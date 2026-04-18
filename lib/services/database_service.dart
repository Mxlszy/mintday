import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/achievement_unlock.dart';
import '../models/check_in.dart';
import '../models/comment.dart';
import '../models/focus_session.dart';
import '../models/friendship.dart';
import '../models/goal.dart';
import '../models/milestone_progress.dart';
import '../models/nft_asset.dart';
import '../models/season_progress_record.dart';
import '../models/season_summary_record.dart';
import '../models/social_post.dart';
import '../models/todo_item.dart';
import '../models/transaction.dart' as wallet;

class DatabaseService {
  static const _dbName = 'mintday.db';
  static const _dbVersion = 10;

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
    await _createTodoTables(db);
    await _createNftAssetTables(db);
    await _createTransactionTables(db);
    await _seedDefaultTransactionCategories(db);
    await _createFocusSessionTables(db);
    await _createFriendTables(db);
    await _createSocialTables(db);

    await db.execute(
      'CREATE INDEX idx_check_ins_goal_id ON check_ins (goal_id)',
    );
    await db.execute('CREATE INDEX idx_check_ins_date ON check_ins (date)');
    await db.execute(
      'CREATE INDEX idx_milestone_goal_id ON milestone_progress (goal_id)',
    );

    await _createGamificationTables(db);

    log('[DB] 所有数据表创建完成', name: 'DatabaseService');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    log('[DB] 数据库升级: $oldVersion → $newVersion', name: 'DatabaseService');
    if (oldVersion < 2) {
      await _createGamificationTables(db);
      await _ensureGoalsV2Columns(db);
      await _ensureCheckInsEvidenceColumns(db);
    }
    if (oldVersion < 3) {
      await _createFocusSessionTables(db);
    }
    if (oldVersion < 4) {
      await _ensureMilestoneTable(db);
      await _createNftAssetTables(db);
    }
    if (oldVersion < 5) {
      await _createTransactionTables(db);
      await _seedDefaultTransactionCategories(db);
    }
    if (oldVersion < 6) {
      await _createTodoTables(db);
    }
    if (oldVersion < 7) {
      await _ensureNftAssetV7Columns(db);
    }
    if (oldVersion < 8) {
      await _createFriendTables(db);
    }
    if (oldVersion < 9) {
      await _createSocialTables(db);
    }
    if (oldVersion < 10) {
      await _ensureSocialV10Columns(db);
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
      'ALTER TABLE goals ADD COLUMN is_mintable INTEGER NOT NULL DEFAULT 0',
    );
    await tryAlter(
      'ALTER TABLE goals ADD COLUMN is_public INTEGER NOT NULL DEFAULT 0',
    );
    await tryAlter('ALTER TABLE goals ADD COLUMN reward TEXT');
  }

  static Future<void> _ensureCheckInsEvidenceColumns(Database db) async {
    Future<void> tryAlter(String sql) async {
      try {
        await db.execute(sql);
      } catch (e) {
        log('[DB] ALTER check_ins 跳过（列可能已存在）: $e', name: 'DatabaseService');
      }
    }

    await tryAlter('ALTER TABLE check_ins ADD COLUMN evidence_type TEXT');
    await tryAlter(
      'ALTER TABLE check_ins ADD COLUMN evidence_urls TEXT NOT NULL DEFAULT \'[]\'',
    );
  }

  static Future<void> _ensureNftAssetV7Columns(Database db) async {
    Future<void> tryAlter(String sql) async {
      try {
        await db.execute(sql);
      } catch (e) {
        log('[DB] ALTER nft_assets skipped: $e', name: 'DatabaseService');
      }
    }

    await _createNftAssetTables(db);
    await tryAlter('ALTER TABLE nft_assets ADD COLUMN check_in_id TEXT');
    await tryAlter('ALTER TABLE nft_assets ADD COLUMN template_id TEXT');
    await tryAlter('ALTER TABLE nft_assets ADD COLUMN metadata TEXT');
    await tryAlter('ALTER TABLE nft_assets ADD COLUMN rarity TEXT');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nft_assets_check_in ON nft_assets (check_in_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nft_assets_rarity ON nft_assets (rarity)',
    );
  }

  static Future<void> _ensureSocialV10Columns(Database db) async {
    Future<void> tryAlter(String sql) async {
      try {
        await db.execute(sql);
      } catch (e) {
        log('[DB] ALTER social_posts skipped: $e', name: 'DatabaseService');
      }
    }

    await _createSocialTables(db);
    await tryAlter(
      'ALTER TABLE social_posts ADD COLUMN visibility TEXT NOT NULL DEFAULT \'public\'',
    );
    await tryAlter('ALTER TABLE social_posts ADD COLUMN title TEXT');
    await tryAlter('ALTER TABLE social_posts ADD COLUMN subtitle TEXT');
    await tryAlter('ALTER TABLE social_posts ADD COLUMN goal_id TEXT');
    await tryAlter('ALTER TABLE social_posts ADD COLUMN mood INTEGER');
    await tryAlter(
      'ALTER TABLE social_posts ADD COLUMN image_paths TEXT NOT NULL DEFAULT \'[]\'',
    );
    await tryAlter('ALTER TABLE social_posts ADD COLUMN metadata TEXT');
    await tryAlter(
      'ALTER TABLE social_posts ADD COLUMN share_count INTEGER NOT NULL DEFAULT 0',
    );
    await tryAlter(
      'ALTER TABLE social_posts ADD COLUMN is_official INTEGER NOT NULL DEFAULT 0',
    );
    await tryAlter('ALTER TABLE social_posts ADD COLUMN source_goal_id TEXT');
    await tryAlter('ALTER TABLE social_posts ADD COLUMN source_nft_id TEXT');
    await tryAlter(
      'ALTER TABLE social_posts ADD COLUMN source_milestone_id TEXT',
    );
    await tryAlter(
      'ALTER TABLE social_posts ADD COLUMN source_achievement_id TEXT',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_user_created ON social_posts (user_id, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_visibility_created ON social_posts (visibility, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_goal_id ON social_posts (goal_id)',
    );
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
      'CREATE INDEX IF NOT EXISTS idx_achievement_unlocks_time ON achievement_unlocks (unlocked_at)',
    );

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
      'CREATE INDEX IF NOT EXISTS idx_season_summaries_index ON season_summaries (season_index)',
    );
  }

  static Future<void> _createFocusSessionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_sessions (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_focus_sessions_goal_id ON focus_sessions (goal_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_focus_sessions_start ON focus_sessions (start_time)',
    );
  }

  // ─────────────────────────────────────────
  // Goal CRUD
  // ─────────────────────────────────────────

  static Future<String> insertGoal(Goal goal) async {
    final db = await database;
    await db.insert(
      'goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    final maps = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
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

  static Future<String> insertTodoItem(TodoItem todoItem) async {
    final db = await database;
    await db.insert(
      'todo_items',
      todoItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return todoItem.id;
  }

  static Future<List<TodoItem>> getTodoItemsByGoalAndDate(
    String goalId,
    String date,
  ) async {
    final db = await database;
    final maps = await db.query(
      'todo_items',
      where: 'goal_id = ? AND date = ?',
      whereArgs: [goalId, date],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  static Future<List<TodoItem>> getTodoItemsByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'todo_items',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'goal_id ASC, sort_order ASC, created_at ASC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  static Future<int> updateTodoItem(TodoItem todoItem) async {
    final db = await database;
    return db.update(
      'todo_items',
      todoItem.toMap(),
      where: 'id = ?',
      whereArgs: [todoItem.id],
    );
  }

  static Future<int> deleteTodoItem(String id) async {
    final db = await database;
    return db.delete('todo_items', where: 'id = ?', whereArgs: [id]);
  }

  static Future<TodoItem?> toggleTodoItem(String id) async {
    final db = await database;
    final completedAt = DateTime.now().toIso8601String();
    await db.rawUpdate(
      '''
      UPDATE todo_items
      SET
        is_completed = CASE WHEN is_completed = 1 THEN 0 ELSE 1 END,
        completed_at = CASE WHEN is_completed = 1 THEN NULL ELSE ? END
      WHERE id = ?
      ''',
      [completedAt, id],
    );

    final maps = await db.query(
      'todo_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TodoItem.fromMap(maps.first);
  }

  static Future<int> getIncompleteTodoCount(String goalId, String date) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt
      FROM todo_items
      WHERE goal_id = ? AND date = ? AND is_completed = 0
      ''',
      [goalId, date],
    );
    return (result.first['cnt'] as int? ?? 0);
  }

  static Future<int> deleteGoal(String id) async {
    final db = await database;
    final count = await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    log('[DB] 删除目标: $id', name: 'DatabaseService');
    return count;
  }

  // ─────────────────────────────────────────
  // CheckIn CRUD
  // ─────────────────────────────────────────

  static Future<String> insertCheckIn(CheckIn checkIn) async {
    final db = await database;
    await db.insert(
      'check_ins',
      checkIn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log(
      '[DB] 插入打卡: goalId=${checkIn.goalId}, date=${checkIn.dateString}',
      name: 'DatabaseService',
    );
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
    final maps = await db.query(
      'check_ins',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => CheckIn.fromMap(m)).toList();
  }

  static Future<List<CheckIn>> getCheckInsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = CheckIn.fromMap({
      'id': '',
      'goal_id': '',
      'date':
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
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

  static Future<String> insertFocusSession(FocusSession session) async {
    final db = await database;
    await db.insert(
      'focus_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return session.id;
  }

  static Future<List<FocusSession>> getAllFocusSessions() async {
    final db = await database;
    final maps = await db.query(
      'focus_sessions',
      orderBy: 'start_time DESC, created_at DESC',
    );
    return maps.map((m) => FocusSession.fromMap(m)).toList();
  }

  static Future<String> upsertFriendship(Friendship friendship) async {
    final db = await database;
    await db.insert(
      'friendships',
      friendship.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return friendship.id;
  }

  static Future<Friendship?> getFriendshipById(String id) async {
    final db = await database;
    final maps = await db.query(
      'friendships',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Friendship.fromMap(maps.first);
  }

  static Future<List<Friendship>> getFriendshipsForUser(
    String userId, {
    FriendshipStatus? status,
  }) async {
    final db = await database;
    final maps = await db.query(
      'friendships',
      where: status == null
          ? '(user_id = ? OR friend_id = ?)'
          : '(user_id = ? OR friend_id = ?) AND status = ?',
      whereArgs: status == null
          ? [userId, userId]
          : [userId, userId, status.value],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Friendship.fromMap(map)).toList();
  }

  static Future<Friendship?> getFriendshipBetween(
    String userAId,
    String userBId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'friendships',
      where:
          '(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
      whereArgs: [userAId, userBId, userBId, userAId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Friendship.fromMap(maps.first);
  }

  static Future<int> deleteFriendship(String id) async {
    final db = await database;
    return db.delete('friendships', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteFriendshipsBetween(
    String userAId,
    String userBId,
  ) async {
    final db = await database;
    return db.delete(
      'friendships',
      where:
          '(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
      whereArgs: [userAId, userBId, userBId, userAId],
    );
  }

  static Future<void> upsertFriendProfile(FriendProfile profile) async {
    final db = await database;
    await db.insert(
      'friend_profiles',
      profile.toCacheMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> upsertFriendProfiles(
    Iterable<FriendProfile> profiles,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final profile in profiles) {
      batch.insert(
        'friend_profiles',
        profile.toCacheMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<FriendProfile?> getFriendProfileById(String id) async {
    final db = await database;
    final maps = await db.query(
      'friend_profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FriendProfile.fromCacheMap(maps.first);
  }

  static Future<List<FriendProfile>> getAllFriendProfiles() async {
    final db = await database;
    final maps = await db.query(
      'friend_profiles',
      orderBy: 'nickname COLLATE NOCASE ASC',
    );
    return maps.map((map) => FriendProfile.fromCacheMap(map)).toList();
  }

  static Future<List<FriendProfile>> searchFriendProfiles(
    String query, {
    int limit = 20,
  }) async {
    final db = await database;
    final normalized = query.trim().toLowerCase();

    final maps = normalized.isEmpty
        ? await db.query(
            'friend_profiles',
            orderBy: 'last_synced DESC',
            limit: limit,
          )
        : await db.query(
            'friend_profiles',
            where: 'LOWER(nickname) LIKE ? OR LOWER(id) LIKE ?',
            whereArgs: ['%$normalized%', '%$normalized%'],
            orderBy: 'nickname COLLATE NOCASE ASC',
            limit: limit,
          );

    return maps.map((map) => FriendProfile.fromCacheMap(map)).toList();
  }

  // ─────────────────────────────────────────
  // MilestoneProgress CRUD（第一阶段静默使用）
  // ─────────────────────────────────────────

  static Future<String> upsertSocialPost(SocialPost post) async {
    final db = await database;
    await db.insert(
      'social_posts',
      post.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return post.id;
  }

  static Future<String> ensureSocialPost(SocialPost post) async {
    final db = await database;
    await db.insert(
      'social_posts',
      post.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return post.id;
  }

  static Future<void> insertSocialPostsIfAbsent(
    Iterable<SocialPost> posts,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final post in posts) {
      batch.insert(
        'social_posts',
        post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<SocialPost?> getSocialPostById(
    String id, {
    String? currentUserId,
  }) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT p.*,
             CASE WHEN pl.post_id IS NULL THEN 0 ELSE 1 END AS is_liked_by_me
      FROM social_posts p
      LEFT JOIN post_likes pl
        ON pl.post_id = p.id AND pl.user_id = ?
      WHERE p.id = ?
      LIMIT 1
      ''',
      [currentUserId ?? '', id],
    );
    if (maps.isEmpty) return null;
    return SocialPost.fromMap(maps.first);
  }

  static Future<List<SocialPost>> getSocialPosts({
    String? currentUserId,
    bool includeFriendActivity = true,
    PostVisibility? visibility,
    Iterable<String>? userIds,
    bool? isOfficial,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final buffer = StringBuffer('''
      SELECT p.*,
             CASE WHEN pl.post_id IS NULL THEN 0 ELSE 1 END AS is_liked_by_me
      FROM social_posts p
      LEFT JOIN post_likes pl
        ON pl.post_id = p.id AND pl.user_id = ?
    ''');
    final args = <Object?>[currentUserId ?? ''];
    final whereClauses = <String>[];

    if (!includeFriendActivity) {
      whereClauses.add('p.is_friend_activity = 0');
    }
    if (visibility != null) {
      whereClauses.add('p.visibility = ?');
      args.add(visibility.name);
    }
    if (isOfficial != null) {
      whereClauses.add('p.is_official = ?');
      args.add(isOfficial ? 1 : 0);
    }
    if (userIds != null) {
      final ids = userIds.where((item) => item.trim().isNotEmpty).toList();
      if (ids.isNotEmpty) {
        final placeholders = List.filled(ids.length, '?').join(', ');
        whereClauses.add('p.user_id IN ($placeholders)');
        args.addAll(ids);
      }
    }

    if (whereClauses.isNotEmpty) {
      buffer.writeln('WHERE ${whereClauses.join(' AND ')}');
    }

    buffer.writeln('ORDER BY p.created_at DESC');
    if (limit != null) {
      buffer.writeln('LIMIT ?');
      args.add(limit);
    }
    if (offset != null) {
      buffer.writeln('OFFSET ?');
      args.add(offset);
    }

    final maps = await db.rawQuery(buffer.toString(), args);
    return maps.map(SocialPost.fromMap).toList();
  }

  static Future<int> incrementPostShareCount(String postId) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE social_posts
      SET share_count = share_count + 1
      WHERE id = ?
      ''',
      [postId],
    );

    final maps = await db.query(
      'social_posts',
      columns: ['share_count'],
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );
    if (maps.isEmpty) return 0;
    return maps.first['share_count'] as int? ?? 0;
  }

  static Future<int> deleteLegacyMockSocialPosts() async {
    final db = await database;
    return db.delete(
      'social_posts',
      where: 'user_id LIKE ? AND (is_official IS NULL OR is_official = 0)',
      whereArgs: ['mock-%'],
    );
  }

  static Future<Map<String, dynamic>> getLikeSummaryForUserPosts(
    String userId, {
    DateTime? since,
  }) async {
    final db = await database;
    final where = <String>['p.user_id = ?', 'pl.user_id != ?'];
    final args = <Object?>[userId, userId];
    if (since != null) {
      where.add('pl.created_at > ?');
      args.add(since.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS cnt, MAX(pl.created_at) AS latest_at
      FROM post_likes pl
      INNER JOIN social_posts p ON p.id = pl.post_id
      WHERE ${where.join(' AND ')}
      ''', args);
    final row = result.first;
    return {
      'count': row['cnt'] as int? ?? 0,
      'latest_at': row['latest_at'] as String?,
    };
  }

  static Future<Map<String, dynamic>> getCommentSummaryForUserPosts(
    String userId, {
    DateTime? since,
  }) async {
    final db = await database;
    final where = <String>['p.user_id = ?', 'c.author_id != ?'];
    final args = <Object?>[userId, userId];
    if (since != null) {
      where.add('c.created_at > ?');
      args.add(since.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS cnt, MAX(c.created_at) AS latest_at
      FROM comments c
      INNER JOIN social_posts p ON p.id = c.post_id
      WHERE ${where.join(' AND ')}
      ''', args);
    final row = result.first;
    return {
      'count': row['cnt'] as int? ?? 0,
      'latest_at': row['latest_at'] as String?,
    };
  }

  static Future<bool> togglePostLike(String postId, String userId) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'post_likes',
        columns: ['post_id'],
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, userId],
        limit: 1,
      );

      final nextLiked = existing.isEmpty;
      if (nextLiked) {
        await txn.insert('post_likes', {
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        await txn.rawUpdate(
          '''
          UPDATE social_posts
          SET like_count = like_count + 1
          WHERE id = ?
          ''',
          [postId],
        );
      } else {
        await txn.delete(
          'post_likes',
          where: 'post_id = ? AND user_id = ?',
          whereArgs: [postId, userId],
        );
        await txn.rawUpdate(
          '''
          UPDATE social_posts
          SET like_count = CASE
            WHEN like_count > 0 THEN like_count - 1
            ELSE 0
          END
          WHERE id = ?
          ''',
          [postId],
        );
      }

      return nextLiked;
    });
  }

  static Future<String> insertComment(Comment comment) async {
    final db = await database;
    await db.insert(
      'comments',
      comment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return comment.id;
  }

  static Future<Comment?> getCommentById(
    String id, {
    String? currentUserId,
  }) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT c.*,
             CASE WHEN cl.comment_id IS NULL THEN 0 ELSE 1 END AS is_liked
      FROM comments c
      LEFT JOIN comment_likes cl
        ON cl.comment_id = c.id AND cl.user_id = ?
      WHERE c.id = ?
      LIMIT 1
      ''',
      [currentUserId ?? '', id],
    );
    if (maps.isEmpty) return null;
    return Comment.fromMap(maps.first);
  }

  static Future<List<Comment>> getCommentsByPost(
    String postId, {
    int limit = 20,
    int offset = 0,
    String? currentUserId,
  }) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT c.*,
             CASE WHEN cl.comment_id IS NULL THEN 0 ELSE 1 END AS is_liked
      FROM comments c
      LEFT JOIN comment_likes cl
        ON cl.comment_id = c.id AND cl.user_id = ?
      WHERE c.post_id = ?
      ORDER BY c.created_at DESC
      LIMIT ? OFFSET ?
      ''',
      [currentUserId ?? '', postId, limit, offset],
    );
    return maps.map(Comment.fromMap).toList();
  }

  static Future<int> getCommentCount(String postId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt
      FROM comments
      WHERE post_id = ?
      ''',
      [postId],
    );
    return result.first['cnt'] as int? ?? 0;
  }

  static Future<int> syncSocialPostCommentCount(String postId) async {
    final db = await database;
    final count = await getCommentCount(postId);
    await db.update(
      'social_posts',
      {'comment_count': count},
      where: 'id = ?',
      whereArgs: [postId],
    );
    return count;
  }

  static Future<int> deleteComment(String commentId) async {
    final db = await database;
    return db.transaction((txn) async {
      final targets = await txn.query(
        'comments',
        columns: ['id'],
        where: 'id = ? OR parent_id = ?',
        whereArgs: [commentId, commentId],
      );
      if (targets.isEmpty) {
        return 0;
      }

      final ids = targets.map((item) => item['id'] as String).toList();
      final placeholders = List.filled(ids.length, '?').join(', ');

      await txn.delete(
        'comment_likes',
        where: 'comment_id IN ($placeholders)',
        whereArgs: ids,
      );
      return txn.delete(
        'comments',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    });
  }

  static Future<bool> toggleCommentLike(String commentId, String userId) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'comment_likes',
        columns: ['comment_id'],
        where: 'comment_id = ? AND user_id = ?',
        whereArgs: [commentId, userId],
        limit: 1,
      );

      final nextLiked = existing.isEmpty;
      if (nextLiked) {
        await txn.insert('comment_likes', {
          'comment_id': commentId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        await txn.rawUpdate(
          '''
          UPDATE comments
          SET like_count = like_count + 1
          WHERE id = ?
          ''',
          [commentId],
        );
      } else {
        await txn.delete(
          'comment_likes',
          where: 'comment_id = ? AND user_id = ?',
          whereArgs: [commentId, userId],
        );
        await txn.rawUpdate(
          '''
          UPDATE comments
          SET like_count = CASE
            WHEN like_count > 0 THEN like_count - 1
            ELSE 0
          END
          WHERE id = ?
          ''',
          [commentId],
        );
      }

      return nextLiked;
    });
  }

  static Future<String> insertTransaction(
    wallet.Transaction transaction,
  ) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return transaction.id;
  }

  static Future<List<wallet.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => wallet.Transaction.fromMap(m)).toList();
  }

  static Future<int> updateTransaction(wallet.Transaction transaction) async {
    final db = await database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  static Future<int> deleteTransaction(String id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<String> insertTransactionCategory(
    wallet.TransactionCategory category,
  ) async {
    final db = await database;
    await db.insert(
      'transaction_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return category.id;
  }

  static Future<List<wallet.TransactionCategory>>
  getAllTransactionCategories() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT id, name, emoji, type, is_default
      FROM transaction_categories
      ORDER BY
        CASE type WHEN 'expense' THEN 0 ELSE 1 END,
        rowid ASC
    ''');
    return maps.map((m) => wallet.TransactionCategory.fromMap(m)).toList();
  }

  static Future<int> updateTransactionCategory(
    wallet.TransactionCategory category,
  ) async {
    final db = await database;
    return db.update(
      'transaction_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<int> deleteTransactionCategory(String id) async {
    final db = await database;
    return db.delete(
      'transaction_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<String> insertMilestone(MilestoneProgress milestone) async {
    final db = await database;
    await db.insert(
      'milestone_progress',
      milestone.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log('[DB] 插入里程碑: ${milestone.title}', name: 'DatabaseService');
    return milestone.id;
  }

  static Future<List<MilestoneProgress>> getMilestonesByGoal(
    String goalId,
  ) async {
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
      ['skipped'],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 所有目标中最长连续打卡天数
  static Future<int> getMaxStreakDays() async {
    final db = await database;
    final goals = await db.query(
      'goals',
      columns: ['id'],
      where: 'status = ?',
      whereArgs: ['active'],
    );
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
    final maps = await db.query(
      'achievement_unlocks',
      orderBy: 'unlocked_at ASC',
    );
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
      log('[DB] 写入成就失败: $e', name: 'DatabaseService', error: e, stackTrace: s);
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
      [startInclusive.toIso8601String(), endExclusive.toIso8601String()],
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
    String seasonId,
  ) async {
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
      log(
        '[DB] 写入赛季总结失败: $e',
        name: 'DatabaseService',
        error: e,
        stackTrace: s,
      );
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

  static String _yearDateStart(int year) => '$year-01-01';

  static String _yearDateEnd(int year) => '$year-12-31';

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

    final buf = StringBuffer('日期,目标名称,打卡模式,完成状态,心情(1-5),投入时长(分钟),备注\n');
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

  static Future<void> _ensureMilestoneTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS milestone_progress (
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_milestone_goal_id ON milestone_progress (goal_id)',
    );
  }

  static Future<void> _createTransactionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        goal_id TEXT,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES transaction_categories (id),
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date DESC, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_goal ON transactions (goal_id)',
    );
  }

  static Future<void> _seedDefaultTransactionCategories(Database db) async {
    final batch = db.batch();
    for (final category in wallet.defaultTransactionCategories) {
      batch.insert(
        'transaction_categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _createNftAssetTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nft_assets (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        source_id TEXT,
        check_in_id TEXT,
        template_id TEXT,
        metadata TEXT,
        image_path TEXT NOT NULL,
        status TEXT NOT NULL,
        tx_hash TEXT,
        token_id TEXT,
        rarity TEXT,
        created_at TEXT NOT NULL,
        minted_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nft_assets_created_at ON nft_assets (created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nft_assets_source ON nft_assets (category, source_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nft_assets_check_in ON nft_assets (check_in_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nft_assets_rarity ON nft_assets (rarity)',
    );
  }

  static Future<int> updateMilestoneCardImage(
    String milestoneId,
    String imagePath,
  ) async {
    final db = await database;
    return db.update(
      'milestone_progress',
      {'card_image_path': imagePath},
      where: 'id = ?',
      whereArgs: [milestoneId],
    );
  }

  static Future<int> markMilestoneMinted(
    String milestoneId, {
    required String txHash,
    required String cardImagePath,
  }) async {
    final db = await database;
    return db.update(
      'milestone_progress',
      {
        'is_minted': 1,
        'mint_tx_hash': txHash,
        'card_image_path': cardImagePath,
      },
      where: 'id = ?',
      whereArgs: [milestoneId],
    );
  }

  static Future<String> insertNftAsset(NftAsset asset) async {
    final db = await database;
    await db.insert(
      'nft_assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return asset.id;
  }

  static Future<List<NftAsset>> getAllNftAssets() async {
    final db = await database;
    final maps = await db.query('nft_assets', orderBy: 'created_at DESC');
    return maps.map((m) => NftAsset.fromMap(m)).toList();
  }

  static Future<NftAsset?> getNftAssetById(String id) async {
    final db = await database;
    final maps = await db.query(
      'nft_assets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return NftAsset.fromMap(maps.first);
  }

  static Future<int> updateNftAsset(NftAsset asset) async {
    final db = await database;
    return db.update(
      'nft_assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  static Future<void> _createFriendTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS friendships (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        friend_id TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        accepted_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_friendships_user_status ON friendships (user_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_friendships_friend_status ON friendships (friend_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_friendships_pair ON friendships (user_id, friend_id)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS friend_profiles (
        id TEXT PRIMARY KEY,
        nickname TEXT NOT NULL,
        avatar_data TEXT,
        stats_json TEXT NOT NULL DEFAULT '{}',
        last_synced TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_friend_profiles_nickname ON friend_profiles (nickname)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_friend_profiles_last_synced ON friend_profiles (last_synced DESC)',
    );
  }

  static Future<void> _createSocialTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS social_posts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_avatar TEXT,
        avatar_config TEXT,
        content TEXT NOT NULL,
        title TEXT,
        subtitle TEXT,
        goal_id TEXT,
        goal_title TEXT,
        mood INTEGER,
        streak INTEGER,
        image_paths TEXT NOT NULL DEFAULT '[]',
        metadata TEXT,
        visibility TEXT NOT NULL DEFAULT 'public',
        achievement_title TEXT,
        type TEXT NOT NULL,
        like_count INTEGER NOT NULL DEFAULT 0,
        comment_count INTEGER NOT NULL DEFAULT 0,
        share_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        is_official INTEGER NOT NULL DEFAULT 0,
        is_friend_activity INTEGER NOT NULL DEFAULT 0,
        source_check_in_id TEXT,
        source_goal_id TEXT,
        source_nft_id TEXT,
        source_milestone_id TEXT,
        source_achievement_id TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_created_at ON social_posts (created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_friend_activity ON social_posts (is_friend_activity, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_user_created ON social_posts (user_id, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_visibility_created ON social_posts (visibility, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_goal_id ON social_posts (goal_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_social_posts_source_check_in ON social_posts (source_check_in_id)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS post_likes (
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (post_id, user_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_post_likes_user_time ON post_likes (user_id, created_at DESC)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_avatar TEXT,
        author_avatar_config TEXT,
        content TEXT NOT NULL,
        parent_id TEXT,
        reply_to_name TEXT,
        created_at TEXT NOT NULL,
        like_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comments_post_created_at ON comments (post_id, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comments_parent_created_at ON comments (parent_id, created_at ASC)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comment_likes (
        comment_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (comment_id, user_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comment_likes_user_time ON comment_likes (user_id, created_at DESC)',
    );
  }

  static Future<void> _createTodoTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS todo_items (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        content TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_todo_items_goal_date ON todo_items (goal_id, date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_todo_items_date ON todo_items (date)',
    );
  }
}
