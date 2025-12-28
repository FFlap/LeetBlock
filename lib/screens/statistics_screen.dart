import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:convert' as java_convert;
import 'dart:io';
import '../providers/leet_block_provider.dart';
import '../models/app_info.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Screen Time State
  String _screenTimePeriod = '1W'; // '1W' or '1M'
  int? _hoveredBarIndex;
  int _screenTimePageOffset = 0; // 0 = current week/month, 1 = previous, etc.
  DateTime _selectedDate = DateTime.now(); // Default to today
  
  // LeetCode Chart State
  String _leetcodeChartPeriod = '1W';
  int? _leetcodeHoverIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Strip time for clean daily comparison
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeetBlockProvider>().fetchDetailedStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<LeetBlockProvider>(
                builder: (context, provider, _) {
                  return TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // PERSONAL STATS TAB (Default)
                      RefreshIndicator(
                        onRefresh: () => provider.fetchDetailedStats(),
                        color: const Color(0xFFFFA116),
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWeeklyRequirements(provider),
                              const SizedBox(height: 24),
                              _buildScreenTimeGraph(provider),
                              const SizedBox(height: 24),
                              _buildAppUsageList(provider),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      
                      // LEETCODE STATS TAB
                      RefreshIndicator(
                        onRefresh: () => provider.fetchDetailedStats(),
                        color: const Color(0xFFFFA116),
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTotalSolvedCard(provider),
                              const SizedBox(height: 24),
                              _buildLeetCodeActivityChart(provider),
                              const SizedBox(height: 24),
                              _buildDifficultyBreakdown(provider),
                              const SizedBox(height: 24),
                              _buildRecentActivity(provider, context),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistics',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFFFA116),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Personal'),
          Tab(text: 'LeetCode'),
        ],
      ),
    );
  }

  // --- PERSONAL TAB WIDGETS ---

  Widget _buildWeeklyRequirements(LeetBlockProvider provider) {
    // Generate dates for the last 7 days (ending today)
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
    
    final history = provider.completionHistory;
    final todayKey = _dateKey(DateTime.now());
    
    int completedCount = 0;
    for (var date in dates) {
      final key = _dateKey(date);
      // For today, use the live isQuotaMet value
      final isComplete = (key == todayKey) ? provider.isBaseQuotaMet : (history[key] == true);
      if (isComplete) completedCount++;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
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
                'Weekly Goal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA116).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount/7 completed',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFA116),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dates.map((date) {
              final key = _dateKey(date);
              final isToday = _dateKey(DateTime.now()) == key;
              // For today, use the live isBaseQuotaMet value (base quota only, ignoring penalty)
              final isCompleted = isToday ? provider.isBaseQuotaMet : (history[key] == true);
              final dayLabel = _dayLabel(date);
              
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? const Color(0xFFFFA116) : Colors.transparent,
                      border: Border.all(
                        color: isCompleted 
                            ? const Color(0xFFFFA116) 
                            : isToday ? Colors.white38 : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    child: isCompleted 
                        ? const Icon(Icons.check, size: 20, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isToday ? Colors.white : Colors.white24,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildScreenTimeGraph(LeetBlockProvider provider) {
    final now = DateTime.now();
    final isWeek = _screenTimePeriod == '1W';
    final daysPerPeriod = isWeek ? 7 : 30;
    
    // Calculate start date based on offset
    final endDate = now.subtract(Duration(days: _screenTimePeriod == '1W' ? _screenTimePageOffset * 7 : _screenTimePageOffset * 30));
    
    // Generate dates for current view (left to right)
    final dates = List.generate(daysPerPeriod, (index) => endDate.subtract(Duration(days: daysPerPeriod - 1 - index)));
    
    final history = provider.screenTimeHistory;
    final data = dates.map((date) {
      final key = _dateKey(date);
      return (history[key] ?? 0).toDouble();
    }).toList();
    
    // Inject today's live value if relevant
    if (_screenTimePageOffset == 0 && provider.totalBlockedTime > 0) {
        final todayKey = _dateKey(now);
        for (int i=0; i<dates.length; i++) {
          if (_dateKey(dates[i]) == todayKey) {
             if (history[todayKey] == null || provider.totalBlockedTime > history[todayKey]!) {
                data[i] = provider.totalBlockedTime.toDouble();
             }
             break;
          }
        }
    }

    double maxVal = data.reduce(math.max);
    if (maxVal == 0) maxVal = 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blocked App Usage',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Swipeable Chart Area
          GestureDetector(
             behavior: HitTestBehavior.opaque,
             onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // Swipe Right -> View Previous Period
                  setState(() {
                    _screenTimePageOffset++; 
                    _hoveredBarIndex = null;
                  });
                } else if (details.primaryVelocity! < 0) {
                  // Swipe Left -> View Next Period
                  if (_screenTimePageOffset > 0) {
                    setState(() {
                       _screenTimePageOffset--;
                       _hoveredBarIndex = null;
                    });
                  }
                }
             },
             child: Column(
               children: [
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(data.length, (index) {
                        final value = data[index];
                        final heightFactor = value / maxVal;
                        final date = dates[index];
                        // For monthly view, only show the date range at the bottom (no per-bar labels)
                        final label = isWeek ? _dayLabel(date) : "";
                        
                        // Check if this date is currently selected
                        final isSelected = _dateKey(date) == _dateKey(_selectedDate);
                        final isHovered = _hoveredBarIndex == index;
                        
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setState(() {
                                 // Strip time for clean daily comparison
                                _selectedDate = DateTime(date.year, date.month, date.day);
                              });
                            },
                            onTapDown: (_) => setState(() => _hoveredBarIndex = index),
                            onTapUp: (_) => setState(() => _hoveredBarIndex = null),
                            onTapCancel: () => setState(() => _hoveredBarIndex = null),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                 // Tooltip - show for selected or hovered bars
                                if (isHovered || isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF333333),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _formatDuration(value.toInt()),
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                  
                                Container(
                                  height: math.max(4, 100 * heightFactor),
                                  margin: EdgeInsets.symmetric(horizontal: isWeek ? 8 : 1),
                                  decoration: BoxDecoration(
                                    color: (isHovered || isSelected) 
                                        ? const Color(0xFFFFA116)
                                        : const Color(0xFFFFA116).withOpacity(0.5 + (heightFactor * 0.5)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white : Colors.white38,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Paging Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_screenTimePageOffset > 0)
                        const Icon(Icons.chevron_left, size: 16, color: Colors.white38)
                      else 
                        const SizedBox(width: 16),
                        
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _getDateRangeLabel(dates.first, dates.last),
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                        ),
                      ),
                      
                      if (_screenTimePageOffset > 0) 
                         const Icon(Icons.chevron_right, size: 16, color: Colors.white38)
                      else
                         const SizedBox(width: 16),
                    ],
                  ),
               ],
             ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildAppUsageList(LeetBlockProvider provider) {
     final dateKey = _dateKey(_selectedDate);
     final history = provider.appUsageHistory;
     
     // Get apps for the selected date
     Map<String, int> appsForDate = history[dateKey] ?? {};
     
     // If selected date is today, merge/override with latest from provider.allApps if we had granular tracking there?
     // Actually appUsageHistory IS the breakdown source. 
     // BUT, provider.appUsageHistory comes from StorageService, which reads from Prefs.
     // AppBlockerService writes to Prefs.
     // So on refresh, we get the latest.
     // However, provider.appUsageHistory might be stale if we didn't call fetchDetailedStats (which reloads storage).
     // The refreshIndicator does call it.
     
     if (appsForDate.isEmpty) {
        return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                "No usage data for $_dateKeyDisplay",
                style: GoogleFonts.inter(color: Colors.white38),
              ),
            ),
        ).animate().fadeIn(delay: 250.ms);
     }
     int totalMs = 0;
     appsForDate.forEach((_, time) => totalMs += time);
     final totalTimeStr = _formatDuration(totalMs);
     
     // Convert to list for sorting
     final List<MapEntry<String, int>> sortedApps = appsForDate.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // Descending time
        
     return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
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
                        "Usage by App",
                        style: GoogleFonts.inter(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600, 
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateKeyDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    totalTimeStr,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFA116),
                    ),
                  ),
               ],
             ),
             const SizedBox(height: 16),
              ...sortedApps.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                final pkg = entry.key;
                final durationMs = entry.value;
                final durationStr = _formatDuration(durationMs);
                final isLast = index == sortedApps.length - 1;
                
                // Find app info if available
                final appInfo = provider.allApps.firstWhere(
                   (a) => a.packageName == pkg, 
                   orElse: () => BlockedAppInfo(packageName: pkg, appName: pkg, isBlocked: true),
                );
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                           Container(
                             width: 40,
                             height: 40,
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(10),
                               image: appInfo.icon != null 
                                  ? DecorationImage(
                                      image: MemoryImage(appInfo.icon!), 
                                      fit: BoxFit.cover
                                    ) 
                                  : null,
                             ),
                             child: appInfo.icon == null 
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF252525),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.android, size: 20, color: Colors.white38),
                                  )
                                : null,
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Text(
                               appInfo.appName,
                               style: GoogleFonts.inter(
                                 color: Colors.white,
                                 fontWeight: FontWeight.w500,
                                 fontSize: 14,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           Text(
                             durationStr,
                             style: GoogleFonts.inter(
                               color: const Color(0xFFFFA116),
                               fontWeight: FontWeight.w600,
                               fontSize: 14,
                             ),
                           ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.05),
                        indent: 52,
                      ),
                  ],
                );
             }),
           ],
        ),
     ).animate().fadeIn(delay: 250.ms);
  }
  
  String get _dateKeyDisplay {
     final now = DateTime.now();
     if (_selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day) {
       return "Today";
     }
     if (_selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day - 1) {
       return "Yesterday";
     }
     return DateFormat('MMM d').format(_selectedDate);
  }
  
  String _getDateRangeLabel(DateTime start, DateTime end) {
    return "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}";
  }

  Widget _periodButton(String period) {
    final isSelected = _screenTimePeriod == period;
    return GestureDetector(
      onTap: () => setState(() {
        _screenTimePeriod = period;
        _screenTimePageOffset = 0; // Reset offset on mode switch
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA116) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
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
  }

  // --- LEETCODE TAB WIDGETS ---

  Widget _buildTotalSolvedCard(LeetBlockProvider provider) {
    final stats = provider.currentStats;
    final totalSolved = stats?.totalSolved ?? 0;
    final streak = provider.currentStreak;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Problems Solved',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalSolved',
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFA116), size: 24),
                const SizedBox(height: 4),
                Text(
                  '$streak',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Streak',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildLeetCodeActivityChart(LeetBlockProvider provider) {
    final detailedStats = provider.detailedStats;
    if (detailedStats == null) return const SizedBox();

    final (chartData, totalInPeriod, periodLabel) = _getLeetCodeChartData(detailedStats, _leetcodeChartPeriod);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
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
                    'Submissions',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Text(
                    '$totalInPeriod $periodLabel',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
              // Period selector for LeetCode chart
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _leetcodePeriodButton('1W'),
                    const SizedBox(width: 4),
                    _leetcodePeriodButton('1M'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine point width
                final pointWidth = constraints.maxWidth / (chartData.length - 1);
                
                return GestureDetector(
                   onPanUpdate: (details) {
                     final index = (details.localPosition.dx / pointWidth).round().clamp(0, chartData.length - 1);
                     setState(() => _leetcodeHoverIndex = index);
                   },
                   onPanEnd: (_) => setState(() => _leetcodeHoverIndex = null),
                   onTapDown: (details) {
                     final index = (details.localPosition.dx / pointWidth).round().clamp(0, chartData.length - 1);
                     setState(() => _leetcodeHoverIndex = index);
                   },
                   onTapUp: (_) => setState(() => _leetcodeHoverIndex = null),
                   
                   child: Stack(
                     clipBehavior: Clip.none,
                     children: [
                       CustomPaint(
                         size: Size(constraints.maxWidth, 120),
                         painter: AreaChartPainter(
                           data: chartData,
                           lineColor: const Color(0xFFFFA116),
                           fillColor: const Color(0xFFFFA116).withOpacity(0.2),
                           hoverIndex: _leetcodeHoverIndex,
                         ),
                       ),
                       // Tooltip overlay - positioned at data point level
                       if (_leetcodeHoverIndex != null && _leetcodeHoverIndex! < chartData.length)
                         Builder(
                           builder: (context) {
                             final value = chartData[_leetcodeHoverIndex!];
                             final maxVal = chartData.reduce(math.max);
                             final normalizedY = maxVal > 0 ? (1 - value / maxVal) * 100 : 100.0;
                             
                             // Calculate date for this index
                             final daysAgo = chartData.length - 1 - _leetcodeHoverIndex!;
                             final date = DateTime.now().subtract(Duration(days: daysAgo));
                             final dateStr = '${date.month}/${date.day}';
                             
                             return Positioned(
                               left: (_leetcodeHoverIndex! * pointWidth - 35).clamp(0.0, constraints.maxWidth - 70),
                               top: (normalizedY - 25).clamp(0.0, 95.0),
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: const Color(0xFF333333),
                                   borderRadius: BorderRadius.circular(6),
                                 ),
                                 child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Text(
                                       '${value.toInt()} submissions',
                                       style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                                     ),
                                     Text(
                                       dateStr,
                                       style: GoogleFonts.inter(fontSize: 9, color: Colors.white54),
                                     ),
                                   ],
                                 ),
                               ),
                             );
                           },
                         ),
                     ],
                   ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _leetcodePeriodButton(String period) {
    final isSelected = _leetcodeChartPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _leetcodeChartPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA116) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
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
  }

  (List<double>, int, String) _getLeetCodeChartData(Map<String, dynamic> stats, String period) {
     final now = DateTime.now();
     final today = DateTime(now.year, now.month, now.day);
     
     // Parse calendar
     final calendarJson = stats['submissionCalendar'];
     Map<int, int> calendar = {};
     if (calendarJson is String) {
       try {
         final Map<String, dynamic> decoded = Map<String, dynamic>.from(java_convert.jsonDecode(calendarJson));
         decoded.forEach((k, v) => calendar[int.parse(k)] = v as int);
       } catch (e) {
         print("Error parsing calendar: $e");
       }
     }

     List<double> data = [];
     int total = 0;
     String label = '';

     if (period == '1W') {
        data = List.filled(7, 0.0);
        for(int i=6; i>=0; i--) {
           final day = today.subtract(Duration(days: i));
           // Sum for this day
           calendar.forEach((ts, count) {
              final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              if (date.year == day.year && date.month == day.month && date.day == day.day) {
                 data[6-i] += count; // Using i here means rightmost is i=0 (today). index logic: 6-i
                 total += count;
              }
           });
        }
        label = 'this week';
     } else {
        // 1M
        data = List.filled(30, 0.0);
        for(int i=29; i>=0; i--) {
           final day = today.subtract(Duration(days: i));
           calendar.forEach((ts, count) {
              final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              if (date.year == day.year && date.month == day.month && date.day == day.day) {
                 data[29-i] += count; 
                 total += count;
              }
           });
        }
        label = 'this month';
     }
     
     return (data, total, label);
  }

  Widget _buildDifficultyBreakdown(LeetBlockProvider provider) {
    final stats = provider.currentStats;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
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
          _buildDifficultyRow('Easy', stats?.easySolved ?? 0, stats?.totalEasy ?? 0, const Color(0xFF4CAF50)),
          const SizedBox(height: 16),
          _buildDifficultyRow('Medium', stats?.mediumSolved ?? 0, stats?.totalMedium ?? 0, const Color(0xFFFF9800)),
          const SizedBox(height: 16),
          _buildDifficultyRow('Hard', stats?.hardSolved ?? 0, stats?.totalHard ?? 0, const Color(0xFFF44336)),
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

  Widget _buildRecentActivity(LeetBlockProvider provider, BuildContext context) {
    final recentProblems = provider.detailedStats?['recentProblems'] as List<Map<String, dynamic>>? ?? [];
    
    return Container(
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
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (recentProblems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No recent activity',
                  style: GoogleFonts.inter(color: Colors.white38),
                ),
              ),
            )
          else
            Column(
              children: recentProblems.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final problem = entry.value;
                final title = problem['title'] ?? 'Unknown';
                final timestamp = problem['timestamp'] as int? ?? 0;
                final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                final timeStr = _getTimeAgo(date);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showSubmissionDetails(context, problem, _getTimeAgo(date)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 18, color: Color(0xFF4CAF50)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeStr,
                                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                          ],
                        ),
                      ),
                      if (index < recentProblems.take(5).length - 1)
                        Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  // --- HELPERS ---

  /// Formats duration in ms to "Xh Ym" or "Xm"
  String _formatDuration(int ms) {
    final totalMins = (ms / 1000 / 60).round();
    if (totalMins >= 60) {
      final hours = totalMins ~/ 60;
      final mins = totalMins % 60;
      return "${hours}h ${mins}m";
    }
    return "${totalMins}m";
  }

  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _dayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showSubmissionDetails(BuildContext context, Map<String, dynamic> problem, String timeAgo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Text(
          problem['title'] ?? 'Submission Details',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Language', problem['lang'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow('Runtime', problem['runtime'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow('Memory', problem['memory'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow('Time', timeAgo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFFFFA116))),
          )
        ],
      )
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54)),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

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
    
    final path = Path();
    final fillPath = Path();
    final width = size.width;
    final height = size.height;
    final pointWidth = width / (data.length - 1);
    
    // Find max value for normalization
    double maxVal = data.reduce(math.max);
    if (maxVal == 0) maxVal = 1;

    // Build path
    path.moveTo(0, height - (data[0] / maxVal * height));
    fillPath.moveTo(0, height);
    fillPath.lineTo(0, height - (data[0] / maxVal * height));

    for (int i = 1; i < data.length; i++) {
      final x = i * pointWidth;
      final y = height - (data[i] / maxVal * height);
      
      // Curved lines using quadratic bezier
      final prevX = (i - 1) * pointWidth;
      final prevY = height - (data[i - 1] / maxVal * height);
      final controlX = prevX + (x - prevX) / 2;
      
      path.cubicTo(controlX, prevY, controlX, y, x, y);
      fillPath.cubicTo(controlX, prevY, controlX, y, x, y);
    }
    
    fillPath.lineTo(width, height);
    fillPath.close();

    // Draw fill gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillColor, fillColor.withOpacity(0.0)],
      stops: const [0.0, 0.9],
    );
    
    final paintFill = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, paintFill);

    // Draw line
    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawPath(path, paintLine);
    
    // Draw Hover Indicator
    if (hoverIndex != null && hoverIndex! < data.length) {
      final x = hoverIndex! * pointWidth;
      final y = height - (data[hoverIndex!] / maxVal * height);
      
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = lineColor);
      
      // Vertical line
      final dashPaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      double dy = y + 8;
      while (dy < height) {
        canvas.drawLine(Offset(x, dy), Offset(x, math.min(dy + 4, height)), dashPaint);
        dy += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AreaChartPainter oldDelegate) => 
      oldDelegate.data != data || oldDelegate.hoverIndex != hoverIndex;
}
