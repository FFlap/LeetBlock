import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/leet_block_provider.dart';
import 'settings/quota_settings_screen.dart';
import 'settings/penalty_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _tempQuota;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
    // Initialize temp quota from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _tempQuota = context.read<LeetBlockProvider>().dailyQuota;
        });
      }
    });
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() => _isNotificationEnabled = status.isGranted);
    }
  }

  bool _isNotificationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop && _tempQuota != null) {
          // Commit quota change when leaving screen
          final provider = context.read<LeetBlockProvider>();
          if (_tempQuota != provider.dailyQuota) {
            await provider.setDailyQuota(_tempQuota!);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Consumer<LeetBlockProvider>(
          builder: (context, provider, _) {
            // Ensure tempQuota is synced if it hasn't been initialized yet
            final currentQuota = _tempQuota ?? provider.dailyQuota;
            
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildAccountCard(provider),
                const SizedBox(height: 32),
                
                _buildSectionHeader('Focus'),
                _buildQuotaSection(context, currentQuota, provider), // Pass provider too
                _buildSettingTile(
                  icon: Icons.message_outlined,
                  title: 'Block Message',
                  subtitle: provider.blockMessage,
                  onTap: () => _showBlockMessageDialog(context, provider),
                ),
                _buildSettingTile(
                  icon: Icons.timer_outlined,
                  title: 'Usage Penalty',
                  subtitle: provider.penaltyEnabled 
                      ? 'Enabled • ${provider.penaltyThreshold}m limit' 
                      : 'Disabled',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PenaltySettingsScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                _buildStrictModeTile(context, provider),

                const SizedBox(height: 32),
                _buildSectionHeader('App'),
                _buildSettingTile(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: _isNotificationEnabled ? 'Enabled' : 'Disabled',
                  onTap: openAppSettings,
                ),
                const SizedBox(height: 32),
                _buildDangerZone(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountCard(LeetBlockProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LeetCode Username',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
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
          if (provider.currentStats != null) ...[
            const SizedBox(height: 16),
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
    ).animate().fadeIn();
  }

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  
  // Quota Section with Edit Today's Progress button
  Widget _buildQuotaSection(BuildContext context, int currentQuota, LeetBlockProvider provider) {
    final completed = provider.questionsCompletedToday;
    final isComplete = provider.isQuotaMet;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$currentQuota',
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFA116),
              ),
            ),
          ),
          Center(
            child: Text(
              currentQuota == 1
                  ? 'problem per day'
                  : 'problems per day',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ),
          const SizedBox(height: 16),
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
              value: currentQuota.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() => _tempQuota = value.round());
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: GoogleFonts.inter(color: Colors.white38)),
              Text('10', style: GoogleFonts.inter(color: Colors.white38)),
            ],
          ),
          // Edit Today's Progress - simple text link
          Center(
            child: TextButton(
              onPressed: () => _showTodaysProgressSheet(context, provider),
              child: Text(
                'Edit Today\'s Progress',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  void _showTodaysProgressSheet(BuildContext context, LeetBlockProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<LeetBlockProvider>(
        builder: (context, provider, _) {
          final completed = provider.questionsCompletedToday;
          final quota = provider.dailyQuota;
          final isComplete = provider.isQuotaMet;
          final offset = provider.manualOffset;
          
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Text(
                          '$completed',
                          style: GoogleFonts.inter(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: isComplete 
                                ? const Color(0xFF3FB950)
                                : const Color(0xFFFFA116),
                          ),
                        ),
                        Text(
                          'of $quota',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
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
                // Always reserve space to prevent sheet resizing
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: offset != 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              offset != 0 
                                  ? 'Manual adjustment: ${offset > 0 ? '+' : ''}$offset'
                                  : 'No adjustment',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: offset < 0 
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF3FB950),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: offset != 0 ? () => provider.resetManualOffset() : null,
                        child: Text(
                          'Reset adjustment',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: offset != 0 ? Colors.white38 : Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // Today's Progress section with +/- buttons
  Widget _buildDailyProgressSection(LeetBlockProvider provider) {
    final completed = provider.questionsCompletedToday;
    final quota = provider.dailyQuota;
    final isComplete = provider.isQuotaMet;
    final offset = provider.manualOffset;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
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
          if (offset != 0) ...[
            const SizedBox(height: 12),
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
                      style: GoogleFonts.inter(
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
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white38,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.white54, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildStrictModeTile(BuildContext context, LeetBlockProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Strict Mode',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white, // Fixed color to white
          ),
        ),
        subtitle: Text(
          provider.strictMode 
              ? 'App blocked until quota met'
              : 'Blocks only listed apps',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white38, // Fixed color to white38
          ),
        ),
        secondary: Icon(
          Icons.security,
          color: Colors.white54, // Fixed color to white54
          size: 22,
        ),
        value: provider.strictMode,
        onChanged: (value) {
          if (value) {
            _showStrictModeWarning(context, provider);
          } else {
            provider.setStrictMode(false);
          }
        },
        activeColor: const Color(0xFFFFA116),
        activeTrackColor: const Color(0xFFFFA116).withOpacity(0.3),
        inactiveThumbColor: Colors.white38,
        inactiveTrackColor: Colors.white10,
      ),
    ).animate().fadeIn();
  }

  Widget _buildDangerZone(LeetBlockProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Danger Zone'),
        _buildSettingTile(
          icon: Icons.delete_forever,
          title: 'Reset App',
          subtitle: 'Clear all data and settings',
          iconColor: const Color(0xFFFF6B6B),
          onTap: () => _showResetConfirmation(context, provider),
        ),
      ],
    );
  }

  void _showBlockMessageDialog(BuildContext context, LeetBlockProvider provider) {
    final controller = TextEditingController(text: provider.blockMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Text(
          'Block Message',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: Colors.white),
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'Enter message...',
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFA116)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              provider.setBlockMessage(controller.text.isEmpty ? 'LOCK IN' : controller.text);
              Navigator.pop(context);
            },
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFFFFA116))),
          ),
        ],
      ),
    );
  }

  void _showStrictModeWarning(BuildContext context, LeetBlockProvider provider) {
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
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'This will block access to this app until you complete your daily LeetCode quota.\n\nYou won\'t be able to:\n• Change your quota\n• Disable blocked apps\n• Turn off strict mode\n\nAre you sure?',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
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
                borderRadius: BorderRadius.circular(8),
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

  void _showResetConfirmation(BuildContext context, LeetBlockProvider provider) {
    final confirmationController = TextEditingController();
    
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
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 12),
            Text(
              'Reset App?',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will delete all data including:\n• Blocked apps list\n• Statistics & history\n• Settings\n\nType "confirm" to proceed:',
              style: GoogleFonts.inter(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmationController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'confirm',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (confirmationController.text == 'confirm') {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close settings
                await provider.reset();
              }
            },
            child: Text(
              'Reset Everything',
              style: GoogleFonts.inter(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
