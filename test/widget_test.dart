import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:esther/main.dart';

void main() {
  testWidgets('Esther démarre sur la liste produits', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EstherApp()),
    );

    expect(find.text('Esther'), findsOneWidget);
    expect(find.text('Montures sélection'), findsOneWidget);
  });
}
