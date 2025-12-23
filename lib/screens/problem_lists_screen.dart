import 'package:flutter/material.dart';
import '../models/problem_list.dart';
import '../services/storage_service.dart';
import 'problem_list_detail_screen.dart';
import 'create_list_screen.dart';

class ProblemListsScreen extends StatefulWidget {
  const ProblemListsScreen({super.key});

  @override
  State<ProblemListsScreen> createState() => _ProblemListsScreenState();
}

class _ProblemListsScreenState extends State<ProblemListsScreen> {
  List<ProblemList> _lists = [];
  late StorageService _storage;

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = StorageService();
    await _storage.init();
    _loadLists();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Problem Lists',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  list.isCustom ? Icons.folder_outlined : Icons.star_rounded,
                  color: const Color(0xFFFFA116),
                  size: 32,
                ),
                if (list.isCustom)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    color: const Color(0xFF252525),
                    onSelected: (value) {
                      if (value == 'edit') {
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
      onTap: () async {
        final newList = await Navigator.push<ProblemList>(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateListScreen(),
          ),
        );
        if (newList != null) {
          setState(() {
            _lists.add(newList);
          });
          _saveCustomLists();
        }
      },
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
}
