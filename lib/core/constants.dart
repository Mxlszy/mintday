/// 动态问候：连续天数分档。
enum MintGreetingStreakTier {
  /// 0 天
  zero,

  /// 1–2 天
  oneToTwo,

  /// 3–6 天
  threeToSix,

  /// 7–13 天
  sevenToThirteen,

  /// 14–29 天
  fourteenToTwentyNine,

  /// 30 天及以上
  thirtyPlus,
}

/// 动态问候：今日相对打卡状态。
enum MintGreetingTodayStatus {
  /// 仍有目标未完成今日打卡
  notChecked,

  /// 全部活跃目标今日已打卡
  completedToday,

  /// 曾有记录但连续已断（streak 为 0）
  streakBroken,
}

class AppConstants {
  AppConstants._();

  static const String appName = 'MintDay';
  static const String appVersion = '1.0.0';

  static const List<String> encouragementMessages = [
    '又一天，你比昨天更接近想去的地方。',
    '每一次记录，都是在为自己作证。',
    '不是每一天都轻松，但你今天做到了。',
    '小步向前，也是在向前。',
    '你正在成为你想成为的那个人。',
    '坚持本身，就已经很了不起。',
    '记录就是力量，继续走下去吧。',
    '这段旅程，值得被认真记住。',
    '今天的你，比开始那天更稳了。',
    '把每一天都过成值得回看的样子。',
  ];

  static const String emptyGoalTitle = '开始你的第一段旅程';
  static const String emptyGoalSubtitle =
      '设定一个目标，每天记录一点点。你正在成为的那个人，就从这里开始。';

  static const String emptyHistoryTitle = '还没有打卡记录';
  static const String emptyHistorySubtitle =
      '完成第一次打卡后，你的成长轨迹会出现在这里。';

  static const List<int> streakMilestones = [3, 7, 14, 30, 60, 100];
  static const int maxImagesPerCheckIn = 3;
  static const String dbName = 'mintday.db';

  /// 连续天数档 × 今日状态；每格至少 3 条，旅程语气。
  static const Map<MintGreetingStreakTier,
      Map<MintGreetingTodayStatus, List<String>>> dynamicGreetings = {
    MintGreetingStreakTier.zero: {
      MintGreetingTodayStatus.notChecked: [
        '今天的第一格，从这里开始下笔。',
        '空白的日历在等你，落下第一次记录就好。',
        '新一天的地图展开了，先标上一个起点吧。',
      ],
      MintGreetingTodayStatus.completedToday: [
        '你已经把今天写进旅程里了，真不错。',
        '今天的记录落下来了，这是属于你的脚印。',
        '亮起的第一格，叫什么名字都好听。',
      ],
      MintGreetingTodayStatus.streakBroken: [
        '连续断了也没关系，旅程本来就会有岔路。',
        '昨天没跟上也没关系，今天可以从这里重新接上轨。',
        '打卡会断，想去的地方不会消失——今天再把你接回路上。',
      ],
    },
    MintGreetingStreakTier.oneToTwo: {
      MintGreetingTodayStatus.notChecked: [
        '小火苗刚亮起来，今天也别忘了添一根柴。',
        '连续在生长，今天再往前挪一小步。',
        '才刚开始的节拍，今天一起踩下去。',
      ],
      MintGreetingTodayStatus.completedToday: [
        '又续了一天——旅程就是这样一点一点变长的。',
        '今天你把自己接得很稳，继续就好。',
        '小小的连续，也是了不起的惯性。',
      ],
      MintGreetingTodayStatus.streakBroken: [
        '岔路之后还是路，今天可以再点起火种。',
        '节奏可以重来，你比想象中更容易再回到轨道。',
        '每一次重新打卡，都是旅程的第二章开场。',
      ],
    },
    MintGreetingStreakTier.threeToSix: {
      MintGreetingTodayStatus.notChecked: [
        '连续快一周了，今天别让它悄悄断掉。',
        '这段路你已经走得有模有样，再推一格。',
        '旅程的中段最考验人——你今天的选择会写进故事。',
      ],
      MintGreetingTodayStatus.completedToday: [
        '又稳一天，你的连续正在变成习惯。',
        '这几天的坚持，已经为后面的你铺了路。',
        '今天也亮格了，你正在把自己的承诺当真。',
      ],
      MintGreetingTodayStatus.streakBroken: [
        '火花可以重燃，你这段路的经验都还在。',
        '连续会休息，但想去的地方不会抹掉。',
        '停下来喘气可以，今天就能把线再接上。',
      ],
    },
    MintGreetingStreakTier.sevenToThirteen: {
      MintGreetingTodayStatus.notChecked: [
        '快两周了，今天的这一格也很重要。',
        '里程碑在望，今天的格子别留白。',
        '你已经走出了一小段里程，今天把它续上。',
      ],
      MintGreetingTodayStatus.completedToday: [
        '又一天入账，你在把自己练成「说到做到」的样子。',
        '这段连续值得骄傲，今天你也没有辜负它。',
        '记录叠起来，就是你的旅程厚度。',
      ],
      MintGreetingTodayStatus.streakBroken: [
        '长跑也会绊一下，重要的是你还愿意站起来。',
        '断点不是结局，是你改写故事的下一笔。',
        '曾经的连续做过数，今天可以重新开始计数。',
      ],
    },
    MintGreetingStreakTier.fourteenToTwentyNine: {
      MintGreetingTodayStatus.notChecked: [
        '快要满月了，今天这格会是故事里的关键一笔。',
        '这么久都走过来了，今天也别轻易松手。',
        '你的旅程已经有了弧度，今天再画一小段。',
      ],
      MintGreetingTodayStatus.completedToday: [
        '又稳稳地走过一天，你在给未来的自己留证据。',
        '连续快一个月了——这是只有坚持才能看到的风景。',
        '今天你再次投票给了「想成为的自己」。',
      ],
      MintGreetingTodayStatus.streakBroken: [
        '那么长的路都走过，重新出发只会更熟练。',
        '旅程不会因为暂停就消失，今天再按下继续。',
        '你证明过一次，就能再证明第二次。',
      ],
    },
    MintGreetingStreakTier.thirtyPlus: {
      MintGreetingTodayStatus.notChecked: [
        '三十格以上的旅程里，今天仍然算数。',
        '你已经是很会走长路的人了，今天也别缺席。',
        '习惯早已扎根，今天轻点一下就好。',
      ],
      MintGreetingTodayStatus.completedToday: [
        '又是一个被点亮的平常日——这就是长路旅人的样子。',
        '三十天以外的你，已经和日历上的数字成了朋友。',
        '今天的记录，是你给漫长旅程的又一次落款。',
      ],
      MintGreetingTodayStatus.streakBroken: [
        '长跑歇一口气无可厚非，再起跑时你还在同一条路上。',
        '那么长的连续已经足够证明你，今天从一格重新开始也很好。',
        '旧章翻过，新章照样可以写得很远。',
      ],
    },
  };
}

/// 分区标题与高频 UI 文案（与 [AppConstants] 鼓励语、空态文案互补）。
class AppStrings {
  AppStrings._();

  static const String homeEyebrowBadges = '最近点亮';
  static const String homeTitleBadges = '成长徽章';
  static const String homeEyebrowJourney = '正在推进';
  static const String homeTitleJourney = '当前旅程';
  static const String homeJourneyHint = '把今天要完成的事情先推进一格。';

  static const String progressPageTitle = '成长图鉴';
  static const String progressPageSubtitle =
      '把推进轨迹和成就收藏放在一起看。';
  static const String progressViewJourney = '旅程地图';
  static const String progressViewBadges = '徽章墙';
  static const String progressEmptyBadgesTitle = '图鉴还没有内容';
  static const String progressEmptyBadgesSubtitle =
      '从第一个目标和第一次记录开始，这里会慢慢长成你的成长收藏墙。';

  /// 年度报告入口占位说明（避免对用户说「开发中」）。
  static const String annualReportComingSoon =
      '年度报告即将上线，届时可一键生成长图分享。';
  static const String annualReportComingSoonButton = '知道了';
}

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String createGoal = '/goal/create';
  static const String goalDetail = '/goal/detail';
  static const String checkIn = '/check-in';
  static const String history = '/history';
  static const String progress = '/progress';
}
