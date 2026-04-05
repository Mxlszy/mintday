import '../models/check_in.dart';
import '../models/goal.dart';
import 'pixel_icons.dart';

class CollectibleBadge {
  final String title;
  final String subtitle;
  final PixelIconData icon;
  final int colorIndex;
  final bool unlocked;

  const CollectibleBadge({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorIndex,
    required this.unlocked,
  });
}

enum JourneyNodeStatus {
  complete,
  current,
  locked,
}

class JourneyNode {
  final String label;
  final String caption;
  final PixelIconData icon;
  final JourneyNodeStatus status;

  const JourneyNode({
    required this.label,
    required this.caption,
    required this.icon,
    required this.status,
  });
}

List<CollectibleBadge> buildCollectibleBadges({
  required List<Goal> goals,
  required List<CheckIn> checkIns,
  required int maxStreak,
}) {
  final completedGoals =
      goals.where((goal) => goal.status == GoalStatus.completed).length;
  final hasImages = checkIns.any((checkIn) => checkIn.imagePaths.isNotEmpty);
  final hasDeepProgress = goals.any((goal) => goal.progress >= 0.5);

  return [
    CollectibleBadge(
      title: '第一笔记录',
      subtitle: '完成第一次打卡',
      icon: PixelIcons.pencil,
      colorIndex: 0,
      unlocked: checkIns.isNotEmpty,
    ),
    CollectibleBadge(
      title: '旅程启动',
      subtitle: '创建至少 1 个目标',
      icon: PixelIcons.sprout,
      colorIndex: 1,
      unlocked: goals.isNotEmpty,
    ),
    CollectibleBadge(
      title: '三日火花',
      subtitle: '连续打卡达到 3 天',
      icon: PixelIcons.bolt,
      colorIndex: 2,
      unlocked: maxStreak >= 3,
    ),
    CollectibleBadge(
      title: '七日稳态',
      subtitle: '连续打卡达到 7 天',
      icon: PixelIcons.trophy,
      colorIndex: 1,
      unlocked: maxStreak >= 7,
    ),
    CollectibleBadge(
      title: '深水推进',
      subtitle: '任一目标推进到 50%',
      icon: PixelIcons.chart,
      colorIndex: 3,
      unlocked: hasDeepProgress,
    ),
    CollectibleBadge(
      title: '完成一程',
      subtitle: '完成至少 1 个目标',
      icon: PixelIcons.trophy,
      colorIndex: 0,
      unlocked: completedGoals >= 1,
    ),
    CollectibleBadge(
      title: '图鉴收藏家',
      subtitle: '累计记录达到 10 条',
      icon: PixelIcons.diamond,
      colorIndex: 1,
      unlocked: checkIns.length >= 10,
    ),
    CollectibleBadge(
      title: '留住证据',
      subtitle: '完成 1 次图片打卡',
      icon: PixelIcons.star,
      colorIndex: 3,
      unlocked: hasImages,
    ),
  ];
}

List<JourneyNode> buildJourneyNodes({
  required Goal goal,
  required int streakDays,
  required int totalCheckIns,
}) {
  final reached = <bool>[
    true,
    totalCheckIns >= 1,
    totalCheckIns >= 3 || streakDays >= 3 || goal.progress >= 0.25,
    totalCheckIns >= 7 || streakDays >= 7 || goal.progress >= 0.6,
    goal.status == GoalStatus.completed || goal.progress >= 1,
  ];

  final firstLocked = reached.indexWhere((value) => !value);
  final currentIndex = firstLocked == -1 ? reached.length - 1 : firstLocked;

  return [
    JourneyNode(
      label: '启程',
      caption: '立下目标',
      icon: PixelIcons.flag,
      status: _resolveNodeStatus(
        index: 0,
        currentIndex: currentIndex,
        isUnlocked: reached[0],
        isFullyUnlocked: firstLocked == -1,
      ),
    ),
    JourneyNode(
      label: '落笔',
      caption: totalCheckIns > 0 ? '$totalCheckIns 次记录' : '等待第一笔',
      icon: PixelIcons.check,
      status: _resolveNodeStatus(
        index: 1,
        currentIndex: currentIndex,
        isUnlocked: reached[1],
        isFullyUnlocked: firstLocked == -1,
      ),
    ),
    JourneyNode(
      label: '稳态',
      caption: streakDays >= 1 ? '连续 $streakDays 天' : '建立节奏',
      icon: PixelIcons.fire,
      status: _resolveNodeStatus(
        index: 2,
        currentIndex: currentIndex,
        isUnlocked: reached[2],
        isFullyUnlocked: firstLocked == -1,
      ),
    ),
    JourneyNode(
      label: '突破',
      caption: '${(goal.progress * 100).toInt()}% 完成',
      icon: PixelIcons.diamond,
      status: _resolveNodeStatus(
        index: 3,
        currentIndex: currentIndex,
        isUnlocked: reached[3],
        isFullyUnlocked: firstLocked == -1,
      ),
    ),
    JourneyNode(
      label: '完成',
      caption: goal.status == GoalStatus.completed ? '已抵达' : '终点待点亮',
      icon: PixelIcons.trophy,
      status: _resolveNodeStatus(
        index: 4,
        currentIndex: currentIndex,
        isUnlocked: reached[4],
        isFullyUnlocked: firstLocked == -1,
      ),
    ),
  ];
}

JourneyNodeStatus _resolveNodeStatus({
  required int index,
  required int currentIndex,
  required bool isUnlocked,
  required bool isFullyUnlocked,
}) {
  if (isFullyUnlocked) {
    return JourneyNodeStatus.complete;
  }
  if (index < currentIndex && isUnlocked) {
    return JourneyNodeStatus.complete;
  }
  if (index == currentIndex) {
    return JourneyNodeStatus.current;
  }
  return JourneyNodeStatus.locked;
}
