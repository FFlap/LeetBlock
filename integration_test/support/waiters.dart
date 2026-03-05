import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 50),
  String? description,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) {
      return;
    }
    await tester.pump(step);
  }
  if (predicate()) {
    return;
  }

  final descriptionSuffix = description == null ? '' : ': $description';
  throw TestFailure(
    'Timed out waiting for condition$descriptionSuffix after '
    '${timeout.inMilliseconds}ms.',
  );
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 50),
  String? description,
}) {
  return pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    timeout: timeout,
    step: step,
    description: description ?? 'finder $finder to appear',
  );
}

Future<void> waitForFinderGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 50),
  String? description,
}) {
  return pumpUntil(
    tester,
    () => finder.evaluate().isEmpty,
    timeout: timeout,
    step: step,
    description: description ?? 'finder $finder to disappear',
  );
}

Future<void> tapWhenVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 50),
  String? description,
}) async {
  await waitForFinder(
    tester,
    finder,
    timeout: timeout,
    step: step,
    description: description,
  );
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  await tester.pump();
}

Future<void> longPressWhenVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 50),
  String? description,
}) async {
  await waitForFinder(
    tester,
    finder,
    timeout: timeout,
    step: step,
    description: description,
  );
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.longPress(target);
  await tester.pump();
}
