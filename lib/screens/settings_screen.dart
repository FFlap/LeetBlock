import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/leet_block_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _selectedQuota;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LeetBlockProvider>();
    _selectedQuota = provider.dailyQuota;
    _selectedQuota = provider.dailyQuota;
    _messageController = TextEditingController(text: provider.blockMessage);
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() => _isNotificationEnabled = status.isGranted);
    }
  }

  bool _isNotificationEnabled = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildUserSection(),
                  const SizedBox(height: 16),
                  _buildQuotaSection(),
                  const SizedBox(height: 16),
                  _buildDailyProgressSection(),
                  const SizedBox(height: 16),
                  _buildBlockMessageSection(),
                  const SizedBox(height: 16),
                  _buildStrictModeSection(),
                  const SizedBox(height: 16),
                  _buildPenaltySection(),
                  const SizedBox(height: 16),
                  _buildDangerZone(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }



  Widget _buildUserSection() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
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
                'Account',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA116).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFFFFA116),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LeetCode Username',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          provider.username,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.currentStats != null) ...[
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      'Total',
                      '${provider.currentStats!.totalSolved}',
                    ),
                    _buildMiniStat(
                      'Easy',
                      '${provider.currentStats!.easySolved}',
                    ),
                    _buildMiniStat(
                      'Medium',
                      '${provider.currentStats!.mediumSolved}',
                    ),
                    _buildMiniStat(
                      'Hard',
                      '${provider.currentStats!.hardSolved}',
                    ),
                  ],
                ),

              ],
            ],
          ),
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgressSection() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        final completed = provider.questionsCompletedToday;
        final quota = provider.dailyQuota;
        final isComplete = provider.isQuotaMet;
        final offset = provider.manualOffset;
        
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Progress',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF238636).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '✓ Complete',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF3FB950),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decrement button
                  IconButton(
                    onPressed: completed > 0 
                        ? () => provider.adjustCompletedCount(-1)
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: completed > 0 
                          ? const Color(0xFF252525)
                          : Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                    ),
                    icon: Icon(
                      Icons.remove,
                      color: completed > 0 
                          ? Colors.white70 
                          : Colors.white24,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Count display
                  Column(
                    children: [
                      Text(
                        '$completed',
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isComplete 
                              ? const Color(0xFF3FB950)
                              : const Color(0xFFFFA116),
                        ),
                      ),
                      Text(
                        'of $quota',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Increment button
                  IconButton(
                    onPressed: () => provider.adjustCompletedCount(1),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF252525),
                    ),
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Show offset if non-zero
              if (offset != 0) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: offset < 0 
                          ? const Color(0xFFFF6B6B).withOpacity(0.15)
                          : const Color(0xFF238636).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          offset < 0 ? Icons.trending_down : Icons.trending_up,
                          size: 14,
                          color: offset < 0 
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF3FB950),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Manual adjustment: ${offset > 0 ? '+' : ''}$offset',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: offset < 0 
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF3FB950),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => provider.resetManualOffset(),
                    child: Text(
                      'Reset adjustment',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Adjustments persist through refreshes',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 200.ms);
      },
    );
  }

  Widget _buildQuotaSection() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Quota',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '$_selectedQuota',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFA116),
                  ),
                ),
              ),
              Center(
                child: Text(
                  _selectedQuota == 1
                      ? 'problem per day'
                      : 'problems per day',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFFFA116),
                  inactiveTrackColor: const Color(0xFF252525),
                  thumbColor: const Color(0xFFFFA116),
                  overlayColor: const Color(0xFFFFA116).withOpacity(0.2),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                  ),
                ),
                child: Slider(
                  value: _selectedQuota.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() => _selectedQuota = value.round());
                  },
                  onChangeEnd: (value) async {
                    await provider.setDailyQuota(value.round());
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1', style: GoogleFonts.jetBrainsMono(color: Colors.white38)),
                  Text('10', style: GoogleFonts.jetBrainsMono(color: Colors.white38)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms);
      },
    );
  }

  Widget _buildBlockMessageSection() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Block Screen Message',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customize the message shown when apps are blocked',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLength: 30,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF252525),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFA116)),
                  ),
                  hintText: 'LOCK IN',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white24,
                  ),
                  counterStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                onChanged: (value) {
                  provider.setBlockMessage(value.isEmpty ? 'LOCK IN' : value);
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms);
      },
    );
  }

  Widget _buildStrictModeSection() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: provider.strictMode 
                  ? const Color(0xFFFFA116).withOpacity(0.5)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: Color(0xFFFFA116),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Strict Mode',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFFFA116),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Block this app too until quota is met. Prevents lowering quota to cheat.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.strictMode ? 'Enabled' : 'Disabled',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: provider.strictMode 
                          ? const Color(0xFFFFA116)
                          : Colors.white38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: provider.strictMode,
                    onChanged: (value) {
                      if (value) {
                        _showStrictModeWarning(provider);
                      } else {
                        provider.setStrictMode(false);
                      }
                    },
                    activeColor: const Color(0xFFFFA116),
                    activeTrackColor: const Color(0xFFFFA116).withOpacity(0.3),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                  ),
                ],
              ),
              if (provider.strictMode) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA116).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFFA116),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You won\'t be able to access this app until you complete your daily quota!',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFFFA116),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 275.ms);
      },
    );
  }

  void _showStrictModeWarning(LeetBlockProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFFFFA116)),
            const SizedBox(width: 12),
            Text(
              'Enable Strict Mode?',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'This will block access to this app until you complete your daily LeetCode quota.\n\nYou won\'t be able to:\n• Change your quota\n• Disable blocked apps\n• Turn off strict mode\n\nAre you sure?',
          style: GoogleFonts.inter(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setStrictMode(true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA116),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Enable',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltySection() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: provider.penaltyEnabled 
                  ? const Color(0xFFFF6B6B).withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Color(0xFFFF6B6B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Usage Penalty',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Increase daily quota if you spend too much time on blocked apps.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.penaltyEnabled ? 'Enabled' : 'Disabled',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: provider.penaltyEnabled 
                          ? const Color(0xFFFF6B6B)
                          : Colors.white38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: provider.penaltyEnabled,
                    onChanged: (value) => provider.setPenaltyEnabled(value),
                    activeColor: const Color(0xFFFF6B6B),
                    activeTrackColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                  ),
                ],
              ),
              if (provider.penaltyEnabled) ...[
                const SizedBox(height: 24),
                Text(
                  'Time Threshold',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${provider.penaltyThreshold}m',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFF6B6B),
                          inactiveTrackColor: const Color(0xFF252525),
                          thumbColor: const Color(0xFFFF6B6B),
                          overlayColor: const Color(0xFFFF6B6B).withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: provider.penaltyThreshold.toDouble(),
                          min: 1,
                          max: 120,
                          divisions: 119,
                          label: '${provider.penaltyThreshold}m',
                          onChanged: (value) => provider.setPenaltyThreshold(value.round()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Penalty Amount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+${provider.penaltyIncrement} problem${provider.penaltyIncrement > 1 ? "s" : ""}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: provider.penaltyIncrement > 1 
                              ? () => provider.setPenaltyIncrement(provider.penaltyIncrement - 1)
                              : null,
                          icon: const Icon(Icons.remove, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF252525),
                            foregroundColor: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: provider.penaltyIncrement < 5 
                              ? () => provider.setPenaltyIncrement(provider.penaltyIncrement + 1)
                              : null,
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF252525),
                            foregroundColor: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warning Notifications',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get notified before penalty applies',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isNotificationEnabled,
                      onChanged: (value) async {
                        if (value) {
                          final status = await Permission.notification.request();
                          if (status.isPermanentlyDenied) {
                            openAppSettings();
                          }
                          setState(() => _isNotificationEnabled = status.isGranted);
                        } else {
                          openAppSettings();
                        }
                      },
                      activeColor: const Color(0xFFFF6B6B),
                      activeTrackColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white12,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 285.ms);
      },
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF6B6B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showResetConfirmation(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B6B),
                side: const BorderSide(color: Color(0xFFFF6B6B)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Reset All Settings',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Text(
          'Reset All Settings?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will clear your username, quota, and blocked apps list. You\'ll need to set up the app again.',
          style: GoogleFonts.inter(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<LeetBlockProvider>().reset();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

