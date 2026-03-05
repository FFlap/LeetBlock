import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/leet_block_provider.dart';

class StudyPreferencesDialog extends StatefulWidget {
  final String listId;
  final String listName;

  const StudyPreferencesDialog({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<StudyPreferencesDialog> createState() => _StudyPreferencesDialogState();
}

class _StudyPreferencesDialogState extends State<StudyPreferencesDialog> {
  late bool _isStudyList;
  late bool _random;
  late bool _unsolvedOnly;
  late bool _easiestFirst;
  late bool _skipPremium;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LeetBlockProvider>();
    final prefs = provider.studyPreferences;
    _isStudyList = prefs['activeListId'] == widget.listId;
    _random = prefs['random'] as bool? ?? false;
    _unsolvedOnly = prefs['unsolvedOnly'] as bool? ?? true;
    _easiestFirst = prefs['easiestFirst'] as bool? ?? false;
    _skipPremium = prefs['skipPremium'] as bool? ?? true;
  }

  String _getBehaviorText() {
    String baseText;
    if (_random && _unsolvedOnly && _easiestFirst) {
      baseText =
          'Picks a random unsolved problem from the easiest difficulty tier (Easy → Medium → Hard)';
    } else if (_random && _unsolvedOnly) {
      baseText = 'Picks any random unsolved problem';
    } else if (_random && _easiestFirst) {
      baseText = 'Picks a random problem from the easiest difficulty tier';
    } else if (_unsolvedOnly && _easiestFirst) {
      baseText =
          'Picks the first unsolved problem, sorted by difficulty (Easy → Medium → Hard)';
    } else if (_random) {
      baseText = 'Picks any random problem (solved or unsolved)';
    } else if (_unsolvedOnly) {
      baseText = 'Picks the first unsolved problem in list order';
    } else if (_easiestFirst) {
      baseText =
          'Picks the first problem sorted by difficulty (Easy → Medium → Hard)';
    } else {
      baseText = 'Picks the first problem in list order';
    }

    if (_skipPremium) {
      baseText += ', excluding Premium problems';
    }

    return baseText;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Preferences',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.listName,
            style: const TextStyle(
              color: Color(0xFFFFA116),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Study toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Study this list',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _isStudyList
                      ? 'Problems from this list will open on block screen'
                      : 'Enable to practice problems from this list',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                value: _isStudyList,
                activeColor: const Color(0xFFFFA116),
                activeTrackColor: const Color(0xFFFFA116).withOpacity(0.3),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white10,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                onChanged: (value) {
                  setState(() => _isStudyList = value);
                },
              ),
            ),

            if (_isStudyList) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Problem Selection',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Multi-select options
              _buildCheckboxOption(
                'Random',
                'Shuffle problem selection',
                Icons.shuffle,
                _random,
                (value) => setState(() => _random = value ?? false),
              ),
              _buildCheckboxOption(
                'First unsolved',
                'Only pick problems not yet completed',
                Icons.check_box_outline_blank,
                _unsolvedOnly,
                (value) => setState(() => _unsolvedOnly = value ?? false),
              ),
              _buildCheckboxOption(
                'Easiest first',
                'Prioritize Easy → Medium → Hard',
                Icons.trending_down,
                _easiestFirst,
                (value) => setState(() => _easiestFirst = value ?? false),
              ),
              _buildCheckboxOption(
                'Skip premium',
                'Don\'t assign LeetCode Premium problems',
                Icons.workspace_premium,
                _skipPremium,
                (value) => setState(() => _skipPremium = value ?? true),
              ),

              // Behavior description
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFA116).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFFA116),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Behavior',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getBehaviorText(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          key: const ValueKey('study_preferences_save_button'),
          onPressed: _savePreferences,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA116),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isSaving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            value
                ? const Color(0xFFFFA116).withOpacity(0.15)
                : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFFFFA116) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            color: value ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFFA116),
        checkColor: Colors.black,
        secondary: Icon(
          icon,
          color: value ? const Color(0xFFFFA116) : Colors.white54,
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Future<void> _savePreferences() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<LeetBlockProvider>();

    if (_isStudyList) {
      await provider.setStudyList(widget.listId);
      await provider.setStudyOptions(
        random: _random,
        unsolvedOnly: _unsolvedOnly,
        easiestFirst: _easiestFirst,
        skipPremium: _skipPremium,
      );
    } else {
      // Only clear if this was the active list
      final currentActive = provider.studyPreferences['activeListId'];
      if (currentActive == widget.listId) {
        await provider.setStudyList(null);
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
