import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/leet_block_provider.dart';

class PenaltySettingsScreen extends StatelessWidget {
  const PenaltySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Usage Penalty',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<LeetBlockProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  // No border - removed as requested
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFFFFA116), // Changed to orange
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Penalty',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Increase quota if usage exceeds limit',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.penaltyEnabled,
                          onChanged:
                              (value) => provider.setPenaltyEnabled(value),
                          activeColor: const Color(0xFFFFA116),
                          activeTrackColor: const Color(
                            0xFFFFA116,
                          ).withOpacity(0.3),
                          inactiveThumbColor: Colors.white38,
                          inactiveTrackColor: Colors.white12,
                          trackOutlineColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (provider.penaltyEnabled) ...[
                const SizedBox(height: 32),
                Text(
                  'Configuration',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 16),
                _buildPenaltyCard(
                  title: 'Time Threshold',
                  subtitle: '${provider.penaltyThreshold} min allowed',
                  icon: Icons.hourglass_empty,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(
                        0xFFFFA116,
                      ), // Changed to orange
                      inactiveTrackColor: const Color(0xFF252525),
                      thumbColor: const Color(0xFFFFA116), // Changed to orange
                      overlayColor: const Color(0xFFFFA116).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: provider.penaltyThreshold.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: '${provider.penaltyThreshold} min',
                      onChanged:
                          (value) =>
                              provider.setPenaltyThreshold(value.round()),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                _buildPenaltyCard(
                  title: 'Penalty Amount',
                  subtitle: '+${provider.penaltyIncrement} problems',
                  icon: Icons.exposure_plus_1,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(
                        0xFFFFA116,
                      ), // Changed to orange
                      inactiveTrackColor: const Color(0xFF252525),
                      thumbColor: const Color(0xFFFFA116), // Changed to orange
                      overlayColor: const Color(0xFFFFA116).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: provider.penaltyIncrement.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '+${provider.penaltyIncrement}',
                      onChanged:
                          (value) =>
                              provider.setPenaltyIncrement(value.round()),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFA116,
                    ).withOpacity(0.1), // Changed to orange
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFFA116),
                        size: 20,
                      ), // Changed to orange
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'If you use blocked apps for more than ${provider.penaltyThreshold} minutes, your daily quota will increase by ${provider.penaltyIncrement}.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFA116), // Changed to orange
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPenaltyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFFFA116), // Changed to orange
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
