import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/leet_block_provider.dart';
import 'app_selection_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  int _selectedQuota = 1;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _validateUsername() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<LeetBlockProvider>();
    final success = await provider.validateAndSaveUsername(
      _usernameController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _setQuota() async {
    final provider = context.read<LeetBlockProvider>();
    await provider.setDailyQuota(_selectedQuota);
    if (mounted) {
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _requestPermission() async {
    await Permission.notification.request();
    if (mounted) {
      setState(() => _currentStep = 3);
    }
  }

  Future<void> _goToAppSelection() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AppSelectionScreen(),
      ),
    );

    if (result == true && mounted) {
      final provider = context.read<LeetBlockProvider>();
      await provider.completeSetup();
      // The main router will handle showing the permission screen
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
                _buildStepIndicator(),
                const SizedBox(height: 40),
                Expanded(
                  child: _buildCurrentStep(),
                ),
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
                Icons.code,
                color: Color(0xFFFFA116),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LeetBlock',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Discipline through code',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        for (int i = 0; i < 4; i++) ...[
          _buildStepDot(i),
          if (i < 3) _buildStepLine(i),
        ],
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStepDot(int step) {
    final isActive = step <= _currentStep;
    final isCurrent = step == _currentStep;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFFFFA116) : const Color(0xFF21262D),
        border: Border.all(
          color: isCurrent ? const Color(0xFFFFA116) : Colors.transparent,
          width: 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFFFFA116).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isActive
            ? Icon(
                step < _currentStep ? Icons.check : _getStepIcon(step),
                color: Colors.black,
                size: 20,
              )
            : Text(
                '${step + 1}',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.person;
      case 1:
        return Icons.flag;
      case 2:
        return Icons.notifications;
      case 3:
        return Icons.apps;
      default:
        return Icons.check;
    }
  }

  Widget _buildStepLine(int step) {
    final isActive = step < _currentStep;

    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFA116) : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildUsernameStep();
      case 1:
        return _buildQuotaStep();
      case 2:
        return _buildPermissionStep();
      case 3:
        return _buildAppsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUsernameStep() {
    return Consumer<LeetBlockProvider>(
      builder: (context, provider, _) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your LeetCode username',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              Text(
                'We\'ll track your daily progress to unlock apps',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'username',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: Colors.white30,
                  ),
                  prefixIcon: const Icon(
                    Icons.alternate_email,
                    color: Color(0xFFFFA116),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF21262D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFA116),
                      width: 2,
                    ),
                  ),
                  errorStyle: GoogleFonts.inter(
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              if (provider.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _validateUsername,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA116),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your daily quota',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          'How many LeetCode problems must you solve daily?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Text(
                '$_selectedQuota',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFA116),
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),
              Text(
                _selectedQuota == 1 ? 'problem per day' : 'problems per day',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFFA116),
                    inactiveTrackColor: const Color(0xFF21262D),
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
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1',
                    style: GoogleFonts.jetBrainsMono(color: Colors.white38),
                  ),
                  Text(
                    '10',
                    style: GoogleFonts.jetBrainsMono(color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _setQuota,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA116),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildPermissionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enable Notifications',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          'We need this to warn you before penalties and show the persistent blocker notification.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 48),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    size: 64,
                    color: Color(0xFFFFA116),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),
                const SizedBox(height: 24),
                Text(
                  'Stay informed!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _requestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA116),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Enable Notifications',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              if (mounted) {
                setState(() => _currentStep = 3);
              }
            },
            child: Text(
              'Skip for now',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildAppsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select apps to block',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          'These apps will be blocked until you complete your daily quota',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 48),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.apps,
                    size: 64,
                    color: Color(0xFFFFA116),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),
                const SizedBox(height: 24),
                Text(
                  'Choose wisely!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _goToAppSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA116),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Select Apps',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

