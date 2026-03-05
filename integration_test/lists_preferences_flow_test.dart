import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leet_block/main.dart';

import 'support/fakes.dart';
import 'support/platform_channel_mock.dart';
import 'support/provider_harness.dart';
import 'support/waiters.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('list create and study preferences persist', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final platformMock = PlatformChannelMock();
    await platformMock.install();
    addTearDown(() => platformMock.uninstall());

    final provider = await createIntegrationProvider(
      leetCodeService: StubLeetCodeService(),
      initialPrefs: const {
        'is_setup_complete': true,
        'leetcode_username': 'alice',
      },
    );

    await tester.pumpWidget(
      LeetBlockApp(provider: provider, autoStartBlockerService: false),
    );
    await waitForFinder(
      tester,
      find.byIcon(Icons.list_alt_rounded),
      description: 'bottom navigation to load',
    );

    await tapWhenVisible(
      tester,
      find.byIcon(Icons.list_alt_rounded),
      description: 'lists tab button',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('problem_lists_create_card')),
      description: 'problem lists screen',
    );

    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('problem_lists_create_card')),
      description: 'create list card',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('problem_lists_create_name_input')),
      description: 'create list dialog',
    );

    await tester.enterText(
      find.byKey(const ValueKey('problem_lists_create_name_input')),
      'Integration List',
    );
    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('problem_lists_create_button')),
      description: 'create list button',
    );
    await waitForFinder(
      tester,
      find.byIcon(Icons.arrow_back),
      description: 'list detail screen',
    );

    await tapWhenVisible(
      tester,
      find.byIcon(Icons.arrow_back),
      description: 'back from list detail',
    );
    await waitForFinder(
      tester,
      find.text('Integration List'),
      description: 'created list to appear',
    );
    final listInGrid = find.descendant(
      of: find.byType(GridView),
      matching: find.text('Integration List'),
    );
    expect(listInGrid, findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    final savedLists =
        (jsonDecode(prefs.getString('problem_lists') ?? '[]') as List<dynamic>)
            .cast<Map<String, dynamic>>();
    Map<String, dynamic>? createdList;
    for (final list in savedLists) {
      if (list['name'] == 'Integration List') {
        createdList = list;
        break;
      }
    }
    expect(createdList, isNotNull);
    final createdListId = createdList!['id'] as String;
    final createdListCard = find.byKey(
      ValueKey('problem_list_card_$createdListId'),
    );
    await waitForFinder(
      tester,
      createdListCard,
      description: 'created list card to appear',
    );
    await provider.setStudyList(createdListId);
    await waitForFinder(
      tester,
      find.byIcon(Icons.school),
      description: 'study indicator',
    );
    final persistedStudyPrefs =
        jsonDecode(prefs.getString('study_preferences') ?? '{}')
            as Map<String, dynamic>;
    expect(persistedStudyPrefs['activeListId'], createdListId);
  });
}
