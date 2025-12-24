import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/problem_list.dart';
import '../providers/leet_block_provider.dart';
import '../services/storage_service.dart';
import '../widgets/study_preferences_dialog.dart';
import 'problem_list_detail_screen.dart';

class ProblemListsScreen extends StatefulWidget {
  const ProblemListsScreen({super.key});

  @override
  State<ProblemListsScreen> createState() => ProblemListsScreenState();
}

class ProblemListsScreenState extends State<ProblemListsScreen> {
  List<ProblemList> _lists = [];
  late StorageService _storage;
  bool _isInitialized = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  /// Public method to refresh the lists and sync from LeetCode - called when tab is selected
  void refresh() {
    if (_isInitialized) {
      _syncFromLeetCode();
    }
  }

  Future<void> _syncFromLeetCode() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    
    try {
      final provider = context.read<LeetBlockProvider>();
      // Fetch latest from LeetCode and sync to lists
      await provider.fetchAndSyncProblemLists();
    } catch (e) {
      // Silent fail
    }
    
    // Reload lists with updated completion status
    _loadLists();
    
    setState(() => _isSyncing = false);
  }

  Future<void> _initStorage() async {
    _storage = StorageService();
    await _storage.init();
    _isInitialized = true;
    _loadLists();
    // Initial sync when first opened
    _syncFromLeetCode();
  }

  void _loadLists() {
    // Load default lists
    final defaultLists = [
      DefaultProblemLists.blind75,
      DefaultProblemLists.neetcode250,
    ];
    
    // Load custom lists from storage
    final savedListsJson = _storage.getProblemLists();
    final customLists = savedListsJson
        .map((json) => ProblemList.fromJson(json))
        .where((list) => list.isCustom)
        .toList();
    
    final allLists = [...defaultLists, ...customLists];
    
    // Apply saved completion status to all lists
    final completion = _storage.getProblemCompletion();
    for (final list in allLists) {
      for (final category in list.categories.entries) {
        for (final problem in category.value) {
          final key = '${list.id}_${problem.id}';
          if (completion.containsKey(key)) {
            problem.isCompleted = completion[key]!;
          }
        }
      }
    }
    
    setState(() {
      _lists = allLists;
    });
  }

  Future<void> _saveCustomLists() async {
    final customLists = _lists
        .where((list) => list.isCustom)
        .map((list) => list.toJson())
        .toList();
    await _storage.saveProblemLists(customLists);
  }

  void _showPreferencesDialog(ProblemList list) {
    showDialog(
      context: context,
      builder: (context) => StudyPreferencesDialog(
        listId: list.id,
        listName: list.name,
      ),
    ).then((_) {
      // Refresh to show study indicator
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Problem Lists',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA116)),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncFromLeetCode,
        color: const Color(0xFFFFA116),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: _lists.length + 1, // +1 for "Create New" card
            itemBuilder: (context, index) {
              if (index == _lists.length) {
                return _buildCreateNewCard();
              }
              return _buildListCard(_lists[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(ProblemList list) {
    final progress = list.totalProblems > 0
        ? list.completedProblems / list.totalProblems
        : 0.0;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<ProblemList>(
          context,
          MaterialPageRoute(
            builder: (context) => ProblemListDetailScreen(problemList: list),
          ),
        );
        if (result != null) {
          setState(() {
            final index = _lists.indexWhere((l) => l.id == list.id);
            if (index != -1) {
              _lists[index] = result;
            }
          });
          if (result.isCustom) _saveCustomLists();
        }
      },
      onLongPress: list.isCustom ? () => _showDeleteDialog(list) : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Consumer<LeetBlockProvider>(
          builder: (context, provider, _) {
            final isStudyList = provider.studyPreferences['activeListId'] == list.id;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          list.isCustom ? Icons.folder_outlined : Icons.star_rounded,
                          color: const Color(0xFFFFA116),
                          size: 32,
                        ),
                        if (isStudyList)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      color: const Color(0xFF252525),
                      onSelected: (value) {
                        if (value == 'preferences') {
                          _showPreferencesDialog(list);
                        } else if (value == 'edit') {
                          Navigator.push<ProblemList>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProblemListDetailScreen(
                                problemList: list,
                                startInEditMode: true,
                              ),
                            ),
                          ).then((result) {
                            if (result != null) {
                              setState(() {
                                final index = _lists.indexWhere((l) => l.id == list.id);
                                if (index != -1) {
                                  _lists[index] = result;
                                }
                              });
                              _saveCustomLists();
                            }
                          });
                        } else if (value == 'delete') {
                          _showDeleteDialog(list);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'preferences',
                          child: Row(
                            children: [
                              Icon(Icons.settings, color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text('Preferences', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        if (list.isCustom) ...[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Text('Edit', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  list.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${list.completedProblems}/${list.totalProblems} problems',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA116)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(ProblemList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete List?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${list.name}"?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _lists.removeWhere((l) => l.id == list.id);
              });
              _saveCustomLists();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNewCard() {
    return GestureDetector(
      onTap: () => _showCreateDialog(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Create New',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Create New List', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'List name',
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              
              Navigator.pop(context);
              
              // Create new empty list
              final newList = ProblemList(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                isCustom: true,
                categories: {},
              );
              
              // Add to lists and save
              setState(() {
                _lists.add(newList);
              });
              _saveCustomLists();
              
              // Open in edit mode
              final result = await Navigator.push<ProblemList>(
                context,
                MaterialPageRoute(
                  builder: (context) => ProblemListDetailScreen(
                    problemList: newList,
                    startInEditMode: true,
                  ),
                ),
              );
              
              // Update list with any edits
              if (result != null) {
                setState(() {
                  final index = _lists.indexWhere((l) => l.id == result.id);
                  if (index != -1) {
                    _lists[index] = result;
                  }
                });
                _saveCustomLists();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
