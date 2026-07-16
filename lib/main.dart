import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/leet_block_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/problem_lists_screen.dart';
import 'screens/permission_screen.dart';
import 'services/platform_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LeetBlockApp());
}

class LeetBlockApp extends StatelessWidget {
  final LeetBlockProvider? provider;
  final bool autoStartBlockerService;
  final bool Function()? isAndroid;
  final Future<bool> Function()? hasAllPermissions;
  final Future<bool> Function()? startBlockerService;

  const LeetBlockApp({
    super.key,
    this.provider,
    this.autoStartBlockerService = true,
    this.isAndroid,
    this.hasAllPermissions,
    this.startBlockerService,
  });

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'LeetBlock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFA116),
          secondary: Color(0xFFFFA116),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),
      home: AppRouter(
        autoStartBlockerService: autoStartBlockerService,
        isAndroid: isAndroid,
        hasAllPermissions: hasAllPermissions,
        startBlockerService: startBlockerService,
      ),
    );

    if (provider != null) {
      return ChangeNotifierProvider<LeetBlockProvider>.value(
        value: provider!,
        child: app,
      );
    }

    return ChangeNotifierProvider(
      create: (_) => LeetBlockProvider()..init(),
      child: app,
    );
  }
}

class AppRouter extends StatefulWidget {
  final bool autoStartBlockerService;
  final bool Function() isAndroid;
  final Future<bool> Function() hasAllPermissions;
  final Future<bool> Function() startBlockerService;

  AppRouter({
    super.key,
    this.autoStartBlockerService = true,
    bool Function()? isAndroid,
    Future<bool> Function()? hasAllPermissions,
    Future<bool> Function()? startBlockerService,
  }) : isAndroid = isAndroid ?? (() => Platform.isAndroid),
       hasAllPermissions =
           hasAllPermissions ?? PlatformService.hasAllPermissions,
       startBlockerService =
           startBlockerService ?? PlatformService.startBlockerService;

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  static const Duration _autoStartRetryCooldown = Duration(seconds: 30);
  bool _hasPermissions = true; // Default to true for non-Android platforms
  bool _permissionsChecked = false;
  bool _blockerServiceStartQueued = false;
  DateTime? _lastAutoStartFailureAt;
  LeetBlockProvider? _observedProvider;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<LeetBlockProvider>();
    if (_observedProvider == provider) {
      return;
    }

    _observedProvider?.removeListener(_handleProviderChanged);
    _observedProvider = provider;
    _observedProvider?.addListener(_handleProviderChanged);
  }

  @override
  void dispose() {
    _observedProvider?.removeListener(_handleProviderChanged);
    super.dispose();
  }

  void _handleProviderChanged() {
    final provider = _observedProvider;
    if (provider == null || !mounted) {
      return;
    }

    final shouldResetQueue =
        !provider.isSetupComplete || (widget.isAndroid() && !_hasPermissions);
    if (shouldResetQueue && _blockerServiceStartQueued) {
      setState(() {
        _blockerServiceStartQueued = false;
      });
    }
    if (shouldResetQueue) {
      _lastAutoStartFailureAt = null;
    }
  }

  Future<void> _startBlockerServiceSafely() async {
    try {
      final started = await widget.startBlockerService();
      if (started) {
        _lastAutoStartFailureAt = null;
      } else {
        _lastAutoStartFailureAt = DateTime.now();
        if (mounted) {
          setState(() {
            _blockerServiceStartQueued = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to auto-start blocker service: $e');
      _lastAutoStartFailureAt = DateTime.now();
      if (mounted) {
        setState(() {
          _blockerServiceStartQueued = false;
        });
      }
    }
  }

  bool _isInAutoStartCooldown() {
    final lastFailureAt = _lastAutoStartFailureAt;
    if (lastFailureAt == null) {
      return false;
    }
    return DateTime.now().difference(lastFailureAt) < _autoStartRetryCooldown;
  }

  void _ensureBlockerServiceStartQueued() {
    if (_blockerServiceStartQueued || _isInAutoStartCooldown()) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _blockerServiceStartQueued) {
        return;
      }

      setState(() {
        _blockerServiceStartQueued = true;
      });
      unawaited(_startBlockerServiceSafely());
    });
  }

  Future<void> _checkPermissions() async {
    if (widget.isAndroid()) {
      final hasPermissions = await widget.hasAllPermissions();
      if (!mounted) {
        return;
      }
      setState(() {
        _hasPermissions = hasPermissions;
        _permissionsChecked = true;
        if (!hasPermissions) {
          _blockerServiceStartQueued = false;
        }
      });
    } else {
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionsChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        // Show splash while initializing
        if (!_permissionsChecked) {
          return const SplashScreen();
        }

        // Show permission screen if permissions not granted (Android only)
        if (widget.isAndroid() &&
            provider.isSetupComplete &&
            !_hasPermissions) {
          return PermissionScreen(
            onAllPermissionsGranted: () {
              setState(() {
                _hasPermissions = true;
              });
            },
          );
        }

        // Show setup if not complete
        if (!provider.isSetupComplete) {
          return const SetupScreen();
        }

        // Check permissions after setup
        if (widget.isAndroid() && !_hasPermissions) {
          return PermissionScreen(
            onAllPermissionsGranted: () {
              setState(() {
                _hasPermissions = true;
              });
            },
          );
        }

        // Start blocker service once when conditions are met.
        if (widget.isAndroid() &&
            _hasPermissions &&
            widget.autoStartBlockerService &&
            !_blockerServiceStartQueued) {
          _ensureBlockerServiceStartQueued();
        }

        return const MainNavigationShell();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFA116).withOpacity(0.3),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/app_icon/leetblock_logo.png',
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'LeetBlock',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discipline through code',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFA116),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final GlobalKey<ProblemListsScreenState> _problemListsKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      ProblemListsScreen(key: _problemListsKey),
      const StatisticsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.list_alt_rounded,
                  label: 'Lists',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        // Refresh problem lists when switching to Lists tab
        if (index == 1) {
          _problemListsKey.currentState?.refresh();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFFFFA116).withOpacity(0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFFA116) : Colors.white54,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFA116),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
