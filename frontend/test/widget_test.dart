import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servisgadget_foundation/main.dart';

void main() {
  testWidgets('shows dummy login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ServisGadgetApp()));

    expect(find.text('Dummy Login'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Admin Toko'), findsOneWidget);
  });
}
