import 'package:flutter/material.dart';
import '../models/problem_list.dart';
import '../models/problem.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _nameController = TextEditingController();
  final Map<String, List<Problem>> _categories = {};
  final _categoryController = TextEditingController();

  void _addCategory() {
    final name = _categoryController.text.trim();
    if (name.isNotEmpty && !_categories.containsKey(name)) {
      setState(() {
        _categories[name] = [];
        _categoryController.clear();
      });
    }
  }

  void _addProblemToCategory(String category) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final urlController = TextEditingController();
        String difficulty = 'Medium';

        return StatefulBuilder(
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA116),
                ),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      _categories[category]!.add(Problem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text.trim(),
                        url: urlController.text.trim(),
                        difficulty: difficulty,
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveList() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    final newList = ProblemList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      isCustom: true,
      categories: _categories,
    );

    Navigator.pop(context, newList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create List', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveList,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFFFA116),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // List name
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'List Name',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFA116)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Add category
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Category name (e.g., Arrays)',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFA116)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _addCategory,
                icon: const Icon(Icons.add_circle, color: Color(0xFFFFA116), size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Categories
          ..._categories.entries.map((entry) {
            final category = entry.key;
            final problems = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                  title: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${problems.length} problems',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.expand_more, color: Colors.white54),
                    ],
                  ),
                  childrenPadding: EdgeInsets.zero,
                  children: [
                    Container(
                      color: const Color(0xFF252525),
                      child: Column(
                        children: [
                          ...problems.map((p) => ListTile(
                            title: Text(p.title, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(p.difficulty, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          )),
                          ListTile(
                            leading: const Icon(Icons.add, color: Color(0xFFFFA116)),
                            title: const Text(
                              'Add Problem',
                              style: TextStyle(color: Color(0xFFFFA116)),
                            ),
                            onTap: () => _addProblemToCategory(category),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}

