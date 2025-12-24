import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/problem_list.dart';
import '../models/problem.dart';
import '../providers/leet_block_provider.dart';
import '../services/storage_service.dart';
import '../services/leetcode_service.dart';
import '../widgets/study_preferences_dialog.dart';

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

  /// Saves the current custom list immediately to storage
  Future<void> _saveCustomList() async {
    if (_storage == null || !_list.isCustom) return;
    
    // Load all existing custom lists
    final savedListsJson = _storage!.getProblemLists();
    final customLists = savedListsJson
        .map((json) => ProblemList.fromJson(json))
        .where((list) => list.isCustom)
        .toList();
    
    // Find and update this list, or add if new
    final index = customLists.indexWhere((l) => l.id == _list.id);
    if (index >= 0) {
      customLists[index] = _list;
    } else {
      customLists.add(_list);
    }
    
    // Save back
    await _storage!.saveProblemLists(customLists.map((l) => l.toJson()).toList());
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
    });
    _saveCustomList();
  }

  void _moveCategoryUp(int index) {
    if (index <= 0) return;
    setState(() {
      final keys = _list.orderedCategoryKeys;
      final temp = keys[index];
      keys[index] = keys[index - 1];
      keys[index - 1] = temp;
      _list.categoryOrder = keys;
    });
  }

  void _moveCategoryDown(int index) {
    final keys = _list.orderedCategoryKeys;
    if (index >= keys.length - 1) return;
    setState(() {
      final temp = keys[index];
      keys[index] = keys[index + 1];
      keys[index + 1] = temp;
      _list.categoryOrder = keys;
    });
  }

  void _renameCategory(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Rename Category', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Category name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFFFA116)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA116),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                setState(() {
                  // Get the problems from old category
                  final problems = _list.categories[oldName];
                  if (problems != null) {
                    // Add with new name
                    _list.categories[newName] = problems;
                    // Remove old name
                    _list.categories.remove(oldName);
                    // Update category order if exists
                    if (_list.categoryOrder != null) {
                      final idx = _list.categoryOrder!.indexOf(oldName);
                      if (idx >= 0) {
                        _list.categoryOrder![idx] = newName;
                      }
                    }
                  }
                });
                _saveCustomList();
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Category', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$category" and all its problems?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _list.categories.remove(category);
                // Update category order if exists
                _list.categoryOrder?.remove(category);
              });
              _saveCustomList();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
                _saveCustomList();
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
    final urlController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Problem', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste a LeetCode problem URL and we\'ll fetch the details automatically.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'LeetCode URL',
                  hintText: 'https://leetcode.com/problems/...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.link,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFA116)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  if (errorMessage != null) {
                    setDialogState(() => errorMessage = null);
                  }
                },
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFA116),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Fetching problem details...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isLoading ? Colors.white24 : Colors.white54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final url = urlController.text.trim();
                
                // Validate URL
                if (url.isEmpty) {
                  setDialogState(() => errorMessage = 'Please enter a LeetCode URL');
                  return;
                }
                
                if (!url.contains('leetcode.com/problems/')) {
                  setDialogState(() => errorMessage = 'Invalid URL. Please enter a valid LeetCode problem URL (e.g., leetcode.com/problems/two-sum)');
                  return;
                }
                
                setDialogState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                
                // Fetch problem details
                final leetCodeService = LeetCodeService();
                final details = await leetCodeService.fetchProblemDetails(url);
                
                if (details != null && details['title']!.isNotEmpty) {
                  // Success - add the problem
                  setState(() {
                    _list.categories[category]!.add(Problem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: details['title']!,
                      url: url,
                      difficulty: details['difficulty'] ?? 'Medium',
                      isPremium: details['isPremium'] == 'true',
                    ));
                  });
                  _saveCustomList();
                  Navigator.pop(context);
                } else {
                  // Failed to fetch
                  setDialogState(() {
                    isLoading = false;
                    errorMessage = 'Could not fetch problem details. Please check the URL and try again.';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLoading ? Colors.grey : const Color(0xFFFFA116),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add'),
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
          // Preferences button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Study Preferences',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StudyPreferencesDialog(
                  listId: _list.id,
                  listName: _list.name,
                ),
              );
            },
          ),
          if (_list.isCustom)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: _isEditing && _list.isCustom
          ? _buildEditableBody()
          : _buildReadOnlyBody(),
    );
  }

  Widget _buildReadOnlyBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProgressSummary(),
        const SizedBox(height: 16),
        ..._buildCategoryWidgets(),
      ],
    );
  }

  Widget _buildEditableBody() {
    final categoryKeys = _list.orderedCategoryKeys;
    
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProgressSummary(),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverReorderableList(
            itemCount: categoryKeys.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = categoryKeys.removeAt(oldIndex);
                categoryKeys.insert(newIndex, item);
                _list.categoryOrder = categoryKeys;
              });
              _saveCustomList();
            },
            itemBuilder: (context, index) {
              final category = categoryKeys[index];
              final problems = _list.sortedCategories[category] ?? [];
              final completedInCategory = problems.where((p) => p.isCompleted).length;
              
              return _buildCategoryTile(
                key: ValueKey(category),
                category: category,
                problems: problems,
                completedInCategory: completedInCategory,
                catIndex: index,
                showDragHandle: true,
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
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
        ),
      ],
    );
  }

  Widget _buildProgressSummary() {
    return Container(
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
    );
  }

  List<Widget> _buildCategoryWidgets() {
    return _list.sortedCategories.entries.toList().asMap().entries.map((mapEntry) {
      final catIndex = mapEntry.key;
      final entry = mapEntry.value;
      final category = entry.key;
      final problems = entry.value;
      final completedInCategory = problems.where((p) => p.isCompleted).length;

      return _buildCategoryTile(
        key: ValueKey(category),
        category: category,
        problems: problems,
        completedInCategory: completedInCategory,
        catIndex: catIndex,
        showDragHandle: false,
      );
    }).toList();
  }

  Widget _buildCategoryTile({
    required Key key,
    required String category,
    required List<Problem> problems,
    required int completedInCategory,
    required int catIndex,
    required bool showDragHandle,
  }) {
    return Container(
      key: key,
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
              // Drag handle (only in edit mode for custom lists)
              if (showDragHandle) ...[
                ReorderableDragStartListener(
                  index: catIndex,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              ],
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
              // Edit and delete buttons (only in edit mode for custom lists)
              if (_isEditing && _list.isCustom) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _renameCategory(category),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteCategory(category),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.withOpacity(0.7),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          childrenPadding: EdgeInsets.zero,
          children: [
            Container(
              color: const Color(0xFF252525),
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
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              problem.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: problem.isCompleted ? Colors.white54 : Colors.white,
                                decoration: problem.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (problem.isPremium) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA116).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFFA116).withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: const Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFA116),
                                ),
                              ),
                            ),
                          ],
                        ],
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
