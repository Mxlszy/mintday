import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/check_in.dart';
import '../models/focus_session.dart';
import '../services/database_service.dart';
import 'check_in_provider.dart';

class FocusProvider extends ChangeNotifier {
  FocusProvider({required CheckInProvider checkInProvider})
    : _checkInProvider = checkInProvider;

  static const int defaultTargetMinutes = 25;
  static const int defaultTargetDurationSeconds = defaultTargetMinutes * 60;

  final CheckInProvider _checkInProvider;
  final _uuid = const Uuid();

  final List<FocusSession> _sessions = [];

  FocusSession? _currentSession;
  Timer? _ticker;
  DateTime? _lastResumedAt;
  int _committedElapsedSeconds = 0;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isLoading = false;

  List<FocusSession> get sessions => List.unmodifiable(_sessions);
  FocusSession? get currentSession => _currentSession;
  String? get currentGoalId => _currentSession?.goalId;
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _currentSession != null;
  bool get isRunning => _currentSession != null && !_isPaused;
  bool get isPaused => _currentSession != null && _isPaused;
  int get elapsedSeconds => _elapsedSeconds;
  double get progressToTarget =>
      (_elapsedSeconds / defaultTargetDurationSeconds)
          .clamp(0.0, 1.0)
          .toDouble();

  Future<void> init() async {
    await loadSessions();
  }

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final sessions = await DatabaseService.getAllFocusSessions();
      _sessions
        ..clear()
        ..addAll(sessions);
      log(
        '[FocusProvider] Loaded focus sessions: ${_sessions.length}',
        name: 'FocusProvider',
      );
    } catch (e, s) {
      log(
        '[FocusProvider] Failed to load focus sessions: $e',
        name: 'FocusProvider',
        error: e,
        stackTrace: s,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool start(String goalId) {
    if (goalId.isEmpty || _currentSession != null) return false;

    final now = DateTime.now();
    _currentSession = FocusSession(
      id: _uuid.v4(),
      goalId: goalId,
      startTime: now,
      endTime: null,
      durationSeconds: 0,
      isCompleted: false,
      note: null,
      createdAt: now,
    );
    _committedElapsedSeconds = 0;
    _elapsedSeconds = 0;
    _isPaused = false;
    _lastResumedAt = now;
    _startTicker();
    notifyListeners();
    return true;
  }

  void pause() {
    if (!isRunning || _currentSession == null || _lastResumedAt == null) return;
    _commitRunningElapsed();
    _isPaused = true;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void resume() {
    if (!isPaused || _currentSession == null) return;
    _isPaused = false;
    _lastResumedAt = DateTime.now();
    _refreshElapsed();
    _startTicker();
    notifyListeners();
  }

  Future<FocusSession?> complete([String? note]) async {
    final session = _currentSession;
    if (session == null) return null;

    final endTime = DateTime.now();
    final durationSeconds = _finalizeElapsed();
    final trimmedNote = _normalizeNote(note);

    final completedSession = session.copyWith(
      endTime: endTime,
      durationSeconds: durationSeconds,
      isCompleted: true,
      note: trimmedNote,
    );

    try {
      await DatabaseService.insertFocusSession(completedSession);
      _sessions.insert(0, completedSession);
      _resetCurrentSession();

      final durationMinutes = completedSession.durationSeconds ~/ 60;
      await _checkInProvider.submitCheckIn(
        goalId: completedSession.goalId,
        mode: CheckInMode.quick,
        status: CheckInStatus.done,
        duration: durationMinutes,
        note: trimmedNote,
      );

      notifyListeners();
      return completedSession;
    } catch (e, s) {
      log(
        '[FocusProvider] Failed to complete focus session: $e',
        name: 'FocusProvider',
        error: e,
        stackTrace: s,
      );
      _restoreRuntimeSession(
        session: session,
        elapsedSeconds: durationSeconds,
        paused: true,
      );
      notifyListeners();
      return null;
    }
  }

  Future<FocusSession?> cancel() async {
    final session = _currentSession;
    if (session == null) return null;

    final endTime = DateTime.now();
    final durationSeconds = _finalizeElapsed();

    final cancelledSession = session.copyWith(
      endTime: endTime,
      durationSeconds: durationSeconds,
      isCompleted: false,
    );

    try {
      if (durationSeconds > 0) {
        await DatabaseService.insertFocusSession(cancelledSession);
        _sessions.insert(0, cancelledSession);
      }
      _resetCurrentSession();
      notifyListeners();
      return cancelledSession;
    } catch (e, s) {
      log(
        '[FocusProvider] Failed to cancel focus session: $e',
        name: 'FocusProvider',
        error: e,
        stackTrace: s,
      );
      _restoreRuntimeSession(
        session: session,
        elapsedSeconds: durationSeconds,
        paused: true,
      );
      notifyListeners();
      return null;
    }
  }

  int getTotalFocusMinutesForGoal(String goalId) {
    final completedSeconds = _sessions
        .where((session) => session.goalId == goalId && session.isCompleted)
        .fold<int>(0, (sum, session) => sum + session.durationSeconds);
    return completedSeconds ~/ 60;
  }

  int getTodayFocusMinutes() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _focusMinutesInRange(startOfDay, endOfDay);
  }

  int getWeekFocusMinutes() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _focusMinutesInRange(startOfWeek, endOfWeek);
  }

  int _focusMinutesInRange(DateTime startInclusive, DateTime endExclusive) {
    var totalSeconds = _sessions
        .where(
          (session) =>
              session.isCompleted &&
              !session.startTime.isBefore(startInclusive) &&
              session.startTime.isBefore(endExclusive),
        )
        .fold<int>(0, (sum, session) => sum + session.durationSeconds);

    final currentSession = _currentSession;
    if (currentSession != null &&
        !currentSession.startTime.isBefore(startInclusive) &&
        currentSession.startTime.isBefore(endExclusive)) {
      totalSeconds += _elapsedSeconds;
    }

    return totalSeconds ~/ 60;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshElapsed();
      notifyListeners();
    });
  }

  void _refreshElapsed() {
    final resumedAt = _lastResumedAt;
    if (_currentSession == null) {
      _elapsedSeconds = 0;
      return;
    }

    if (resumedAt == null) {
      _elapsedSeconds = _committedElapsedSeconds;
      return;
    }

    _elapsedSeconds =
        _committedElapsedSeconds +
        DateTime.now().difference(resumedAt).inSeconds;
  }

  void _commitRunningElapsed() {
    final resumedAt = _lastResumedAt;
    if (resumedAt == null) return;

    _committedElapsedSeconds += DateTime.now().difference(resumedAt).inSeconds;
    _lastResumedAt = null;
    _elapsedSeconds = _committedElapsedSeconds;
  }

  int _finalizeElapsed() {
    _commitRunningElapsed();
    return _committedElapsedSeconds;
  }

  void _resetCurrentSession() {
    _ticker?.cancel();
    _ticker = null;
    _currentSession = null;
    _lastResumedAt = null;
    _committedElapsedSeconds = 0;
    _elapsedSeconds = 0;
    _isPaused = false;
  }

  void _restoreRuntimeSession({
    required FocusSession session,
    required int elapsedSeconds,
    required bool paused,
  }) {
    _currentSession = session;
    _committedElapsedSeconds = elapsedSeconds;
    _elapsedSeconds = elapsedSeconds;
    _isPaused = paused;
    _lastResumedAt = paused ? null : DateTime.now();
    if (!paused) {
      _startTicker();
    }
  }

  String? _normalizeNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
