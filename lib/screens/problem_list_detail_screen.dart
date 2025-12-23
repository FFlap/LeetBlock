import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/problem_list.dart';
import '../models/problem.dart';
import '../services/storage_service.dart';

class ProblemListDetailScreen extends StatefulWidget {
  final ProblemList problemList;
  final bool startInEditMode;

  const ProblemListDetailScreen({
    super.key,
    required this.problemList,
    this.startInEditMode = false,
  });

  @override
  State<ProblemListDetailScreen> createState() => _ProblemListDetailScreenState();
}

class _ProblemListDetailScreenState extends State<ProblemListDetailScreen> {
  late ProblemList _list;
  late bool _isEditing;
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    _list = widget.problemList;
    _isEditing = widget.startInEditMode && widget.problemList.isCustom;
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = StorageService();
    await _storage!.init();
    _loadCompletionStatus();
  }

  void _loadCompletionStatus() {
    if (_storage == null) return;
    final completion = _storage!.getProblemCompletion();
    setState(() {
      for (final category in _list.categories.entries) {
        for (final problem in category.value) {
          final key = '${_list.id}_${problem.id}';
          if (completion.containsKey(key)) {
            problem.isCompleted = completion[key]!;
          }
        }
      }
    });
  }

  Future<void> _saveCompletionStatus() async {
    if (_storage == null) return;
    final completion = <String, bool>{};
    for (final category in _list.categories.entries) {
      for (final problem in category.value) {
        final key = '${_list.id}_${problem.id}';
        completion[key] = problem.isCompleted;
      }
    }
    // Merge with existing completion data
    final existing = _storage!.getProblemCompletion();
    existing.addAll(completion);
    await _storage!.saveProblemCompletion(existing);
  }

  void _toggleProblem(String category, String problemId) {
    setState(() {
      final problems = _list.categories[category]!;
      final problem = problems.firstWhere((p) => p.id == problemId);
      problem.isCompleted = !problem.isCompleted;
    });
    _saveCompletionStatus();
  }

  Future<void> _openProblem(Problem problem) async {
    final uri = Uri.parse(problem.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _deleteProblem(String category, int index) {
    setState(() {
      _list.categories[category]!.removeAt(index);
      if (_list.categories[category]!.isEmpty) {
        _list.categories.remove(category);
      }
    });
  }

  void _addCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Category', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Category name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFA116)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _list.categories[controller.text] = [];
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFFFFA116))),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _list.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Rename List', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'List name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFA116)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _list.name = controller.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFFFFA116))),
          ),
        ],
      ),
    );
  }

  void _addProblem(String category) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String difficulty = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Problem', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Problem Title',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFA116)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'LeetCode URL',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFA116)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: difficulty,
                dropdownColor: const Color(0xFF252525),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Difficulty',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                items: ['Easy', 'Medium', 'Hard'].map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => difficulty = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _list.categories[category]!.add(Problem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      url: urlController.text.trim(),
                      difficulty: difficulty,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Color(0xFFFFA116))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        scrolledUnderElevation: 0,
        title: _isEditing && _list.isCustom
            ? GestureDetector(
                onTap: _showRenameDialog,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _list.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 16, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
              )
            : Text(
                _list.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _list),
        ),
        actions: [
          if (_list.isCustom)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_list.completedProblems}/${_list.totalProblems}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA116),
                        ),
                      ),
                      Text(
                        'Problems Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _list.totalProblems > 0
                        ? _list.completedProblems / _list.totalProblems
                        : 0,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA116)),
                    strokeWidth: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories with accordions (sorted by difficulty)
          ..._list.sortedCategories.entries.map((entry) {
            final category = entry.key;
            final problems = entry.value;
            final completedInCategory = problems.where((p) => p.isCompleted).length;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA116).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$completedInCategory/${problems.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFFA116),
                          ),
                        ),
                      ),
                    ],
                  ),
                  iconColor: Colors.white54,
                  collapsedIconColor: Colors.white54,
                  childrenPadding: EdgeInsets.zero,
                  children: [
                    Container(
                      color: const Color(0xFF252525), // Lighter background for expanded area
                      child: Column(
                        children: [
                          ...problems.asMap().entries.map((problemEntry) {
                            final index = problemEntry.key;
                            final problem = problemEntry.value;

                            return ListTile(
                      leading: GestureDetector(
                        onTap: () => _toggleProblem(category, problem.id),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: problem.isCompleted
                                ? const Color(0xFFFFA116)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: problem.isCompleted
                                  ? const Color(0xFFFFA116)
                                  : Colors.white38,
                              width: 2,
                            ),
                          ),
                          child: problem.isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.black)
                              : null,
                        ),
                      ),
                      title: Text(
                        problem.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: problem.isCompleted ? Colors.white54 : Colors.white,
                          decoration: problem.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDifficultyBadge(problem.difficulty),
                          const SizedBox(width: 4),
                          if (_isEditing && _list.isCustom)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: Colors.red.withOpacity(0.7),
                              onPressed: () => _deleteProblem(category, index),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              color: Colors.white54,
                              onPressed: () => _openProblem(problem),
                            ),
                        ],
                      ),
                      onTap: () => _toggleProblem(category, problem.id),
                    );
                  }),
                          if (_isEditing && _list.isCustom)
                            ListTile(
                              leading: const Icon(Icons.add, color: Color(0xFFFFA116)),
                              title: const Text(
                                'Add Problem',
                                style: TextStyle(color: Color(0xFFFFA116)),
                              ),
                              onTap: () => _addProblem(category),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Add category button
          if (_isEditing && _list.isCustom)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, color: Color(0xFFFFA116)),
                label: const Text('Add Category', style: TextStyle(color: Color(0xFFFFA116))),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFFFA116).withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF00B8A3);
        break;
      case 'medium':
        color = const Color(0xFFFFC01E);
        break;
      case 'hard':
        color = const Color(0xFFFF375F);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
