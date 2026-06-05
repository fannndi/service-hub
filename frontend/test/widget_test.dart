import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servisgadget_foundation/main.dart';

void main() {
  testWidgets('boots customer app through splash route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ServisGadgetApp()));

    expect(find.text('ServisGadget'), findsOneWidget);
  });
}
