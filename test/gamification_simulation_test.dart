import 'package:flutter_test/flutter_test.dart';
import 'package:mintday/core/achievement_evaluator.dart';
import 'package:mintday/core/season_rolling_utils.dart';
import 'package:mintday/models/achievement.dart';
import 'package:mintday/models/check_in.dart';
import 'package:mintday/models/goal.dart';

/// 纯内存模拟：不连真实 DB，便于在终端观察成就与赛季统计行为。
///
/// 运行（展开输出）：
/// `flutter test test/gamification_simulation_test.dart --reporter expanded`
void main() {
  test('模拟：链上人生账本 · 成就 + 30 日赛季统计演示', () {
    final buffer = StringBuffer();

    void p(String s) {
      // ignore: avoid_print
      print(s);
      buffer.writeln(s);
    }

    p('');
    p('══════════════════════════════════════════════════════════════');
    p('  MintDay 成就 / 赛季 模拟（虚构数据）');
    p('══════════════════════════════════════════════════════════════');

    // 锚点 2024-01-01，赛季 0 = 2024-01-01 ~ 2024-01-30
    final anchor = SeasonRollingUtils.defaultAnchorDate;
    p('\n【赛季锚点】$anchor  →  当前演示赛季 index=0（s30_0）\n');

    final gHabit = Goal(
      id: 'goal-habit',
      title: '晨间阅读',
      category: GoalCategory.habit,
      status: GoalStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      seasonId: 's30_0',
    );
    final gHealth = Goal(
      id: 'goal-health',
      title: '跑步',
      category: GoalCategory.health,
      status: GoalStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      seasonId: 's30_0',
    );
    final gStudy = Goal(
      id: 'goal-study',
      title: '刷题',
      category: GoalCategory.study,
      status: GoalStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      seasonId: 's30_0',
    );
    final goals = [gHabit, gHealth, gStudy];

    // 构造打卡：连续 10 天 + 时间维度 + 反思 + 部分完成 + 某日三目标齐打卡 + 单日多条
    final checkIns = <CheckIn>[];
    var id = 0;
    CheckIn mk({
      required String goalId,
      required DateTime date,
      required int hour,
      CheckInMode mode = CheckInMode.quick,
      CheckInStatus status = CheckInStatus.done,
      int? mood,
      List<String> images = const [],
    }) {
      final created = DateTime(date.year, date.month, date.day, hour, 10);
      return CheckIn(
        id: 'sim-${id++}',
        goalId: goalId,
        date: date,
        mode: mode,
        status: status,
        mood: mood,
        createdAt: created,
      );
    }

    // 1/1：晨光 + 夜间 + 习惯线
    checkIns.add(mk(
      goalId: gHabit.id,
      date: DateTime(2024, 1, 1),
      hour: 6,
    ));
    checkIns.add(mk(
      goalId: gHealth.id,
      date: DateTime(2024, 1, 1),
      hour: 23,
    ));
    // 1/2 ~ 1/9：习惯每日打卡（叠全球连续日）
    for (var d = 2; d <= 9; d++) {
      checkIns.add(mk(
        goalId: gHabit.id,
        date: DateTime(2024, 1, d),
        hour: 9,
      ));
    }
    // 1/10：同日全垒打（三个目标都打卡）+ 多一条刷题形成「高能一日」
    checkIns.add(mk(goalId: gHabit.id, date: DateTime(2024, 1, 10), hour: 7));
    checkIns.add(mk(goalId: gHealth.id, date: DateTime(2024, 1, 10), hour: 12));
    checkIns.add(mk(goalId: gStudy.id, date: DateTime(2024, 1, 10), hour: 19));
    checkIns.add(mk(goalId: gStudy.id, date: DateTime(2024, 1, 10), hour: 20));
    // 反思若干次
    for (var i = 0; i < 10; i++) {
      checkIns.add(mk(
        goalId: gHabit.id,
        date: DateTime(2024, 1, 11 + i),
        hour: 21,
        mode: CheckInMode.reflection,
        mood: 4,
      ));
    }
    // 快速打卡凑 20+
    for (var i = 0; i < 12; i++) {
      checkIns.add(mk(
        goalId: gHealth.id,
        date: DateTime(2024, 1, 11 + (i % 5)),
        hour: 8,
      ));
    }
    // 带图 1 次
    checkIns.add(mk(
      goalId: gStudy.id,
      date: DateTime(2024, 1, 25),
      hour: 15,
      images: const ['/fake/path.jpg'],
    ));
    // 部分完成 5 次
    for (var i = 0; i < 5; i++) {
      checkIns.add(mk(
        goalId: gHabit.id,
        date: DateTime(2024, 1, 26 + i),
        hour: 10,
        status: CheckInStatus.partial,
      ));
    }
    // 某日双反思
    checkIns.add(mk(
      goalId: gHabit.id,
      date: DateTime(2024, 1, 28),
      hour: 8,
      mode: CheckInMode.reflection,
    ));
    checkIns.add(mk(
      goalId: gHealth.id,
      date: DateTime(2024, 1, 28),
      hour: 20,
      mode: CheckInMode.reflection,
    ));

    p('【虚构数据】');
    p('  活跃目标: ${goals.length}（习惯 / 健康 / 学习，seasonId=s30_0）');
    p('  打卡条数: ${checkIns.length}（含跳过逻辑外数据）\n');

    // ── 成就 ──
    final snap = AchievementEvaluationSnapshot.build(
      goals: goals,
      checkIns: checkIns,
    );
    p('【成就快照】');
    p('  全局最长连续日历日（任目标非跳过）: ${snap.globalMaxStreakDays}');
    p('  单目标最长连续: ${snap.maxSingleGoalStreak}');
    p('  不同打卡日数: ${snap.distinctCalendarDays}');
    p('  非跳过总次数: ${snap.totalNonSkipCount}\n');

    final unlocked = AchievementEvaluator.evaluateAllUnlocked(snap);
    p('【本模拟下已满足成就】共 ${unlocked.length} / ${AchievementCatalog.count}');
    for (final id in unlocked.toList()..sort((a, b) => a.name.compareTo(b.name))) {
      final def = AchievementCatalog.byId[id];
      if (def != null) {
        p('  · [${def.dimension.label}] ${def.title} — ${def.subtitle}');
      }
    }

    final fakePrev = <AchievementId>{AchievementId.streakGlobal100};
    final delta = AchievementEvaluator.newlyUnlocked(
      snapshot: snap,
      previouslyUnlocked: fakePrev,
    );
    p('\n【增量演示】若库中已仅有「百日筑基」时，本轮「新解锁」条数: ${delta.length}');

    // ── 赛季总结（index 0，与锚点一致）──
    final window = SeasonRollingUtils.windowForIndex(0, anchor: anchor);
    p('\n【赛季窗口】${window.seasonId}');
    p('  ${window.startInclusive.toIso8601String().split('T').first} '
        '~ ${window.endInclusive.toIso8601String().split('T').first}');

    final summary = SeasonRollingUtils.buildSeasonSummary(
      seasonIndex: 0,
      goals: goals,
      checkIns: checkIns,
      achievementsUnlockedInSeason: 8,
      anchor: anchor,
    );
    p('\n【赛季总结卡字段】（成就数参数模拟为 8）');
    p('  参与目标数: ${summary.goalsInSeasonCount}');
    p('  完成率(日均): ${(summary.completionRate * 100).toStringAsFixed(1)}%');
    p('  窗口内最佳连续日: ${summary.bestStreakDays}');
    p('  窗口内非跳过打卡次数: ${summary.totalCheckInsInWindow}');
    p('  赛季内解锁成就数(模拟): ${summary.achievementsUnlockedCount}');

    p('\n【JSON 预览】');
    p(summary.toJson().toString());

    p('\n══════════════════════════════════════════════════════════════');
    p('  模拟结束（真实 App 中由 GamificationProvider + DB 闭环写入）');
    p('══════════════════════════════════════════════════════════════\n');

    expect(unlocked.length, greaterThan(10));
    expect(summary.seasonId, 's30_0');
    expect(buffer.isNotEmpty, true);
  });
}
