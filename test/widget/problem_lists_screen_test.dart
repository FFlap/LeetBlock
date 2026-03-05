import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:leet_block/models/problem.dart';
import 'package:leet_block/models/problem_list.dart';
import 'package:leet_block/providers/leet_block_provider.dart';
import 'package:leet_block/screens/problem_lists_screen.dart';
import '../support/fakes.dart';
import '../support/provider_test_harness.dart';

void main() {
  testWidgets('ProblemListsScreen can create and delete custom lists', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final existingList = ProblemList(
      id: 'existing',
      name: 'Old List',
      isCustom: true,
      categories: {
        'Array': [
          Problem(id: '1', title: 'Two Sum', difficulty: 'Easy', url: 'u1'),
        ],
      },
    );

    final provider = await createInitializedProvider(
      leetCodeService: StubLeetCodeService(),
      initialPrefs: {
        'problem_lists': jsonEncode([existingList.toJson()]),
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<LeetBlockProvider>.value(
        value: provider,
        child: const MaterialApp(home: ProblemListsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Old List'), findsOneWidget);

    final existingCard = find.byKey(
      const ValueKey('problem_list_card_existing'),
    );
    await tester.ensureVisible(existingCard);
    await tester.longPress(existingCard);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('problem_list_delete_confirm_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old List'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('problem_lists_create_card')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('problem_lists_create_name_input')),
      'New List',
    );
    await tester.tap(find.byKey(const ValueKey('problem_lists_create_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();
    expect(find.text('New List'), findsOneWidget);
  });

  testWidgets('ProblemListsScreen shows study indicator for active list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final provider = await createInitializedProvider(
      leetCodeService: StubLeetCodeService(),
      initialPrefs: {
        'study_preferences': jsonEncode({'activeListId': 'blind75'}),
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<LeetBlockProvider>.value(
        value: provider,
        child: const MaterialApp(home: ProblemListsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('problem_list_study_indicator_blind75')),
      findsOneWidget,
    );
  });
}
