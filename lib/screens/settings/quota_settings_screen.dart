import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/leet_block_provider.dart';

class QuotaSettingsScreen extends StatefulWidget {
  const QuotaSettingsScreen({super.key});

  @override
  State<QuotaSettingsScreen> createState() => _QuotaSettingsScreenState();
}

class _QuotaSettingsScreenState extends State<QuotaSettingsScreen> {
  late int _selectedQuota;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LeetBlockProvider>();
    _selectedQuota = provider.dailyQuota;
  }

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
          'Daily Quota',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<LeetBlockProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your daily goal',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    '$_selectedQuota',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFA116),
                    ),
                  ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _selectedQuota == 1
                        ? 'problem per day'
                        : 'problems per day',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFFA116),
                    inactiveTrackColor: const Color(0xFF252525),
                    thumbColor: const Color(0xFFFFA116),
                    overlayColor: const Color(0xFFFFA116).withOpacity(0.2),
                    trackHeight: 12,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 18,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1', style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 16)),
                      Text('10', style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 16)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white54, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Updating your quota will apply immediately for today.',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
