import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/pixel_icons.dart';
import 'core/theme/app_theme.dart';
import 'pages/history/history_page.dart';
import 'pages/home/home_page.dart';
import 'pages/progress/progress_page.dart';
import 'models/achievement.dart';
import 'providers/check_in_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/share_export_provider.dart';
import 'providers/user_profile_provider.dart';
import 'widgets/share/share_sheets.dart';

class MintDayApp extends StatelessWidget {
  const MintDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalProvider()..init()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()..init()),
        ChangeNotifierProvider(create: (_) => ShareExportProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()..init()),
        ChangeNotifierProvider(
          create: (context) => CheckInProvider(
            gamification: context.read<GamificationProvider>(),
          )..init(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MainScaffold(),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  GamificationProvider? _gamification;
  bool _achievementShareOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = context.read<GamificationProvider>();
    if (!identical(_gamification, g)) {
      _gamification?.removeListener(_onGamificationChanged);
      _gamification = g;
      g.addListener(_onGamificationChanged);
    }
  }

  @override
  void dispose() {
    _gamification?.removeListener(_onGamificationChanged);
    super.dispose();
  }

  void _onGamificationChanged() {
    if (!mounted || _achievementShareOpen) return;
    final g = _gamification!;
    if (g.pendingAchievementUnlocks.isEmpty) return;

    final ids = List<AchievementId>.from(g.pendingAchievementUnlocks);
    _achievementShareOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showAchievementShareSheet(context, achievementIds: ids);
      if (mounted) {
        _achievementShareOpen = false;
        g.clearPendingAchievements();
      }
    });
  }

  final List<Widget> _pages = const [
    HomePage(),
    HistoryPage(),
    ProgressPage(),
  ];

  static const _navItems = [
    (icon: PixelIcons.home, label: '主控台'),
    (icon: PixelIcons.clock, label: '卷轴'),
    (icon: PixelIcons.chart, label: '图鉴'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          0,
          AppTheme.spacingL,
          AppTheme.spacingL,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.neuRaised,
          ),
          child: Row(
            children: List.generate(_navItems.length, (index) {
              return Expanded(
                child: _buildNavItem(
                  index,
                  _navItems[index].icon,
                  _navItems[index].label,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, PixelIconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelIcon(
              icon: icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyle.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
