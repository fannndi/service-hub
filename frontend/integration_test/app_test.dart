import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:service_me/core/supabase_service.dart';
import 'package:service_me/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => SupabaseService.instance.reset());

  group('Welcome Screen', () {
    testWidgets('renders all main elements', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Service Me'), findsOneWidget);
      expect(find.text('Ajukan Servis'), findsOneWidget);
      expect(find.text('Cek Pesanan'), findsOneWidget);
      expect(find.text('Daftarkan Toko Baru'), findsOneWidget);
      expect(find.text('Masuk'), findsNWidgets(2));
    });

    testWidgets('tap Ajukan Servis navigates to service flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajukan Servis'));
      await tester.pumpAndSettle();

      expect(find.text('Service Now'), findsOneWidget);
      expect(find.text('Perangkat'), findsOneWidget);
    });

    testWidgets('tap Cek Pesanan navigates to guest tracking', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cek Pesanan'));
      await tester.pumpAndSettle();

      expect(find.text('Tracking Pesanan'), findsOneWidget);
      expect(find.text('Cek Pesanan'), findsWidgets);
    });

    testWidgets('tap Masuk (customer) navigates to login', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk').first);
      await tester.pumpAndSettle();

      expect(find.text('Masuk Pelanggan'), findsOneWidget);
    });

    testWidgets('tap Daftarkan Toko Baru navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daftarkan Toko Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Daftarkan Toko'), findsOneWidget);
    });
  });

  group('Service Flow', () {
    testWidgets('step indicators visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajukan Servis'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Perangkat'), findsOneWidget);
      expect(find.text('Kerusakan'), findsOneWidget);
      expect(find.text('Toko'), findsOneWidget);
      expect(find.text('Data Diri'), findsOneWidget);
      expect(find.text('Konfirmasi'), findsOneWidget);
    });

    testWidgets('device type toggle works', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Servis'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('iPhone / iOS'));
      await tester.pumpAndSettle();
      expect(find.text('iPhone / iOS'), findsOneWidget);
    });
  });

  group('Guest Tracking', () {
    testWidgets('shows input fields', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cek Pesanan'));
      await tester.pumpAndSettle();

      expect(find.text('Tracking Pesanan'), findsOneWidget);
      expect(find.text('Cek Pesanan'), findsWidgets);
    });

    testWidgets('validates empty input', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cek Pesanan'));
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, 'Cek Pesanan');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Masukkan nomor pesanan dan nomor WhatsApp'), findsOneWidget);
    });
  });

  group('Store Admin', () {
    testWidgets('navigates to store login', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk').last);
      await tester.pumpAndSettle();

      expect(find.text('Portal Toko'), findsOneWidget);
    });
  });
}
