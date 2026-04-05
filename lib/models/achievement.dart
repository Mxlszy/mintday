/// 成就维度：时间习惯 / 行为模式 / 长期坚持。
enum AchievementDimension {
  time('time', '时间节奏'),
  behavior('behavior', '行为模式'),
  longTerm('long_term', '长期里程碑');

  const AchievementDimension(this.value, this.label);
  final String value;
  final String label;
}

/// 全局成就标识（与配置一一对应，便于持久化与 UI 绑定）。
enum AchievementId {
  timeEarlyBird,
  timeNightOwl,
  timeDeepNight,
  timeNoon,
  timeAfterWork,
  streakGlobal3,
  streakGlobal7,
  streakGlobal14,
  streakGlobal30,
  streakGlobal60,
  streakGlobal100,
  goalStreak7,
  goalStreak30,
  perfectDayOnce,
  tripleCheckInDay,
  firstReflection,
  reflectionMode10,
  quickMode20,
  withPhoto,
  moodHighFive,
  categories3,
  totalCheckIns50,
  totalCheckIns200,
  lifetimeDistinctDays14,
  weekendCheckIn4,
  partialBrave,
  doubleReflectionDay,
}

/// 单条成就定义（静态配置，无状态）。
class AchievementDefinition {
  final AchievementId id;
  final AchievementDimension dimension;
  final String title;
  final String subtitle;

  const AchievementDefinition({
    required this.id,
    required this.dimension,
    required this.title,
    required this.subtitle,
  });

  /// 稳定存储用 slug（与枚举名一致，避免改名破坏历史数据时可再迁移）。
  String get slug => id.name;
}

/// 全量成就目录（20+）。
class AchievementCatalog {
  AchievementCatalog._();

  static const List<AchievementDefinition> all = [
    // —— 时间维度 ——
    AchievementDefinition(
      id: AchievementId.timeEarlyBird,
      dimension: AchievementDimension.time,
      title: '晨光见证',
      subtitle: '在 5:00–7:59 之间完成过一次打卡',
    ),
    AchievementDefinition(
      id: AchievementId.timeNightOwl,
      dimension: AchievementDimension.time,
      title: '星夜同行',
      subtitle: '在 23:00–次日 1:59 之间完成过一次打卡',
    ),
    AchievementDefinition(
      id: AchievementId.timeDeepNight,
      dimension: AchievementDimension.time,
      title: '静夜独行者',
      subtitle: '在 2:00–4:59 之间完成过一次打卡',
    ),
    AchievementDefinition(
      id: AchievementId.timeNoon,
      dimension: AchievementDimension.time,
      title: '午间一刻',
      subtitle: '在 11:00–13:59 之间完成过一次打卡',
    ),
    AchievementDefinition(
      id: AchievementId.timeAfterWork,
      dimension: AchievementDimension.time,
      title: '收工之后',
      subtitle: '在 18:00–20:59 之间完成过一次打卡',
    ),
    // —— 长期维度（连续日历日）——
    AchievementDefinition(
      id: AchievementId.streakGlobal3,
      dimension: AchievementDimension.longTerm,
      title: '三日火花',
      subtitle: '历史上曾达成至少 3 个连续日历日有打卡',
    ),
    AchievementDefinition(
      id: AchievementId.streakGlobal7,
      dimension: AchievementDimension.longTerm,
      title: '七日稳态',
      subtitle: '历史上曾达成至少 7 个连续日历日有打卡',
    ),
    AchievementDefinition(
      id: AchievementId.streakGlobal14,
      dimension: AchievementDimension.longTerm,
      title: '双周恒心',
      subtitle: '历史上曾达成至少 14 个连续日历日有打卡',
    ),
    AchievementDefinition(
      id: AchievementId.streakGlobal30,
      dimension: AchievementDimension.longTerm,
      title: '满月之行',
      subtitle: '历史上曾达成至少 30 个连续日历日有打卡',
    ),
    AchievementDefinition(
      id: AchievementId.streakGlobal60,
      dimension: AchievementDimension.longTerm,
      title: '两月之约',
      subtitle: '历史上曾达成至少 60 个连续日历日有打卡',
    ),
    AchievementDefinition(
      id: AchievementId.streakGlobal100,
      dimension: AchievementDimension.longTerm,
      title: '百日筑基',
      subtitle: '历史上曾达成至少 100 个连续日历日有打卡',
    ),
    AchievementDefinition(
      id: AchievementId.goalStreak7,
      dimension: AchievementDimension.longTerm,
      title: '单线七连',
      subtitle: '任一目标曾达成至少 7 天连续打卡（跳过不计入）',
    ),
    AchievementDefinition(
      id: AchievementId.goalStreak30,
      dimension: AchievementDimension.longTerm,
      title: '单线满月',
      subtitle: '任一目标曾达成至少 30 天连续打卡（跳过不计入）',
    ),
    // —— 行为维度 ——
    AchievementDefinition(
      id: AchievementId.perfectDayOnce,
      dimension: AchievementDimension.behavior,
      title: '同日全垒打',
      subtitle: '某一天内，当前所有活跃目标均完成过非「跳过」打卡',
    ),
    AchievementDefinition(
      id: AchievementId.tripleCheckInDay,
      dimension: AchievementDimension.behavior,
      title: '高能一日',
      subtitle: '单日累计完成 3 次及以上非「跳过」打卡',
    ),
    AchievementDefinition(
      id: AchievementId.firstReflection,
      dimension: AchievementDimension.behavior,
      title: '第一次审视',
      subtitle: '使用过至少一次「反思打卡」模式',
    ),
    AchievementDefinition(
      id: AchievementId.reflectionMode10,
      dimension: AchievementDimension.behavior,
      title: '内观十次',
      subtitle: '累计完成 10 次反思打卡',
    ),
    AchievementDefinition(
      id: AchievementId.quickMode20,
      dimension: AchievementDimension.behavior,
      title: '轻快步频',
      subtitle: '累计完成 20 次快速打卡',
    ),
    AchievementDefinition(
      id: AchievementId.withPhoto,
      dimension: AchievementDimension.behavior,
      title: '有图有真相',
      subtitle: '至少一次打卡附带图片记录',
    ),
    AchievementDefinition(
      id: AchievementId.moodHighFive,
      dimension: AchievementDimension.behavior,
      title: '心情高光',
      subtitle: '累计 5 次心情评分在 4 分及以上',
    ),
    AchievementDefinition(
      id: AchievementId.categories3,
      dimension: AchievementDimension.behavior,
      title: '多面人生',
      subtitle: '打卡覆盖至少 3 种不同的目标分类',
    ),
    AchievementDefinition(
      id: AchievementId.totalCheckIns50,
      dimension: AchievementDimension.behavior,
      title: '五十次出发',
      subtitle: '累计非「跳过」打卡达到 50 次',
    ),
    AchievementDefinition(
      id: AchievementId.totalCheckIns200,
      dimension: AchievementDimension.behavior,
      title: '二百次沉淀',
      subtitle: '累计非「跳过」打卡达到 200 次',
    ),
    AchievementDefinition(
      id: AchievementId.lifetimeDistinctDays14,
      dimension: AchievementDimension.behavior,
      title: '十四日留痕',
      subtitle: '累计在 14 个不同日历日有过打卡',
    ),
    AchievementDefinition(
      id: AchievementId.weekendCheckIn4,
      dimension: AchievementDimension.behavior,
      title: '周末在场',
      subtitle: '周末（周六、周日）累计打卡至少 4 次',
    ),
    AchievementDefinition(
      id: AchievementId.partialBrave,
      dimension: AchievementDimension.behavior,
      title: '部分也作数',
      subtitle: '累计 5 次「部分完成」打卡，仍坚持记录',
    ),
    AchievementDefinition(
      id: AchievementId.doubleReflectionDay,
      dimension: AchievementDimension.behavior,
      title: '同日双思',
      subtitle: '某一日历日内完成至少 2 次反思打卡',
    ),
  ];

  static final Map<AchievementId, AchievementDefinition> byId = {
    for (final a in all) a.id: a,
  };

  static int get count => all.length;
}
