import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/problem_list.dart';
import '../models/problem.dart';
import '../services/leetcode_service.dart';

class CreateListScreen extends StatefulWidget {
  final LeetCodeService? leetCodeService;

  const CreateListScreen({super.key, this.leetCodeService});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  static final Uuid _uuid = Uuid();
  final _nameController = TextEditingController();
  final Map<String, List<Problem>> _categories = {};
  final _categoryController = TextEditingController();
  late final LeetCodeService _leetCodeService;

  @override
  void initState() {
    super.initState();
    _leetCodeService = widget.leetCodeService ?? LeetCodeService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _addCategory() {
    final name = _categoryController.text.trim();
    if (name.isNotEmpty && !_categories.containsKey(name)) {
      setState(() {
        _categories[name] = [];
        _categoryController.clear();
      });
    }
  }

  bool _isValidLeetCodeProblemUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return false;
    }

    final host = uri.host.toLowerCase();
    const allowedHosts = {
      'leetcode.com',
      'www.leetcode.com',
      'leetcode.cn',
      'www.leetcode.cn',
    };
    if (!allowedHosts.contains(host)) {
      return false;
    }

    final segments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.length < 2 || segments.first != 'problems') {
      return false;
    }

    final slug = segments[1];
    return RegExp(
      r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
      caseSensitive: false,
    ).hasMatch(slug);
  }

  bool _parseIsPremium(dynamic value) {
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  void _addProblemToCategory(String category) {
    final urlController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text(
                    'Add Problem',
                    style: TextStyle(color: Colors.white),
                  ),
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
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.link,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFFFA116),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
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
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isLoading ? Colors.white24 : Colors.white54,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                final url = urlController.text.trim();

                                if (url.isEmpty) {
                                  setDialogState(
                                    () =>
                                        errorMessage =
                                            'Please enter a LeetCode URL',
                                  );
                                  return;
                                }

                                if (!_isValidLeetCodeProblemUrl(url)) {
                                  setDialogState(
                                    () =>
                                        errorMessage =
                                            'Invalid URL. Please enter a valid LeetCode problem URL',
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                });

                                final dialogNavigator = Navigator.of(context);
                                Map<String, dynamic>? details;
                                try {
                                  details = await _leetCodeService
                                      .fetchProblemDetails(url);
                                } catch (error, stackTrace) {
                                  debugPrint(
                                    'Failed to fetch problem details for "$url": $error',
                                  );
                                  debugPrint('$stackTrace');
                                  details = null;
                                }

                                if (!mounted || !dialogNavigator.mounted) {
                                  return;
                                }

                                if (!_categories.containsKey(category)) {
                                  setDialogState(() {
                                    isLoading = false;
                                    errorMessage =
                                        'Category no longer exists. Please close this dialog and try again.';
                                  });
                                  return;
                                }

                                final title = details?['title'];
                                if (title is String &&
                                    title.trim().isNotEmpty) {
                                  final normalizedTitle = title.trim();
                                  final rawDifficulty = details?['difficulty'];
                                  final normalizedDifficulty =
                                      rawDifficulty is String &&
                                              rawDifficulty.trim().isNotEmpty
                                          ? rawDifficulty
                                          : 'Medium';
                                  setState(() {
                                    _categories[category]?.add(
                                      Problem(
                                        id: _uuid.v4(),
                                        title: normalizedTitle,
                                        url: url,
                                        difficulty: normalizedDifficulty,
                                        isPremium: _parseIsPremium(
                                          details?['isPremium'],
                                        ),
                                      ),
                                    );
                                  });
                                  dialogNavigator.pop();
                                } else {
                                  if (!dialogNavigator.mounted) {
                                    return;
                                  }
                                  setDialogState(() {
                                    isLoading = false;
                                    errorMessage =
                                        'Could not fetch problem details. Please check the URL.';
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLoading ? Colors.grey : const Color(0xFFFFA116),
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
    ).whenComplete(urlController.dispose);
  }

  void _saveList() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a list name')));
      return;
    }

    final newList = ProblemList(
      id: _uuid.v4(),
      name: trimmedName,
      isCustom: true,
      categories: _categories,
    );

    Navigator.pop(context, newList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            key: const ValueKey('create_list_save_button'),
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
            key: const ValueKey('create_list_name_input'),
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
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
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
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFFFFA116),
                  size: 32,
                ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
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
                          ...problems.map(
                            (p) => ListTile(
                              title: Text(
                                p.title,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                p.difficulty,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.add,
                              color: Color(0xFFFFA116),
                            ),
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
}
