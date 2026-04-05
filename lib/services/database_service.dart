import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/achievement_unlock.dart';
import '../models/check_in.dart';
import '../models/goal.dart';
import '../models/milestone_progress.dart';
import '../models/season_progress_record.dart';
import '../models/season_summary_record.dart';

class DatabaseService {
  static const _dbName = 'mintday.db';
  static const _dbVersion = 2;

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    log('[DB] 初始化数据库: $path', name: 'DatabaseService');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    log('[DB] 创建数据表 (version $version)', name: 'DatabaseService');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        reason TEXT,
        vision TEXT,
        deadline TEXT,
        steps TEXT NOT NULL DEFAULT '[]',
        completed_steps TEXT NOT NULL DEFAULT '[]',
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_mintable INTEGER NOT NULL DEFAULT 0,
        season_id TEXT,
        is_public INTEGER NOT NULL DEFAULT 0,
        reward TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE check_ins (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        date TEXT NOT NULL,
        mode TEXT NOT NULL,
        status TEXT NOT NULL,
        mood INTEGER,
        duration INTEGER,
        note TEXT,
        reflection_progress TEXT,
        reflection_blocker TEXT,
        reflection_next TEXT,
        image_paths TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        evidence_type TEXT,
        evidence_urls TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE milestone_progress (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        target_value INTEGER NOT NULL,
        current_value INTEGER NOT NULL DEFAULT 0,
        is_unlocked INTEGER NOT NULL DEFAULT 0,
        unlocked_at TEXT,
        is_minted INTEGER NOT NULL DEFAULT 0,
        mint_tx_hash TEXT,
        card_image_path TEXT,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');

    // 索引优化查询
    await db.execute(
        'CREATE INDEX idx_check_ins_goal_id ON check_ins (goal_id)');
    await db.execute('CREATE INDEX idx_check_ins_date ON check_ins (date)');
    await db.execute(
        'CREATE INDEX idx_milestone_goal_id ON milestone_progress (goal_id)');

    await _createGamificationTables(db);

    log('[DB] 所有数据表创建完成', name: 'DatabaseService');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    log('[DB] 数据库升级: $oldVersion → $newVersion', name: 'DatabaseService');
    if (oldVersion < 2) {
      await _createGamificationTables(db);
      await _ensureGoalsV2Columns(db);
      await _ensureCheckInsEvidenceColumns(db);
    }
  }

  /// v1 → v2：goals 表可能缺少后续版本字段，避免升级后 insert/update 失败。
  static Future<void> _ensureGoalsV2Columns(Database db) async {
    Future<void> tryAlter(String sql) async {
      try {
        await db.execute(sql);
      } catch (e) {
        log('[DB] ALTER goals 跳过（列可能已存在）: $e', name: 'DatabaseService');
      }
    }

    await tryAlter('ALTER TABLE goals ADD COLUMN season_id TEXT');
    await tryAlter(
        'ALTER TABLE goals ADD COLUMN is_public INTEGER NOT NULL DEFAULT 0');
    await tryAlter('ALTER TABLE goals ADD COLUMN reward TEXT');
  }

  static Future<void> _ensureCheckInsEvidenceColumns(Database db) async {
    Future<void> tryAlter(String sql) async {
      try {
        await db.execute(sql);
      } catch (e) {
        log('[DB] ALTER check_ins 跳过（列可能已存在）: $e',
            name: 'DatabaseService');
      }
    }

    await tryAlter('ALTER TABLE check_ins ADD COLUMN evidence_type TEXT');
    await tryAlter(
        'ALTER TABLE check_ins ADD COLUMN evidence_urls TEXT NOT NULL DEFAULT \'[]\'');
  }

  /// v2：成就解锁、赛季进度快照、赛季总结卡。
  static Future<void> _createGamificationTables(Database db) async {
    log('[DB] 创建 gamification 相关表', name: 'DatabaseService');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievement_unlocks (
        achievement_id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_achievement_unlocks_time ON achievement_unlocks (unlocked_at)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS season_progress (
        season_id TEXT PRIMARY KEY,
        season_index INTEGER NOT NULL,
        window_start TEXT NOT NULL,
        window_end TEXT NOT NULL,
        completion_rate REAL NOT NULL,
        best_streak_days INTEGER NOT NULL,
        check_ins_in_season INTEGER NOT NULL,
        achievements_unlocked_in_season INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS season_summaries (
        id TEXT PRIMARY KEY,
        season_id TEXT NOT NULL UNIQUE,
        season_index INTEGER NOT NULL,
        window_start TEXT NOT NULL,
        window_end TEXT NOT NULL,
        goals_in_season_count INTEGER NOT NULL,
        completion_rate REAL NOT NULL,
        best_streak_days INTEGER NOT NULL,
        achievements_unlocked_count INTEGER NOT NULL,
        total_check_ins_in_window INTEGER NOT NULL,
        generated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_season_summaries_index ON season_summaries (season_index)');
  }

  // ─────────────────────────────────────────
  // Goal CRUD
  // ─────────────────────────────────────────

  static Future<String> insertGoal(Goal goal) async {
    final db = await database;
    await db.insert('goals', goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    log('[DB] 插入目标: ${goal.title}', name: 'DatabaseService');
    return goal.id;
  }

  static Future<List<Goal>> getAllGoals() async {
    final db = await database;
    final maps = await db.query('goals', orderBy: 'created_at DESC');
    log('[DB] 读取所有目标: ${maps.length} 条', name: 'DatabaseService');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  static Future<List<Goal>> getActiveGoals() async {
    final db = await database;
    final maps = await db.query(
      'goals',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  static Future<Goal?> getGoalById(String id) async {
    final db = await database;
    final maps =
        await db.query('goals', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Goal.fromMap(maps.first);
  }

  static Future<int> updateGoal(Goal goal) async {
    final db = await database;
    final count = await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    log('[DB] 更新目标: ${goal.title}', name: 'DatabaseService');
    return count;
  }

  static Future<int> deleteGoal(String id) async {
    final db = await database;
    final count =
        await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    log('[DB] 删除目标: $id', name: 'DatabaseService');
    return count;
  }

  // ─────────────────────────────────────────
  // CheckIn CRUD
  // ─────────────────────────────────────────

  static Future<String> insertCheckIn(CheckIn checkIn) async {
    final db = await database;
    await db.insert('check_ins', checkIn.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    log('[DB] 插入打卡: goalId=${checkIn.goalId}, date=${checkIn.dateString}',
        name: 'DatabaseService');
    return checkIn.id;
  }

  static Future<List<CheckIn>> getCheckInsByGoal(String goalId) async {
    final db = await database;
    final maps = await db.query(
      'check_ins',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => CheckIn.fromMap(m)).toList();
  }

  static Future<List<CheckIn>> getAllCheckIns() async {
    final db = await database;
    final maps =
        await db.query('check_ins', orderBy: 'date DESC, created_at DESC');
    return maps.map((m) => CheckIn.fromMap(m)).toList();
  }

  static Future<List<CheckIn>> getCheckInsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final startStr = CheckIn.fromMap({
      'id': '',
      'goal_id': '',
      'date': '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
      'mode': 'quick',
      'status': 'done',
      'image_paths': '[]',
      'evidence_urls': '[]',
      'created_at': DateTime.now().toIso8601String(),
    }).dateString;
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'check_ins',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return maps.map((m) => CheckIn.fromMap(m)).toList();
  }

  /// 检查某目标今日是否已打卡
  static Future<bool> hasCheckedInToday(String goalId) async {
    final db = await database;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'check_ins',
      where: 'goal_id = ? AND date = ?',
      whereArgs: [goalId, today],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// 获取某目标的连续打卡天数
  static Future<int> getStreakDays(String goalId) async {
    final db = await database;
    final maps = await db.query(
      'check_ins',
      columns: ['date'],
      where: 'goal_id = ? AND status != ?',
      whereArgs: [goalId, 'skipped'],
      orderBy: 'date DESC',
    );

    if (maps.isEmpty) return 0;

    final dateSet = <String>{};
    for (final m in maps) {
      dateSet.add(m['date'] as String);
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();
    // 如果今天没打卡，从昨天开始算
    final todayStr =
        '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    final hasToday = dateSet.contains(todayStr);
    if (!hasToday) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      final target = checkDate.subtract(Duration(days: i));
      final targetStr =
          '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
      if (dateSet.contains(targetStr)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  static Future<int> deleteCheckIn(String id) async {
    final db = await database;
    return db.delete('check_ins', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────
  // MilestoneProgress CRUD（第一阶段静默使用）
  // ─────────────────────────────────────────

  static Future<String> insertMilestone(MilestoneProgress milestone) async {
    final db = await database;
    await db.insert('milestone_progress', milestone.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    log('[DB] 插入里程碑: ${milestone.title}', name: 'DatabaseService');
    return milestone.id;
  }

  static Future<List<MilestoneProgress>> getMilestonesByGoal(
      String goalId) async {
    final db = await database;
    final maps = await db.query(
      'milestone_progress',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'target_value ASC',
    );
    return maps.map((m) => MilestoneProgress.fromMap(m)).toList();
  }

  static Future<int> updateMilestone(MilestoneProgress milestone) async {
    final db = await database;
    return db.update(
      'milestone_progress',
      milestone.toMap(),
      where: 'id = ?',
      whereArgs: [milestone.id],
    );
  }

  // ─────────────────────────────────────────
  // 统计查询
  // ─────────────────────────────────────────

  /// 总打卡天数（去重，按 date 计算）
  static Future<int> getTotalCheckInDays() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(DISTINCT date) as cnt FROM check_ins WHERE status != ?',
        ['skipped']);
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 所有目标中最长连续打卡天数
  static Future<int> getMaxStreakDays() async {
    final db = await database;
    final goals =
        await db.query('goals', columns: ['id'], where: 'status = ?', whereArgs: ['active']);
    int maxStreak = 0;
    for (final g in goals) {
      final streak = await getStreakDays(g['id'] as String);
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }

  // ─────────────────────────────────────────
  // 成就解锁（achievement_unlocks）
  // ─────────────────────────────────────────

  static Future<Set<String>> getAllUnlockedAchievementIds() async {
    final db = await database;
    final maps = await db.query('achievement_unlocks');
    return maps.map((m) => m['achievement_id'] as String).toSet();
  }

  static Future<List<AchievementUnlock>> getAllAchievementUnlocks() async {
    final db = await database;
    final maps =
        await db.query('achievement_unlocks', orderBy: 'unlocked_at ASC');
    return maps.map((m) => AchievementUnlock.fromMap(m)).toList();
  }

  /// 首次解锁写入；已存在则返回 false。
  static Future<bool> insertAchievementUnlockIfAbsent(
    String achievementId,
    DateTime unlockedAt,
  ) async {
    final db = await database;
    try {
      final existing = await db.query(
        'achievement_unlocks',
        columns: ['achievement_id'],
        where: 'achievement_id = ?',
        whereArgs: [achievementId],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;

      await db.insert('achievement_unlocks', {
        'achievement_id': achievementId,
        'unlocked_at': unlockedAt.toIso8601String(),
      });
      log('[DB] 解锁成就: $achievementId', name: 'DatabaseService');
      return true;
    } catch (e, s) {
      log('[DB] 写入成就失败: $e',
          name: 'DatabaseService', error: e, stackTrace: s);
      return false;
    }
  }

  /// `unlocked_at` ∈ [startInclusive, endExclusive)（ISO8601 字符串比较）。
  static Future<int> countAchievementUnlocksBetween(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as cnt FROM achievement_unlocks
      WHERE unlocked_at >= ? AND unlocked_at < ?
      ''',
      [
        startInclusive.toIso8601String(),
        endExclusive.toIso8601String(),
      ],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─────────────────────────────────────────
  // 赛季进度快照（season_progress）
  // ─────────────────────────────────────────

  static Future<void> upsertSeasonProgress(SeasonProgressRecord record) async {
    final db = await database;
    await db.insert(
      'season_progress',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log('[DB] 更新赛季进度: ${record.seasonId}', name: 'DatabaseService');
  }

  static Future<SeasonProgressRecord?> getSeasonProgressBySeasonId(
      String seasonId) async {
    final db = await database;
    final maps = await db.query(
      'season_progress',
      where: 'season_id = ?',
      whereArgs: [seasonId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SeasonProgressRecord.fromMap(maps.first);
  }

  // ─────────────────────────────────────────
  // 赛季总结卡（season_summaries）
  // ─────────────────────────────────────────

  static Future<bool> hasSeasonSummaryForSeasonIndex(int seasonIndex) async {
    final db = await database;
    final maps = await db.query(
      'season_summaries',
      columns: ['id'],
      where: 'season_index = ?',
      whereArgs: [seasonIndex],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// 同一 `season_id` 仅保留一条（首次写入成功返回 true）。
  static Future<bool> insertSeasonSummaryIfAbsent(
    SeasonSummaryRecord record,
  ) async {
    final db = await database;
    try {
      final id = await db.insert(
        'season_summaries',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      final ok = id != 0;
      if (ok) {
        log('[DB] 写入赛季总结: ${record.card.seasonId}', name: 'DatabaseService');
      }
      return ok;
    } catch (e, s) {
      log('[DB] 写入赛季总结失败: $e',
          name: 'DatabaseService', error: e, stackTrace: s);
      return false;
    }
  }

  static Future<List<SeasonSummaryRecord>> getSeasonSummaries({
    int limit = 50,
  }) async {
    final db = await database;
    final maps = await db.query(
      'season_summaries',
      orderBy: 'season_index DESC',
      limit: limit,
    );
    return maps.map((m) => SeasonSummaryRecord.fromMap(m)).toList();
  }

  // ─────────────────────────────────────────
  // 年度报告 / 数据导出
  // ─────────────────────────────────────────

  static String _yearDateStart(int year) =>
      '$year-01-01';

  static String _yearDateEnd(int year) =>
      '$year-12-31';

  /// 自然年内有打卡（非跳过）的不同日历日数量。
  static Future<int> countDistinctCheckInDaysInYear(int year) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT date) as cnt FROM check_ins
      WHERE status != ? AND date >= ? AND date <= ?
      ''',
      ['skipped', _yearDateStart(year), _yearDateEnd(year)],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 自然年内非跳过打卡总条数。
  static Future<int> countNonSkipCheckInsInYear(int year) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as cnt FROM check_ins
      WHERE status != ? AND date >= ? AND date <= ?
      ''',
      ['skipped', _yearDateStart(year), _yearDateEnd(year)],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 自然年内心情分 1–5 的出现次数（缺省分不统计）。
  static Future<Map<int, int>> moodHistogramInYear(int year) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT mood, COUNT(*) as cnt FROM check_ins
      WHERE status != ? AND date >= ? AND date <= ?
        AND mood IS NOT NULL AND mood >= 1 AND mood <= 5
      GROUP BY mood
      ''',
      ['skipped', _yearDateStart(year), _yearDateEnd(year)],
    );
    final out = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
    for (final row in maps) {
      final m = (row['mood'] as int?) ?? 0;
      final c = (row['cnt'] as int?) ?? 0;
      if (m >= 1 && m <= 5) out[m] = c;
    }
    return out;
  }

  /// 自然年内解锁的成就数量（按 unlocked_at）。
  static Future<int> countAchievementUnlocksInYear(int year) async {
    final db = await database;
    final start = DateTime(year, 1, 1).toIso8601String();
    final end = DateTime(year + 1, 1, 1).toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as cnt FROM achievement_unlocks
      WHERE unlocked_at >= ? AND unlocked_at < ?
      ''',
      [start, end],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 导出自然年内打卡 CSV（UTF-8），列为 date,goal_id,status,mode,mood。
  static Future<String> buildCheckInsCsvForYear(int year) async {
    final db = await database;
    final maps = await db.query(
      'check_ins',
      columns: ['date', 'goal_id', 'status', 'mode', 'mood'],
      where: 'date >= ? AND date <= ?',
      whereArgs: [_yearDateStart(year), _yearDateEnd(year)],
      orderBy: 'date ASC, created_at ASC',
    );
    final buf = StringBuffer('date,goal_id,status,mode,mood\n');
    for (final m in maps) {
      buf.write(m['date']);
      buf.write(',');
      buf.write(m['goal_id']);
      buf.write(',');
      buf.write(m['status']);
      buf.write(',');
      buf.write(m['mode']);
      buf.write(',');
      buf.writeln(m['mood'] ?? '');
    }
    return buf.toString();
  }

  static String _csvField(String? text) {
    if (text == null || text.isEmpty) return '';
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  /// 全部打卡记录 CSV（UTF-8）。
  /// 列：日期, 目标名称, 打卡模式, 完成状态, 心情(1-5), 投入时长(分钟), 备注
  static Future<String> buildCheckInsCsvAll() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.date AS date,
             g.title AS goal_title,
             c.mode AS mode,
             c.status AS status,
             c.mood AS mood,
             c.duration AS duration,
             c.note AS note
      FROM check_ins c
      LEFT JOIN goals g ON g.id = c.goal_id
      ORDER BY c.date ASC, c.created_at ASC
    ''');

    final buf = StringBuffer(
      '日期,目标名称,打卡模式,完成状态,心情(1-5),投入时长(分钟),备注\n',
    );
    for (final m in rows) {
      final date = m['date'] as String? ?? '';
      final goalTitle = (m['goal_title'] as String?)?.trim() ?? '';
      final mode = CheckInMode.fromValue(m['mode'] as String).label;
      final status = CheckInStatus.fromValue(m['status'] as String).label;
      final mood = m['mood'] == null ? '' : '${m['mood']}';
      final duration = m['duration'] == null ? '' : '${m['duration']}';
      final note = m['note'] as String? ?? '';

      buf.write(_csvField(date));
      buf.write(',');
      buf.write(_csvField(goalTitle));
      buf.write(',');
      buf.write(_csvField(mode));
      buf.write(',');
      buf.write(_csvField(status));
      buf.write(',');
      buf.write(mood);
      buf.write(',');
      buf.write(duration);
      buf.write(',');
      buf.writeln(_csvField(note));
    }
    return buf.toString();
  }
}
