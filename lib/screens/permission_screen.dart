import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/platform_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onAllPermissionsGranted;

  const PermissionScreen({
    super.key,
    required this.onAllPermissionsGranted,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _hasUsageStatsPermission = false;
  bool _hasOverlayPermission = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    _hasUsageStatsPermission = await PlatformService.hasUsageStatsPermission();
    _hasOverlayPermission = await PlatformService.hasOverlayPermission();

    setState(() => _isChecking = false);

    if (_hasUsageStatsPermission && _hasOverlayPermission) {
      // Start the blocker service
      await PlatformService.startBlockerService();
      widget.onAllPermissionsGranted();
    }
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildPermissionCard(
                  title: 'Usage Access',
                  description:
                      'Required to detect when you open blocked apps',
                  icon: Icons.analytics_outlined,
                  isGranted: _hasUsageStatsPermission,
                  onRequest: () async {
                    await PlatformService.requestUsageStatsPermission();
                  },
                ),
                const SizedBox(height: 16),
                _buildPermissionCard(
                  title: 'Display Over Apps',
                  description:
                      'Required to show the blocking screen when you open a blocked app',
                  icon: Icons.layers_outlined,
                  isGranted: _hasOverlayPermission,
                  onRequest: () async {
                    await PlatformService.requestOverlayPermission();
                  },
                ),
                const Spacer(),
                _buildRefreshButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA116).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFA116).withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.security,
                color: Color(0xFFFFA116),
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Permissions Required',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'LeetBlock needs these permissions to block apps effectively. Your data stays on your device.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF238636).withOpacity(0.5)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF238636).withOpacity(0.15)
                  : const Color(0xFFFFA116).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: isGranted
                  ? const Color(0xFF238636)
                  : const Color(0xFFFFA116),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isGranted)
            TextButton(
              onPressed: onRequest,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFA116).withOpacity(0.1),
                foregroundColor: const Color(0xFFFFA116),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Grant',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF238636).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Granted',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF238636),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isChecking ? null : _checkPermissions,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFA116),
          side: const BorderSide(color: Color(0xFFFFA116)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isChecking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFFA116),
                ),
              )
            : const Icon(Icons.refresh),
        label: Text(
          _isChecking ? 'Checking...' : 'Check Permissions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

