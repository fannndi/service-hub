import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servisgadget_foundation/features/store_admin/presentation/screens/store_login_screen.dart';

void main() {
  testWidgets('shows store admin login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: StoreLoginScreen())));

    expect(find.text('ServisGadget - Portal Toko'), findsOneWidget);
    expect(find.text('Masuk sebagai Admin Toko'), findsOneWidget);
  });
}
