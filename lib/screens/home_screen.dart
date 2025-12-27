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
              Text(
                provider.username,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              Row(
                children: [
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
            color: const Color(0xFF1E1E1E),
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
                          fontSize: 16,
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
                  backgroundColor: const Color(0xFF2A2A2A),
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
        final totalSolved = stats?.totalSolved ?? 0;
        
        // Use 0 as fallback if data is not available, avoiding hardcoded magic numbers
        final totalEasy = stats?.totalEasy ?? 0;
        final totalMedium = stats?.totalMedium ?? 0;
        final totalHard = stats?.totalHard ?? 0;
        
        final totalQuestions = totalEasy + totalMedium + totalHard;
        
        final easySolved = stats?.easySolved ?? 0;
        final mediumSolved = stats?.mediumSolved ?? 0;
        final hardSolved = stats?.hardSolved ?? 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  // Circular Progress Ring
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _StatsRingPainter(
                        easySolved: easySolved,
                        mediumSolved: mediumSolved,
                        hardSolved: hardSolved,
                        totalEasy: totalEasy,
                        totalMedium: totalMedium,
                        totalHard: totalHard,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$totalSolved',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/$totalQuestions',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check, color: Color(0xFF4CAF50), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Solved',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Difficulty Breakdown Boxes
                  Expanded(
                    child: Column(
                      children: [
                        _buildDifficultyBox('Easy', easySolved, totalEasy, const Color(0xFF4CAF50)),
                        const SizedBox(height: 8),
                        _buildDifficultyBox('Med.', mediumSolved, totalMedium, const Color(0xFFFF9800)),
                        const SizedBox(height: 8),
                        _buildDifficultyBox('Hard', hardSolved, totalHard, const Color(0xFFF44336)),
                      ],
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

  Widget _buildDifficultyBox(String label, int solved, int total, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            '$solved/$total',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
                              '${_formatBlockedTime(provider.totalBlockedTime)} today',
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

  /// Formats duration in ms to "Xh Ym" or "Xm"
  String _formatBlockedTime(int ms) {
    final totalMins = (ms / 1000 / 60).round();
    if (totalMins >= 60) {
      final hours = totalMins ~/ 60;
      final mins = totalMins % 60;
      return "${hours}h ${mins}m";
    }
    return "${totalMins}m";
  }
}

// Custom Painter for the stats ring
class _StatsRingPainter extends CustomPainter {
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int totalEasy;
  final int totalMedium;
  final int totalHard;

  _StatsRingPainter({
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.totalEasy,
    required this.totalMedium,
    required this.totalHard,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 8.0;

    // Horseshoe configuration
    // Start at 135 degrees (bottom-left)
    const startAngle = 135 * math.pi / 180;
    // Sweep 270 degrees total
    const fullSweep = 270 * math.pi / 180;
    
    // Calculate gap size in radians
    // Reduce gap significantly
    final capAngle = strokeWidth / radius; 
    // Small visual gap (approx 2 degrees)
    final visualGap = 2 * math.pi / 180; 
    final gapSize = visualGap + capAngle; 

    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Calculate proportions
    final totalAll = totalEasy + totalMedium + totalHard;
    if (totalAll == 0) return;

    final easyRatio = totalEasy / totalAll;
    final mediumRatio = totalMedium / totalAll;
    final hardRatio = totalHard / totalAll;
    
    // Total available sweep for the actual arcs (subtracting gaps)
    // 2 gaps total (between 3 segments)
    final availableSweep = fullSweep - (gapSize * 2);
    
    // Sweep angles for segments
    final easySweep = easyRatio * availableSweep;
    final mediumSweep = mediumRatio * availableSweep;
    final hardSweep = hardRatio * availableSweep;
    
    double currentAngle = startAngle;
    
    // --- EASY SEGMENT (Green) ---
    paint.color = const Color(0xFF1B3320);
    canvas.drawArc(rect, currentAngle, easySweep, false, paint);
    
    if (totalEasy > 0) {
      final easyProgressRatio = (easySolved / totalEasy).clamp(0.0, 1.0);
      paint.color = const Color(0xFF4CAF50);
      if (easyProgressRatio > 0.01) {
         canvas.drawArc(rect, currentAngle, easySweep * easyProgressRatio, false, paint);
      }
    }
    currentAngle += easySweep + gapSize;
    
    // --- MEDIUM SEGMENT (Orange) ---
    paint.color = const Color(0xFF332B1B);
    canvas.drawArc(rect, currentAngle, mediumSweep, false, paint);
    
    if (totalMedium > 0) {
      final mediumProgressRatio = (mediumSolved / totalMedium).clamp(0.0, 1.0);
      paint.color = const Color(0xFFFF9800);
      if (mediumProgressRatio > 0.01) {
        canvas.drawArc(rect, currentAngle, mediumSweep * mediumProgressRatio, false, paint);
      }
    }
    currentAngle += mediumSweep + gapSize;
    
    // --- HARD SEGMENT (Red) ---
    paint.color = const Color(0xFF331B1B);
    canvas.drawArc(rect, currentAngle, hardSweep, false, paint);
    
    if (totalHard > 0) {
       final hardProgressRatio = (hardSolved / totalHard).clamp(0.0, 1.0);
       paint.color = const Color(0xFFF44336);
       if (hardProgressRatio > 0.01) {
         canvas.drawArc(rect, currentAngle, hardSweep * hardProgressRatio, false, paint);
       }
    }
  }

  @override
  bool shouldRepaint(covariant _StatsRingPainter oldDelegate) {
    return easySolved != oldDelegate.easySolved ||
           mediumSolved != oldDelegate.mediumSolved ||
           hardSolved != oldDelegate.hardSolved ||
           totalEasy != oldDelegate.totalEasy ||
           totalMedium != oldDelegate.totalMedium ||
           totalHard != oldDelegate.totalHard;
  }
}
