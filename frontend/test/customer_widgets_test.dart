import 'package:flutter_test/flutter_test.dart';
import 'package:servisgadget_foundation/features/customer/presentation/screens/welcome_screen.dart';
import 'package:servisgadget_foundation/features/customer/presentation/screens/service_flow_steps.dart';
import 'package:servisgadget_foundation/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:servisgadget_foundation/shared_widgets/status_badge.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('WelcomeScreen renders service and login buttons',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('ServisGadget'), findsOneWidget);
    expect(find.text('Ajukan Servis'), findsOneWidget);
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Toko'), findsOneWidget);
    expect(find.text('Admin Platform'), findsOneWidget);
  });

  testWidgets('StatusBadge shows label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StatusBadge(label: 'Active', isDanger: false))));

    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('StatusBadge shows danger style', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StatusBadge(label: 'Urgent', isDanger: true))));

    expect(find.text('Urgent'), findsOneWidget);
  });

  testWidgets('EmptyMessage displays text', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyMessage('No items'))));

    expect(find.text('No items'), findsOneWidget);
  });

  testWidgets('Step4 toggles courier pickup address field', (tester) async {
    final state = FlowState();
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        return Scaffold(
          body: Step4Widget(state: state, onChanged: () => setState(() {})),
        );
      }),
    ));

    expect(find.text('Alamat Penjemputan'), findsNothing);

    await tester.tap(find.text('Pickup Kurir'));
    await tester.pumpAndSettle();

    expect(state.delivery, 'courier_pickup');
    expect(find.text('Alamat Penjemputan'), findsOneWidget);

    await tester.tap(find.text('Antar ke Toko'));
    await tester.pumpAndSettle();

    expect(state.delivery, 'walk_in');
    expect(find.text('Alamat Penjemputan'), findsNothing);
  });
}
