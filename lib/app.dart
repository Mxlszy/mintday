import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_navigator.dart';
import 'core/constants.dart';
import 'core/pixel_icons.dart';
import 'core/theme/app_theme.dart';
import 'models/achievement.dart';
import 'pages/auth/login_page.dart';
import 'pages/focus/focus_page.dart';
import 'pages/home/home_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/social/social_page.dart';
import 'pages/wallet/wallet_page.dart';
import 'providers/ai_companion_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/check_in_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/nft_provider.dart';
import 'providers/share_export_provider.dart';
import 'providers/social_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_profile_provider.dart';
import 'services/sync_service.dart';
import 'services/user_profile_prefs.dart';
import 'widgets/share/share_sheets.dart';
import 'widgets/touch_scale_wrapper.dart';

class MintDayApp extends StatelessWidget {
  const MintDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => GoalProvider()..init()),
        ChangeNotifierProvider(create: (_) => TodoProvider()..init()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()..init()),
        ChangeNotifierProvider(create: (_) => NftProvider()..init()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()..init()),
        ChangeNotifierProvider(create: (_) => ShareExportProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()..init()),
        ChangeNotifierProvider(
          create: (context) => CheckInProvider(
            gamification: context.read<GamificationProvider>(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              FocusProvider(checkInProvider: context.read<CheckInProvider>())
                ..init(),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          UserProfileProvider,
          FriendProvider
        >(
          create: (context) => FriendProvider(
            authProvider: context.read<AuthProvider>(),
            userProfileProvider: context.read<UserProfileProvider>(),
          )..init(),
          update: (_, auth, userProfile, provider) {
            final friendProvider =
                provider ??
                FriendProvider(
                  authProvider: auth,
                  userProfileProvider: userProfile,
                );
            friendProvider.updateDependencies(
              authProvider: auth,
              userProfileProvider: userProfile,
            );
            return friendProvider;
          },
        ),
        ChangeNotifierProxyProvider3<
          CheckInProvider,
          GoalProvider,
          FocusProvider,
          AiCompanionProvider
        >(
          create: (_) => AiCompanionProvider()..init(),
          update: (_, checkIn, goal, focus, provider) {
            final aiProvider = provider ?? AiCompanionProvider();
            aiProvider.updateDependencies(
              checkInProvider: checkIn,
              goalProvider: goal,
              focusProvider: focus,
            );
            return aiProvider;
          },
        ),
        ChangeNotifierProxyProvider3<
          CheckInProvider,
          GoalProvider,
          UserProfileProvider,
          SocialProvider
        >(
          create: (context) => SocialProvider(
            checkInProvider: context.read<CheckInProvider>(),
            goalProvider: context.read<GoalProvider>(),
            userProfileProvider: context.read<UserProfileProvider>(),
          )..init(),
          update: (_, checkIn, goal, userProfile, provider) {
            final socialProvider =
                provider ??
                SocialProvider(
                  checkInProvider: checkIn,
                  goalProvider: goal,
                  userProfileProvider: userProfile,
                );
            socialProvider.updateDependencies(
              checkInProvider: checkIn,
              goalProvider: goal,
              userProfileProvider: userProfile,
            );
            return socialProvider;
          },
        ),
      ],
      child: Consumer<UserProfileProvider>(
        builder: (context, userProfile, _) {
          AppTheme.setDarkMode(userProfile.isDarkMode);

          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: userProfile.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: const AppStartupGate(),
          );
        },
      ),
    );
  }
}

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool? _onboardingCompleted;
  String? _lastHandledUserId;
  bool _syncCheckInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<AuthProvider>().bindUserProfileProvider(
      context.read<UserProfileProvider>(),
    );
  }

  Future<void> _loadOnboardingStatus() async {
    final completed = await UserProfilePrefs.getOnboardingCompleted();
    if (!mounted) return;
    setState(() => _onboardingCompleted = completed);
  }

  void _handleOnboardingCompleted() {
    if (!mounted) return;
    setState(() => _onboardingCompleted = true);
  }

  Future<void> _handleAuthenticatedUser() async {
    if (_syncCheckInFlight) return;

    final authProvider = context.read<AuthProvider>();
    final userProfileProvider = context.read<UserProfileProvider>();
    final user = authProvider.user;
    if (user == null) return;
    if (_lastHandledUserId == user.id) return;

    _lastHandledUserId = user.id;
    _syncCheckInFlight = true;

    try {
      await userProfileProvider.syncFromAuth(user);

      final hasLocalData = await SyncService.checkLocalData();
      final alreadySynced = await UserProfilePrefs.getSyncedToCloud();
      if (!mounted || !hasLocalData || alreadySynced) return;

      await SyncService.showSyncDialog(context);
    } finally {
      _syncCheckInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.authenticated && auth.user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleAuthenticatedUser();
          });
          return const MainScaffold();
        }

        _lastHandledUserId = null;

        if (auth.status == AuthStatus.unknown || _onboardingCompleted == null) {
          return const _StartupLoadingView();
        }

        if (_onboardingCompleted == false) {
          return OnboardingPage(onCompleted: _handleOnboardingCompleted);
        }

        return const LoginPage();
      },
    );
  }
}

class _StartupLoadingView extends StatelessWidget {
  const _StartupLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: AppTheme.spacingL),
            Text('MintDay', style: AppTextStyle.h2),
          ],
        ),
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

  final List<Widget> _pages = const [
    HomePage(),
    FocusPage(),
    SocialPage(),
    WalletPage(),
    ProfilePage(),
  ];

  static const _navItems = [
    (icon: PixelIcons.home, label: '首页'),
    (icon: PixelIcons.bolt, label: '专注'),
    (icon: PixelIcons.heart, label: '社区'),
    (icon: PixelIcons.diamond, label: '钱包'),
    (icon: PixelIcons.star, label: '我的'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gamification = context.read<GamificationProvider>();
    if (!identical(_gamification, gamification)) {
      _gamification?.removeListener(_onGamificationChanged);
      _gamification = gamification;
      gamification.addListener(_onGamificationChanged);
    }
  }

  @override
  void dispose() {
    _gamification?.removeListener(_onGamificationChanged);
    super.dispose();
  }

  void _onGamificationChanged() {
    if (!mounted || _achievementShareOpen) return;
    final gamification = _gamification!;
    if (gamification.pendingAchievementUnlocks.isEmpty) return;

    final ids = List<AchievementId>.from(
      gamification.pendingAchievementUnlocks,
    );
    _achievementShareOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showAchievementShareSheet(context, achievementIds: ids);
      if (!mounted) return;
      _achievementShareOpen = false;
      gamification.clearPendingAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
    return _BottomNavItem(
      icon: icon,
      label: label,
      isSelected: _currentIndex == index,
      onTap: () => setState(() => _currentIndex = index),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final PixelIconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem>
    with TickerProviderStateMixin {
  late final AnimationController _selectionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.isSelected ? 1 : 0,
  );
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  late final Animation<double> _labelReveal = CurvedAnimation(
    parent: _selectionController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<double> _iconBounce = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.8,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 56,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.15,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 44,
    ),
  ]).animate(_bounceController);

  @override
  void didUpdateWidget(covariant _BottomNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected == oldWidget.isSelected) return;

    _selectionController.animateTo(widget.isSelected ? 1 : 0);
    if (!oldWidget.isSelected && widget.isSelected) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TouchScaleWrapper(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_selectionController, _bounceController]),
        builder: (context, _) {
          final backgroundColor =
              ColorTween(
                begin: Colors.transparent,
                end: AppTheme.primary,
              ).evaluate(_selectionController) ??
              Colors.transparent;
          final foregroundColor =
              ColorTween(
                begin: AppTheme.textSecondary,
                end: Colors.white,
              ).evaluate(_selectionController) ??
              AppTheme.textSecondary;

          return Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: widget.isSelected ? _iconBounce.value : 1,
                  child: PixelIcon(
                    icon: widget.icon,
                    size: 18,
                    color: foregroundColor,
                  ),
                ),
                ClipRect(
                  child: Align(
                    widthFactor: _labelReveal.value,
                    child: FadeTransition(
                      opacity: _labelReveal,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: AppTextStyle.caption.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
