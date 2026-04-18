import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/utils.dart';
import '../models/ai_message.dart';
import '../models/check_in.dart';
import '../models/goal.dart';
import '../services/minimax_ai_service.dart';
import 'check_in_provider.dart';
import 'focus_provider.dart';
import 'goal_provider.dart';

enum AiMoodTrendDirection { rising, falling, stable, unknown }

class AiInsightSnapshot {
  final int longestStreak;
  final int activeGoalCount;
  final int checkedTodayCount;
  final int completedSteps;
  final int totalSteps;
  final int totalCheckIns;
  final int todayFocusMinutes;
  final double averageGoalProgress;
  final double? moodAverage7d;
  final AiMoodTrendDirection moodTrend;
  final List<double?> moodSeries7d;

  const AiInsightSnapshot({
    required this.longestStreak,
    required this.activeGoalCount,
    required this.checkedTodayCount,
    required this.completedSteps,
    required this.totalSteps,
    required this.totalCheckIns,
    required this.todayFocusMinutes,
    required this.averageGoalProgress,
    required this.moodAverage7d,
    required this.moodTrend,
    required this.moodSeries7d,
  });
}

class AiCompanionProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final _random = Random();
  final MinimaxAiService _minimaxService;

  final List<AiMessage> _messages = [];
  final Map<String, AiInsightSnapshot> _insightsByMessageId = {};
  final Map<String, String> _rawAssistantContentById = {};

  CheckInProvider? _checkInProvider;
  GoalProvider? _goalProvider;
  FocusProvider? _focusProvider;

  bool _isTyping = false;
  bool _hasSeededGreeting = false;
  String? _lastRemoteError;

  AiCompanionProvider({MinimaxAiService? minimaxService})
    : _minimaxService = minimaxService ?? MinimaxAiService();

  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isBootstrapping =>
      _messages.isEmpty && (_dependenciesAreLoading || !_hasSeededGreeting);
  bool get isRemoteConfigured => _minimaxService.isConfigured;
  String? get lastRemoteError => _lastRemoteError;

  String get backendLabel {
    if (_minimaxService.isConfigured && _lastRemoteError == null) {
      return _minimaxService.modelName;
    }
    if (_minimaxService.isConfigured && _lastRemoteError != null) {
      return 'MiniMax 回退中';
    }
    return '本地模板';
  }

  Future<void> init() async {
    await _minimaxService.init();
    notifyListeners();
  }

  AiInsightSnapshot? insightForMessage(String messageId) {
    return _insightsByMessageId[messageId];
  }

  void updateDependencies({
    required CheckInProvider checkInProvider,
    required GoalProvider goalProvider,
    required FocusProvider focusProvider,
  }) {
    _checkInProvider = checkInProvider;
    _goalProvider = goalProvider;
    _focusProvider = focusProvider;

    if (_hasSeededGreeting || _dependenciesAreLoading) return;
    Future<void>.microtask(_seedGreetingIfReady);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    final context = _buildContext();
    final userMessage = AiMessage(
      id: _uuid.v4(),
      content: trimmed,
      role: MessageRole.user,
      createdAt: DateTime.now(),
      relatedGoalId: context.primaryGoal?.id,
    );

    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      final replyFuture = _buildReply(trimmed, context);
      final typingDelay = 800 + _random.nextInt(701);
      await Future<void>.delayed(Duration(milliseconds: typingDelay));
      final reply = await replyFuture;

      final assistantMessage = AiMessage(
        id: _uuid.v4(),
        content: reply.content,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        relatedGoalId: reply.relatedGoalId,
      );

      if (reply.rawContent != null) {
        _rawAssistantContentById[assistantMessage.id] = reply.rawContent!;
      }
      if (reply.insight != null) {
        _insightsByMessageId[assistantMessage.id] = reply.insight!;
      }

      _messages.add(assistantMessage);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  bool get _dependenciesAreLoading {
    return (_checkInProvider?.isLoading ?? true) ||
        (_goalProvider?.isLoading ?? true) ||
        (_focusProvider?.isLoading ?? true);
  }

  void _seedGreetingIfReady() {
    if (_hasSeededGreeting || _dependenciesAreLoading) return;

    final context = _buildContext();
    final greeting = AiMessage(
      id: _uuid.v4(),
      content: _buildGreeting(context),
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
      relatedGoalId: context.primaryGoal?.id,
    );

    _messages.add(greeting);
    _insightsByMessageId[greeting.id] = context.insight;
    _hasSeededGreeting = true;
    notifyListeners();
  }

  Future<_AiReply> _buildReply(String text, _AiContext context) async {
    if (_minimaxService.isConfigured) {
      try {
        final remote = await _minimaxService.generateReply(
          userText: text,
          context: _buildPromptContext(context),
          history: _buildRemoteHistory(),
        );
        _lastRemoteError = null;

        return _AiReply(
          content: remote.displayContent,
          rawContent: remote.rawContent,
          relatedGoalId:
              context.primaryPendingGoalId ?? context.primaryGoal?.id,
          insight: _shouldAttachInsight(text) ? context.insight : null,
        );
      } catch (error) {
        _lastRemoteError = error.toString();
      }
    }

    return _buildTemplateReply(text, context);
  }

  List<MinimaxHistoryMessage> _buildRemoteHistory() {
    final latestUserOffset =
        _messages.isNotEmpty && _messages.last.role == MessageRole.user ? 1 : 0;
    final availableCount = _messages.length - latestUserOffset;
    final startIndex = availableCount > 10 ? availableCount - 10 : 0;

    return _messages
        .skip(startIndex)
        .map((message) {
          if (latestUserOffset == 1 && identical(message, _messages.last)) {
            return null;
          }
          final content =
              _rawAssistantContentById[message.id] ?? message.content;
          return MinimaxHistoryMessage(role: message.role, content: content);
        })
        .whereType<MinimaxHistoryMessage>()
        .toList(growable: false);
  }

  MinimaxPromptContext _buildPromptContext(_AiContext context) {
    final moodSeries = context.moodSeries7d
        .map((value) => value == null ? '-' : value.toStringAsFixed(1))
        .join(', ');
    final goalStepHints = context.activeGoals
        .where((goal) => goal.steps.isNotEmpty)
        .take(3)
        .map((goal) {
          final pending = <String>[];
          for (var index = 0; index < goal.steps.length; index++) {
            final done = index < goal.completedSteps.length
                ? goal.completedSteps[index]
                : false;
            if (!done) pending.add(goal.steps[index]);
          }

          final preview = pending.take(2).join('、');
          return pending.isEmpty
              ? '${goal.title}：暂无待办'
              : '${goal.title}：$preview';
        })
        .toList(growable: false);

    return MinimaxPromptContext(
      todayLabel: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      activeGoalCount: context.activeGoalCount,
      activeGoalTitles: context.activeGoals.map((goal) => goal.title).toList(),
      checkedTodayCount: context.checkedTodayCount,
      longestStreak: context.longestStreak,
      totalCheckIns: context.totalCheckIns,
      completedSteps: context.completedSteps,
      totalSteps: context.totalSteps,
      goalProgressPercent: (context.averageGoalProgress * 100).round(),
      moodTrendLabel: context.moodTrendLabel,
      moodAverageLabel: context.moodAverage7d == null
          ? '暂无足够记录'
          : '${context.moodAverage7d!.toStringAsFixed(1)} / 5',
      moodSeriesLabel: moodSeries,
      todayFocusLabel: AppUtils.formatDuration(context.todayFocusMinutes),
      primaryGoalTitle: context.primaryGoal?.title,
      primaryPendingStepLabel: context.primaryPendingStepLabel,
      goalStepHints: goalStepHints,
    );
  }

  bool _shouldAttachInsight(String text) {
    final normalized = text.replaceAll('？', '?').replaceAll('，', ',');
    return _matchesTired(normalized) ||
        _matchesGiveUp(normalized) ||
        _matchesProgress(normalized) ||
        _matchesTodayPlan(normalized) ||
        _matchesAdvice(normalized);
  }

  _AiReply _buildTemplateReply(String text, _AiContext context) {
    final normalized = text.replaceAll('？', '?').replaceAll('，', ',');

    if (_matchesTired(normalized)) {
      return _buildTiredReply(context);
    }
    if (_matchesGiveUp(normalized)) {
      return _buildGiveUpReply(context);
    }
    if (_matchesProgress(normalized)) {
      return _buildProgressReply(context);
    }
    if (_matchesTodayPlan(normalized)) {
      return _buildTodayPlanReply(context);
    }
    if (_matchesAdvice(normalized)) {
      return _buildAdviceReply(context);
    }
    if (_matchesEncouragement(normalized)) {
      return _buildEncouragementReply(context);
    }

    return _buildDefaultReply(context);
  }

  bool _matchesTired(String text) {
    return text.contains('今天很累') ||
        text.contains('好累') ||
        text.contains('有点累') ||
        text.contains('很累');
  }

  bool _matchesGiveUp(String text) {
    return text.contains('不想坚持') ||
        text.contains('坚持不下') ||
        text.contains('想放弃') ||
        text.contains('不想继续');
  }

  bool _matchesProgress(String text) {
    return text.contains('进度') ||
        text.contains('怎么样') ||
        text.contains('总结') ||
        text.contains('数据');
  }

  bool _matchesAdvice(String text) {
    return text.contains('建议') || text.contains('该怎么做') || text.contains('怎么办');
  }

  bool _matchesTodayPlan(String text) {
    return text.contains('今天做什么') ||
        text.contains('今天做啥') ||
        text.contains('今天先做什么');
  }

  bool _matchesEncouragement(String text) {
    return text.contains('鼓励') || text.contains('夸夸我') || text.contains('打打气');
  }

  _AiReply _buildTiredReply(_AiContext context) {
    final streakLine = context.longestStreak > 0
        ? '你已经连续 ${context.longestStreak} 天在坚持了，这份稳定很珍贵。'
        : '你已经留下 ${context.totalCheckIns} 次打卡记录，这说明你一直没有真的离开这段旅程。';
    final moodLine = switch (context.moodTrend) {
      AiMoodTrendDirection.falling => '而且最近 7 天的心情有点往下走，今天更值得被温柔对待。',
      AiMoodTrendDirection.rising => '最近 7 天的心情其实在慢慢回升，说明你已经在把自己往好的方向带了。',
      AiMoodTrendDirection.stable => '最近 7 天的心情整体还算平稳，你已经做得比想象中更稳。',
      AiMoodTrendDirection.unknown => '先别急着要求自己满格运转，累的时候放慢一点也没关系。',
    };
    final nextStep = context.primaryPendingStepLabel == null
        ? '今天只做一个最小动作就好，比如完成一次简短打卡。'
        : '不如把门槛降到最低，先只推进一下“${context.primaryPendingStepLabel}”。';

    return _AiReply(
      content:
          '听起来你今天真的有点透支了。$moodLine $streakLine $nextStep 我会陪你把今天过成“没有放弃自己”的一天。',
      relatedGoalId: context.primaryPendingGoalId ?? context.primaryGoal?.id,
      insight: context.insight,
    );
  }

  _AiReply _buildGiveUpReply(_AiContext context) {
    final journeyLine = context.totalSteps > 0
        ? '到现在你已经完成了 ${context.completedSteps}/${context.totalSteps} 个步骤，整体推进约 ${_percentText(context.averageGoalProgress)}。'
        : '到现在你已经积累了 ${context.totalCheckIns} 次打卡记录，这些都是真实发生过的努力。';
    final streakLine = context.longestStreak > 0
        ? '最长连续记录是 ${context.longestStreak} 天。'
        : '这段路也许还没形成连续记录，但你已经开始了。';
    final anchor = context.primaryPendingStepLabel == null
        ? '先别急着决定放弃，今天只做一个 10 分钟的小动作就好。'
        : '先别急着给这段旅程下结论，我们只把今天缩小成“${context.primaryPendingStepLabel}”这一步。';

    return _AiReply(
      content:
          '我能感觉到你现在有点想松手了。通常不是你不行，而是你真的累了。$journeyLine $streakLine $anchor 只要今天还愿意挪动一点点，这段路就没有结束。',
      relatedGoalId: context.primaryPendingGoalId ?? context.primaryGoal?.id,
      insight: context.insight,
    );
  }

  _AiReply _buildProgressReply(_AiContext context) {
    final moodText = context.moodAverage7d == null
        ? '最近 7 天还没有足够的心情记录'
        : '最近 7 天心情均值 ${context.moodAverage7d!.toStringAsFixed(1)} / 5，${context.moodTrendLabel}';

    return _AiReply(
      content:
          '我帮你看了一下：你现在有 ${context.activeGoalCount} 个活跃目标，步骤完成率约 ${_percentText(context.averageGoalProgress)}，最长连续记录 ${context.longestStreak} 天，今天已推进 ${context.checkedTodayCount} 个目标，$moodText，今天专注了 ${AppUtils.formatDuration(context.todayFocusMinutes)}。',
      relatedGoalId: context.primaryGoal?.id,
      insight: context.insight,
    );
  }

  _AiReply _buildAdviceReply(_AiContext context) {
    final stepSuggestion = context.primaryPendingStepLabel == null
        ? '先安排一次简短打卡，把节奏接起来。'
        : '优先处理还没完成的“${context.primaryPendingStepLabel}”，只要求自己推进一点点。';
    final moodSuggestion = switch (context.moodTrend) {
      AiMoodTrendDirection.falling => '最近心情有点往下走，今天更适合做低门槛、能快速完成的小步骤。',
      AiMoodTrendDirection.rising => '最近心情在回升，可以趁这个势头把最关键的一步先做掉。',
      AiMoodTrendDirection.stable => '最近状态比较稳，适合给自己一个清晰的小目标并按节奏推进。',
      AiMoodTrendDirection.unknown => '等你记录更多心情后，我会给你更细的节奏建议。',
    };
    final focusSuggestion = context.todayFocusMinutes > 0
        ? '你今天已经专注了 ${AppUtils.formatDuration(context.todayFocusMinutes)}，可以顺势再补一个收尾动作。'
        : '如果你愿意，可以先开一个 15 分钟专注时段，把启动成本降下来。';

    return _AiReply(
      content:
          '可以的，我给你一个更贴近今天状态的建议：$stepSuggestion $moodSuggestion $focusSuggestion',
      relatedGoalId: context.primaryPendingGoalId ?? context.primaryGoal?.id,
      insight: context.insight,
    );
  }

  _AiReply _buildTodayPlanReply(_AiContext context) {
    final headline = context.primaryPendingStepLabel == null
        ? '今天先把节奏接回来。'
        : '今天最值得先做的是“${context.primaryPendingStepLabel}”。';
    final checkInLine = context.checkedTodayCount > 0
        ? '你今天已经推进了 ${context.checkedTodayCount} 个目标，再补一个小动作就会很完整。'
        : '如果还没开始，先完成一次打卡会比想很多更有用。';
    final focusLine = context.todayFocusMinutes > 0
        ? '你已经有 ${AppUtils.formatDuration(context.todayFocusMinutes)} 的专注积累，可以直接沿着这个节奏继续。'
        : '建议先给自己一个 15 分钟的小专注窗口，做完就收。';

    return _AiReply(
      content: '$headline $checkInLine $focusLine',
      relatedGoalId: context.primaryPendingGoalId ?? context.primaryGoal?.id,
      insight: context.insight,
    );
  }

  _AiReply _buildEncouragementReply(_AiContext context) {
    final candidates = <String>[
      if (context.longestStreak > 0)
        '你已经连续 ${context.longestStreak} 天在路上了，真的很棒，这不是一时兴起能做到的。',
      if (context.totalSteps > 0)
        '你已经完成了 ${context.completedSteps} 个步骤，成长其实已经在你身上留下痕迹了。',
      if (context.todayFocusMinutes > 0)
        '今天你已经投入了 ${AppUtils.formatDuration(context.todayFocusMinutes)} 的专注，这份投入很扎实。',
      if (context.checkedTodayCount > 0)
        '今天已经有 ${context.checkedTodayCount} 个目标被你点亮了，你没有停在原地。',
      '别小看现在的自己，你已经比刚开始时更稳、更会照顾目标了。',
    ];

    return _AiReply(
      content: _pick(candidates),
      relatedGoalId: context.primaryGoal?.id,
      insight: context.insight,
    );
  }

  _AiReply _buildDefaultReply(_AiContext context) {
    final defaultPool = <String>[
      if (context.activeGoalCount > 0)
        '你手上还有 ${context.activeGoalCount} 个目标在生长，不需要一下做很多，先推进一个最小动作就好。',
      if (context.longestStreak > 0)
        '最长连续 ${context.longestStreak} 天的你，已经证明自己能把想法走成节奏。',
      if (context.primaryPendingStepLabel != null)
        '如果你想，我建议从“${context.primaryPendingStepLabel}”开始，这会是今天很好的起点。',
      AppUtils.randomEncouragement(),
    ];

    return _AiReply(
      content: _pick(defaultPool),
      relatedGoalId: context.primaryPendingGoalId ?? context.primaryGoal?.id,
      insight: context.primaryPendingStepLabel == null ? null : context.insight,
    );
  }

  String _buildGreeting(_AiContext context) {
    final salutation = _salutationForHour(DateTime.now().hour);

    if (context.activeGoalCount == 0) {
      return '$salutation，我已经准备好陪你开始新的旅程了。创建一个目标后，我就能结合你的打卡、进度和心情，给你更懂你的提醒。';
    }

    final streakLine = context.longestStreak > 0
        ? '你最近的最长连续记录已经来到 ${context.longestStreak} 天。'
        : '今天也很适合把节奏重新接起来。';
    final focusLine = context.todayFocusMinutes > 0
        ? '你今天已经专注了 ${AppUtils.formatDuration(context.todayFocusMinutes)}。'
        : '如果还没开始，先做一个最小动作就很好。';

    return '$salutation！我是你的 AI 成长伙伴。你现在有 ${context.activeGoalCount} 个活跃目标，$streakLine $focusLine 想聊聊进度、情绪或者下一步时，随时叫我。';
  }

  String _salutationForHour(int hour) {
    if (hour < 11) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 19) return '下午好';
    return '晚上好';
  }

  String _percentText(double progress) {
    return '${(progress * 100).round()}%';
  }

  String _pick(List<String> items) {
    return items[_random.nextInt(items.length)];
  }

  _AiContext _buildContext() {
    final goalProvider = _goalProvider;
    final checkInProvider = _checkInProvider;
    final focusProvider = _focusProvider;

    final allGoals = goalProvider?.goals ?? const <Goal>[];
    final activeGoals = goalProvider?.activeGoals ?? const <Goal>[];
    final checkIns = checkInProvider?.checkIns ?? const <CheckIn>[];

    var longestStreak = 0;
    for (final goal in allGoals) {
      final streak = checkInProvider?.getStreak(goal.id) ?? 0;
      if (streak > longestStreak) {
        longestStreak = streak;
      }
    }

    var checkedTodayCount = 0;
    var completedSteps = 0;
    var totalSteps = 0;
    final pendingSteps = <_PendingStep>[];

    for (final goal in activeGoals) {
      if (checkInProvider?.isTodayChecked(goal.id) ?? false) {
        checkedTodayCount++;
      }

      completedSteps += goal.completedStepCount;
      totalSteps += goal.steps.length;

      for (var index = 0; index < goal.steps.length; index++) {
        final done = index < goal.completedSteps.length
            ? goal.completedSteps[index]
            : false;
        if (!done) {
          pendingSteps.add(
            _PendingStep(
              goalId: goal.id,
              goalTitle: goal.title,
              stepLabel: goal.steps[index],
            ),
          );
        }
      }
    }

    final averageGoalProgress = activeGoals.isEmpty
        ? 0.0
        : activeGoals.fold<double>(0, (sum, goal) => sum + goal.progress) /
              activeGoals.length;

    final moodSeries7d = _buildMoodSeries(checkIns, days: 7);
    final moodValues = moodSeries7d.whereType<double>().toList(growable: false);
    final moodAverage7d = moodValues.isEmpty
        ? null
        : moodValues.reduce((a, b) => a + b) / moodValues.length;
    final moodTrend = _resolveMoodTrend(moodSeries7d);

    return _AiContext(
      activeGoals: activeGoals,
      primaryGoal: activeGoals.isEmpty ? null : activeGoals.first,
      primaryPendingGoalId: pendingSteps.isEmpty
          ? null
          : pendingSteps.first.goalId,
      primaryPendingStepLabel: pendingSteps.isEmpty
          ? null
          : pendingSteps.first.stepLabel,
      activeGoalCount: activeGoals.length,
      checkedTodayCount: checkedTodayCount,
      longestStreak: longestStreak,
      completedSteps: completedSteps,
      totalSteps: totalSteps,
      totalCheckIns: checkIns.length,
      todayFocusMinutes: focusProvider?.getTodayFocusMinutes() ?? 0,
      averageGoalProgress: averageGoalProgress,
      moodAverage7d: moodAverage7d,
      moodTrend: moodTrend,
      moodSeries7d: moodSeries7d,
    );
  }

  List<double?> _buildMoodSeries(List<CheckIn> checkIns, {required int days}) {
    final today = _dayOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    final sums = <DateTime, double>{};
    final counts = <DateTime, int>{};

    for (final checkIn in checkIns) {
      if (checkIn.mood == null || checkIn.status == CheckInStatus.skipped) {
        continue;
      }

      final day = _dayOnly(checkIn.date);
      if (day.isBefore(start) || day.isAfter(today)) continue;

      sums[day] = (sums[day] ?? 0) + checkIn.mood!;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return List<double?>.generate(days, (index) {
      final day = start.add(Duration(days: index));
      final count = counts[day];
      if (count == null || count == 0) return null;
      return sums[day]! / count;
    });
  }

  AiMoodTrendDirection _resolveMoodTrend(List<double?> moodSeries) {
    final values = moodSeries.whereType<double>().toList(growable: false);
    if (values.length < 2) return AiMoodTrendDirection.unknown;

    final half = values.length ~/ 2;
    final firstHalf = values.take(max(1, half)).toList(growable: false);
    final secondHalf = values.skip(half).toList(growable: false);
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    final delta = secondAvg - firstAvg;

    if (delta >= 0.35) return AiMoodTrendDirection.rising;
    if (delta <= -0.35) return AiMoodTrendDirection.falling;
    return AiMoodTrendDirection.stable;
  }

  DateTime _dayOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _AiReply {
  final String content;
  final String? rawContent;
  final String? relatedGoalId;
  final AiInsightSnapshot? insight;

  const _AiReply({
    required this.content,
    this.rawContent,
    this.relatedGoalId,
    this.insight,
  });
}

class _AiContext {
  final List<Goal> activeGoals;
  final Goal? primaryGoal;
  final String? primaryPendingGoalId;
  final String? primaryPendingStepLabel;
  final int activeGoalCount;
  final int checkedTodayCount;
  final int longestStreak;
  final int completedSteps;
  final int totalSteps;
  final int totalCheckIns;
  final int todayFocusMinutes;
  final double averageGoalProgress;
  final double? moodAverage7d;
  final AiMoodTrendDirection moodTrend;
  final List<double?> moodSeries7d;

  const _AiContext({
    required this.activeGoals,
    required this.primaryGoal,
    required this.primaryPendingGoalId,
    required this.primaryPendingStepLabel,
    required this.activeGoalCount,
    required this.checkedTodayCount,
    required this.longestStreak,
    required this.completedSteps,
    required this.totalSteps,
    required this.totalCheckIns,
    required this.todayFocusMinutes,
    required this.averageGoalProgress,
    required this.moodAverage7d,
    required this.moodTrend,
    required this.moodSeries7d,
  });

  String get moodTrendLabel {
    return switch (moodTrend) {
      AiMoodTrendDirection.rising => '状态在回升',
      AiMoodTrendDirection.falling => '状态有点下滑',
      AiMoodTrendDirection.stable => '状态比较平稳',
      AiMoodTrendDirection.unknown => '还在积累更多数据',
    };
  }

  AiInsightSnapshot get insight {
    return AiInsightSnapshot(
      longestStreak: longestStreak,
      activeGoalCount: activeGoalCount,
      checkedTodayCount: checkedTodayCount,
      completedSteps: completedSteps,
      totalSteps: totalSteps,
      totalCheckIns: totalCheckIns,
      todayFocusMinutes: todayFocusMinutes,
      averageGoalProgress: averageGoalProgress,
      moodAverage7d: moodAverage7d,
      moodTrend: moodTrend,
      moodSeries7d: moodSeries7d,
    );
  }
}

class _PendingStep {
  final String goalId;
  final String goalTitle;
  final String stepLabel;

  const _PendingStep({
    required this.goalId,
    required this.goalTitle,
    required this.stepLabel,
  });
}
