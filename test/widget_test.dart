import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/main.dart';

void main() {
  testWidgets('Stash app loads', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StashApp()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Stash'), findsWidgets);
  });
}
