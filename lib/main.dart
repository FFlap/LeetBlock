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
  const LeetBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeetBlockProvider()..init(),
      child: MaterialApp(
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
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF121212),
            elevation: 0,
          ),
        ),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _hasPermissions = true; // Default to true for non-Android platforms
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final hasPermissions = await PlatformService.hasAllPermissions();
      setState(() {
        _hasPermissions = hasPermissions;
        _permissionsChecked = true;
      });
    } else {
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
        if (Platform.isAndroid && provider.isSetupComplete && !_hasPermissions) {
          return PermissionScreen(
            onAllPermissionsGranted: () {
              setState(() => _hasPermissions = true);
            },
          );
        }

        // Show setup if not complete
        if (!provider.isSetupComplete) {
          return const SetupScreen();
        }

        // Check permissions after setup
        if (Platform.isAndroid && !_hasPermissions) {
          return PermissionScreen(
            onAllPermissionsGranted: () {
              setState(() => _hasPermissions = true);
            },
          );
        }

        // Start blocker service if on Android with permissions
        if (Platform.isAndroid && _hasPermissions) {
          PlatformService.startBlockerService();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1117),
              Color(0xFF161B22),
              Color(0xFF0D1117),
            ],
          ),
        ),
        child: Center(
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA116).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFA116).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.code,
                          color: Color(0xFFFFA116),
                          size: 64,
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
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
          color: isSelected 
              ? const Color(0xFFFFA116).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? const Color(0xFFFFA116)
                  : Colors.white54,
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
