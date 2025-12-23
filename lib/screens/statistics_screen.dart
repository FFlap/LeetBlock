import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:convert' as java_convert;
import '../providers/leet_block_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = '1W';
  int? _hoverIndex;
  Offset? _hoverPos;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeetBlockProvider>().fetchDetailedStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Consumer<LeetBlockProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchDetailedStats(),
              color: const Color(0xFFFFA116),
              backgroundColor: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),
                    _buildTotalSolvedCard(provider),
                    _buildActivityChart(provider),
                    _buildQuickStats(provider),
                    _buildDifficultyBreakdown(provider),
                    _buildRecentActivity(provider),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(LeetBlockProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Statistics',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (provider.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFFA116),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white54,
                size: 20,
              ),
            ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildTotalSolvedCard(LeetBlockProvider provider) {
    final stats = provider.currentStats;
    final totalSolved = stats?.totalSolved ?? 0;
    final detailedStats = provider.detailedStats;
    final streak = detailedStats?['streak'] ?? provider.currentStreak;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF252525),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total solved · All time',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, 
                      size: 14, color: Color(0xFFFF9800)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak day streak',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$totalSolved',
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          Text(
            'problems',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildActivityChart(LeetBlockProvider provider) {
    final detailedStats = provider.detailedStats;
    if (detailedStats == null) return const SizedBox();

    final (chartData, totalInPeriod, periodLabel) = _getChartData(detailedStats);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$totalInPeriod',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFA116),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        periodLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 24),
          
          // Area Chart
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  final width = constraints.maxWidth;
                  final pointWidth = width / (chartData.length - 1);
                  final index = (details.localPosition.dx / pointWidth).round().clamp(0, chartData.length - 1);
                  setState(() {
                    _hoverIndex = index;
                    _hoverPos = details.localPosition;
                  });
                },
                onPanEnd: (_) => setState(() => _hoverIndex = null),
                onTapDown: (details) {
                  final width = constraints.maxWidth;
                  final pointWidth = width / (chartData.length - 1);
                  final index = (details.localPosition.dx / pointWidth).round().clamp(0, chartData.length - 1);
                  setState(() {
                    _hoverIndex = index;
                    _hoverPos = details.localPosition;
                  });
                },
                onTapUp: (_) => setState(() => _hoverIndex = null),
                onTapCancel: () => setState(() => _hoverIndex = null),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 120),
                        painter: AreaChartPainter(
                          data: chartData,
                          lineColor: const Color(0xFFFFA116),
                          fillColor: const Color(0xFFFFA116).withOpacity(0.2),
                          hoverIndex: _hoverIndex,
                        ),
                      ),
                    ),
                    if (_hoverIndex != null && _hoverIndex! < chartData.length)
                      Positioned(
                        left: (_hoverIndex! * (constraints.maxWidth / (chartData.length - 1)) - 30).clamp(0.0, constraints.maxWidth - 60),
                        top: -40,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${chartData[_hoverIndex!].toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _getTooltipLabel(_hoverIndex!),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _getChartLabels()
                .asMap()
                .entries
                .map((entry) {
              // Highlight today/last label
              final isHighlight = entry.key == _getChartLabels().length - 1;
              return Text(
                entry.value,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isHighlight ? const Color(0xFFFFA116) : Colors.white38,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildPeriodSelector() {
    final periods = ['1D', '1W', '1M', 'YTD', 'MAX'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedPeriod = period;
              _hoverIndex = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFA116) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.white54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStats(LeetBlockProvider provider) {
    final detailedStats = provider.detailedStats;
    final maxStreak = detailedStats?['maxStreak'] ?? 0;
    final activeDays = detailedStats?['totalActiveDays'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStatCard(
              'Best Streak',
              '$maxStreak',
              'days',
              const Color(0xFFFF9800),
              Icons.emoji_events_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              'Active Days',
              '$activeDays',
              'total',
              const Color(0xFF4CAF50),
              Icons.calendar_month_rounded,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildQuickStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBreakdown(LeetBlockProvider provider) {
    final stats = provider.currentStats;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difficulty Breakdown',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildDifficultyRow(
            'Easy',
            stats?.easySolved ?? 0,
            830,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          _buildDifficultyRow(
            'Medium',
            stats?.mediumSolved ?? 0,
            1740,
            const Color(0xFFFF9800),
          ),
          const SizedBox(height: 16),
          _buildDifficultyRow(
            'Hard',
            stats?.hardSolved ?? 0,
            801,
            const Color(0xFFF44336),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildDifficultyRow(String label, int solved, int total, Color color) {
    final percentage = (solved / total).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '$solved',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  ' / $total',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(LeetBlockProvider provider) {
    final recentProblems = provider.detailedStats?['recentProblems'] 
        as List<Map<String, dynamic>>? ?? [];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${recentProblems.length} solved',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          if (recentProblems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 32,
                        color: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentProblems.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final problem = entry.value;
              final title = problem['title'] ?? 'Unknown Problem';
              final timestamp = problem['timestamp'] as int? ?? 0;
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
              final timeAgo = _getTimeAgo(date);
              final isLast = index == math.min(4, recentProblems.length - 1);

              return InkWell(
                onTap: () => _showSubmissionDetails(context, problem, timeAgo),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeAgo,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 20,
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
                ),
              );
            }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  void _showSubmissionDetails(BuildContext context, Map<String, dynamic> problem, String timeAgo) {
    showDialog(
      context: context,
      builder: (context) => _SubmissionDetailsDialog(
        problem: problem,
        timeAgo: timeAgo,
      ),
    );
  }





  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  (List<double>, int, String) _getChartData(Map<String, dynamic> stats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_selectedPeriod == '1D') {
      // Hourly breakdown for today
      final recentProblems = stats['recentProblems'] as List<Map<String, dynamic>>? ?? [];
      final hourlyData = List<double>.filled(24, 0);
      int total = 0;

      for (var problem in recentProblems) {
        final timestamp = problem['timestamp'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        
        if (date.year == today.year && 
            date.month == today.month && 
            date.day == today.day) {
          hourlyData[date.hour]++;
          total++;
        }
      }
      return (hourlyData, total, 'today');
    }

    // Parse submission calendar for other periods
    final calendarJson = stats['submissionCalendar'];
    Map<int, int> calendar = {};
    if (calendarJson is String) {
      try {
        final Map<String, dynamic> decoded = 
            Map<String, dynamic>.from(const java_convert.JsonDecoder().convert(calendarJson)); // Use standard jsonDecode if import available, else fix imports
        decoded.forEach((k, v) {
          calendar[int.parse(k)] = v as int;
        });
      } catch (e) {
        print('Error parsing calendar: $e');
      }
    }

    // Fix 1D Total: Use submissionCalendar for accurate daily total
    if (_selectedPeriod == '1D') {
      // Re-calculate total from calendar for today
      int calendarTotal = 0;
      calendar.forEach((ts, count) {
        final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        if (date.year == today.year && 
            date.month == today.month && 
            date.day == today.day) {
          calendarTotal += count;
        }
      });
      
      // If calendar has data, use it. Otherwise fallback to recentProblems loop (which might be limited to 50)
      // Actually, let's trust calendar if it has today's data.
      // But we still need hourlyData from recentProblems.
      // So we just update the 'total' returned.
      
      // Hourly breakdown for today (re-run logic or reuse from above block if refactored, but here we just update total)
      final recentProblems = stats['recentProblems'] as List<Map<String, dynamic>>? ?? [];
      final hourlyData = List<double>.filled(24, 0);
      
      for (var problem in recentProblems) {
        final timestamp = problem['timestamp'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        
        if (date.year == today.year && 
            date.month == today.month && 
            date.day == today.day) {
          hourlyData[date.hour]++;
        }
      }
      
      return (hourlyData, calendarTotal > 0 ? calendarTotal : 0, 'today'); // Use calendarTotal
    }

    List<double> data = [];
    int total = 0;
    String label = '';

    if (_selectedPeriod == '1W') {
      // Last 7 days
      data = List<double>.filled(7, 0);
      for (int i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        // Find timestamp for this day (approximate match as calendar keys are timestamps)
        // Actually, calendar keys are unix timestamps. We need to sum up counts for that day.
        // Optimization: Convert calendar keys to DateTimes once.
        
        // Simpler approach: Iterate calendar and bucket
        // But for 1W we want specific 7 bars.
        
        // Let's iterate through the calendar and add to buckets
        calendar.forEach((ts, count) {
          final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          final diff = today.difference(DateTime(date.year, date.month, date.day)).inDays;
          if (diff >= 0 && diff < 7) {
            data[6 - diff] += count.toDouble();
            total += count;
          }
        });
      }
      label = 'this week';
    } else if (_selectedPeriod == '1M') {
      // Last 30 days
      data = List<double>.filled(30, 0);
      calendar.forEach((ts, count) {
        final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        final diff = today.difference(DateTime(date.year, date.month, date.day)).inDays;
        if (diff >= 0 && diff < 30) {
          data[29 - diff] += count.toDouble();
          total += count;
        }
      });
      label = 'this month';
    } else if (_selectedPeriod == 'YTD') {
      // From Jan 1st to now
      final startOfYear = DateTime(now.year, 1, 1);
      final daysInYear = today.difference(startOfYear).inDays + 1;
      // Use fewer points for smoothing, e.g., weeks or months?
      // For AreaChart, too many points might be messy. Let's do weekly buckets for YTD.
      final weeks = (daysInYear / 7).ceil();
      data = List<double>.filled(weeks, 0);
      
      calendar.forEach((ts, count) {
        final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        if (date.year == now.year) {
          final diffDays = date.difference(startOfYear).inDays;
          final weekIndex = (diffDays / 7).floor();
          if (weekIndex < weeks) {
            data[weekIndex] += count.toDouble();
            total += count;
          }
        }
      });
      label = 'this year';
    } else if (_selectedPeriod == 'MAX') {
      // All time, monthly buckets
      if (calendar.isEmpty) {
        data = [0.0];
      } else {
        final timestamps = calendar.keys.toList()..sort();
        final firstTs = timestamps.first;
        final firstDate = DateTime.fromMillisecondsSinceEpoch(firstTs * 1000);
        final startMonth = DateTime(firstDate.year, firstDate.month);
        
        final monthsDiff = (now.year - startMonth.year) * 12 + now.month - startMonth.month + 1;
        data = List<double>.filled(monthsDiff, 0);
        
        calendar.forEach((ts, count) {
          final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          final monthIndex = (date.year - startMonth.year) * 12 + date.month - startMonth.month;
          if (monthIndex >= 0 && monthIndex < monthsDiff) {
            data[monthIndex] += count.toDouble();
            total += count;
          }
        });
      }
      label = 'all time';
    }

    return (data, total, label);
  }

  List<String> _getChartLabels() {
    if (_selectedPeriod == '1D') {
      return ['00', '04', '08', '12', '16', '20', '23'];
    } else if (_selectedPeriod == '1W') {
      final now = DateTime.now();
      return List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      });
    } else if (_selectedPeriod == '1M') {
      return ['30d', '20d', '10d', 'Today'];
    } else if (_selectedPeriod == 'YTD') {
      return ['Jan', 'Apr', 'Jul', 'Oct', 'Now'];
    } else {
      return ['Start', 'Now'];
    }
  }

  String _getTooltipLabel(int index) {
    if (_selectedPeriod == '1D') {
      return '${index.toString().padLeft(2, '0')}:00';
    } else if (_selectedPeriod == '1W') {
      final now = DateTime.now();
      final date = now.subtract(Duration(days: 6 - index));
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    } else if (_selectedPeriod == '1M') {
      return '${30 - index} days ago';
    } else if (_selectedPeriod == 'YTD') {
      return 'Week $index';
    } else {
      return 'Month $index';
    }
  }
}

// Custom Area Chart Painter
class AreaChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  final int? hoverIndex;

  AreaChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    this.hoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final normalizedData = maxValue > 0 
        ? data.map((v) => v / maxValue).toList()
        : data.map((v) => 0.0).toList();

    final path = Path();
    final fillPath = Path();
    final pointSpacing = size.width / (data.length - 1);

    // Start fill path at bottom left
    fillPath.moveTo(0, size.height);

    for (int i = 0; i < normalizedData.length; i++) {
      final x = i * pointSpacing;
      final y = size.height - (normalizedData[i] * size.height * 0.8) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        // Smooth curve
        final prevX = (i - 1) * pointSpacing;
        final prevY = size.height - (normalizedData[i - 1] * size.height * 0.8) - 10;
        final controlX1 = prevX + (x - prevX) / 2;
        final controlX2 = prevX + (x - prevX) / 2;

        path.cubicTo(controlX1, prevY, controlX2, y, x, y);
        fillPath.cubicTo(controlX1, prevY, controlX2, y, x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor, fillColor.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw dots at data points
    final dotPaint = Paint()..color = lineColor;
    for (int i = 0; i < normalizedData.length; i++) {
      if (data[i] > 0) {
        final x = i * pointSpacing;
        final y = size.height - (normalizedData[i] * size.height * 0.8) - 10;
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
        canvas.drawCircle(
          Offset(x, y), 
          2, 
          Paint()..color = const Color(0xFF1E1E1E),
        );
      }
    }

    // Draw hover indicator
    if (hoverIndex != null && hoverIndex! < normalizedData.length) {
      final i = hoverIndex!;
      final x = i * pointSpacing;
      final y = size.height - (normalizedData[i] * size.height * 0.8) - 10;

      // Vertical line
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );

      // Highlight dot
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = lineColor);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFF1E1E1E));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SubmissionDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> problem;
  final String timeAgo;

  const _SubmissionDetailsDialog({
    required this.problem,
    required this.timeAgo,
  });

  @override
  State<_SubmissionDetailsDialog> createState() => _SubmissionDetailsDialogState();
}

class _SubmissionDetailsDialogState extends State<_SubmissionDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      title: Text(
        widget.problem['title'] ?? 'Submission Details',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Language', widget.problem['lang'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Runtime', widget.problem['runtime'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Memory', widget.problem['memory'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Time', widget.timeAgo),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: GoogleFonts.inter(
              color: const Color(0xFFFFA116),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
