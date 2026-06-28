import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:service_me/core/supabase_service.dart';
import 'package:service_me/main.dart' as app;

/// Helper: tap first IconButton (AppBar back button)
Future<void> tapBack(WidgetTester tester) async {
  final icon = find.byIcon(Icons.arrow_back);
  if (icon.evaluate().isNotEmpty) {
    await tester.tap(icon);
  } else {
    await tester.tap(find.byType(IconButton).first);
  }
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => SupabaseService.instance.reset());

  testWidgets('Deep flow: service → tracking → register → login',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // ─── SERVICE FLOW ───
    await tester.tap(find.text('Ajukan Servis'));
    await tester.pumpAndSettle();
    expect(find.text('Service Now'), findsOneWidget);
    await tester.tap(find.text('iPhone / iOS'));
    await tester.pumpAndSettle();

    await tapBack(tester);
    expect(find.text('Service Me'), findsOneWidget);

    // ─── TRACKING ───
    await tester.tap(find.text('Cek Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Tracking Pesanan'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Cek Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan nomor pesanan dan nomor WhatsApp'), findsOneWidget);

    await tapBack(tester);
    expect(find.text('Service Me'), findsOneWidget);

    // ─── STORE REGISTER ───
    await tester.tap(find.text('Daftarkan Toko Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Daftarkan Toko'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Kirim Pendaftaran'));
    await tester.pumpAndSettle();
    expect(find.text('Semua field wajib diisi'), findsOneWidget);

    await tapBack(tester);
    expect(find.text('Service Me'), findsOneWidget);

    // ─── LOGIN ───
    await tester.tap(find.text('Masuk').first);
    await tester.pumpAndSettle();
    expect(find.text('Masuk Pelanggan'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.textContaining('wajib'), findsAtLeast(1));
  });
}
