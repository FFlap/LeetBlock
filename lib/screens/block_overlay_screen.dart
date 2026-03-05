import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BlockOverlayScreen extends StatelessWidget {
  final String appName;
  final int questionsRemaining;
  final int dailyQuota;
  final VoidCallback onGoToLeetCode;
  final VoidCallback onDismiss;

  const BlockOverlayScreen({
    super.key,
    required this.appName,
    required this.questionsRemaining,
    required this.dailyQuota,
    required this.onGoToLeetCode,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A0A), Color(0xFF0D1117), Color(0xFF1A0A0A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildBlockIcon(),
                const SizedBox(height: 40),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildMessage(),
                const SizedBox(height: 48),
                _buildProgressIndicator(),
                const Spacer(),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockIcon() {
    return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B6B).withOpacity(0.2),
                const Color(0xFFFF6B6B).withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: const Icon(Icons.block, size: 56, color: Color(0xFFFF6B6B)),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 2000.ms,
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
        );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'App Blocked',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            appName,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              color: const Color(0xFFFFA116),
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildMessage() {
    return Column(
      children: [
        Text(
          'You haven\'t completed your',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white60),
          textAlign: TextAlign.center,
        ),
        Text(
          'LeetCode quota for today',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildProgressIndicator() {
    final completed = dailyQuota - questionsRemaining;
    final progress = completed / dailyQuota;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$questionsRemaining',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFA116),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'more',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    questionsRemaining == 1 ? 'problem' : 'problems',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF161B22),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFA116),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completed / $dailyQuota completed today',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onGoToLeetCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA116),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.code),
            label: Text(
              'Go to LeetCode',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'Go Back',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
