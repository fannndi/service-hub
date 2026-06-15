import 'package:flutter_test/flutter_test.dart';
import 'package:servisgadget_foundation/features/customer/presentation/screens/booking_form_screen.dart';
import 'package:servisgadget_foundation/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:servisgadget_foundation/shared_widgets/status_badge.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('WelcomeScreen renders service and login buttons', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('ServisGadget'), findsOneWidget);
    expect(find.text('Service Now'), findsOneWidget);
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Toko'), findsOneWidget);
  });

  testWidgets('StatusBadge shows label', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StatusBadge(label: 'Active', isDanger: false))));

    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('StatusBadge shows danger style', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StatusBadge(label: 'Urgent', isDanger: true))));

    expect(find.text('Urgent'), findsOneWidget);
  });

  testWidgets('EmptyMessage displays text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyMessage('No items'))));

    expect(find.text('No items'), findsOneWidget);
  });
}
