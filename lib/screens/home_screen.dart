import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../providers/leet_block_provider.dart';
import '../services/platform_service.dart';
import 'app_selection_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeetBlockProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<LeetBlockProvider>().fetchStats();
          },
          color: const Color(0xFFFFA116),
          backgroundColor: const Color(0xFF1E1E1E),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildProgressCard(),
                _buildQuickStats(),
                _buildBlockedAppsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.username,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (provider.isLoading)
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(10),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFA116),
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn();
      },
    );
  }

  Widget _buildProgressCard() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        final progress = provider.questionsCompletedToday / provider.effectiveQuota;
        final isComplete = provider.isQuotaMet;
        final penalty = provider.quotaPenalty;
        
        // Calculate split progress
        final baseQuota = provider.dailyQuota;
        final totalCompleted = provider.questionsCompletedToday;
        final baseCompleted = totalCompleted.clamp(0, baseQuota);
        final penaltyCompleted = (totalCompleted - baseQuota).clamp(0, penalty);

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2620), // Dark brownish/grey background from image
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Progress',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isComplete
                            ? 'All apps unlocked'
                            : '${provider.questionsRemaining} more to unlock apps',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: penalty > 0
                        ? RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: '$baseCompleted/$baseQuota + '),
                                TextSpan(
                                  text: '$penaltyCompleted/$penalty',
                                  style: const TextStyle(color: Color(0xFFFF6B6B)),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            '$totalCompleted/$baseQuota',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),

              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF1E1E1E),
                  color: const Color(0xFFFFA116),
                  minHeight: 12,
                ),
              ),



              const SizedBox(height: 24),
              
              // Action Buttons
              _buildActionButton(
                icon: Icons.code_rounded,
                label: 'Go to LeetCode',
                onTap: () => PlatformService.openLeetCode(),
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.refresh_rounded,
                label: 'Refresh Progress',
                onTap: () => provider.fetchStats(),
                isPrimary: false,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFFFA116) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isPrimary ? null : Border.all(color: const Color(0xFFFFA116)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 18,
                color: isPrimary ? const Color(0xFF121212) : const Color(0xFFFFA116),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? const Color(0xFF121212) : const Color(0xFFFFA116),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        final stats = provider.currentStats;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Stats',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      '${stats?.totalSolved ?? 0}',
                      const Color(0xFFFFA116),
                      Icons.emoji_events_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Easy',
                      '${stats?.easySolved ?? 0}',
                      const Color(0xFF4CAF50),
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Medium',
                      '${stats?.mediumSolved ?? 0}',
                      const Color(0xFFFF9800),
                      Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Hard',
                      '${stats?.hardSolved ?? 0}',
                      const Color(0xFFF44336),
                      Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms);
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      height: 110, // Fixed height for consistency
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Icon top-left
          Align(
            alignment: Alignment.topLeft,
            child: Icon(icon, color: color, size: 20),
          ),
          
          // Label Pill top-right
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),

          // Value bottom-left
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsSection() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        final blockedApps = provider.blockedApps;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blocked Apps',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white54,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(provider.totalBlockedTime / 1000 / 60).round()}m today',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppSelectionScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFA116),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (blockedApps.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.apps_rounded,
                          size: 32,
                          color: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No apps blocked',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap Edit to add apps',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ...blockedApps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final app = entry.value;
                      final isLast = index == blockedApps.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                if (app.icon != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      app.icon!,
                                      width: 40,
                                      height: 40,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF252525),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.android, color: Colors.white38),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    app.appName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: provider.isQuotaMet
                                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                                        : const Color(0xFFF44336).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        provider.isQuotaMet ? Icons.lock_open : Icons.lock,
                                        size: 12,
                                        color: provider.isQuotaMet
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFF44336),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        provider.isQuotaMet ? 'Open' : 'Blocked',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: provider.isQuotaMet
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFF44336),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.05),
                              indent: 72,
                              endIndent: 20,
                            ),
                        ],
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                  ],
                ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }
}


