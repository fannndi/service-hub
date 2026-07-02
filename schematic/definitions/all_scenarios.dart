import '../core/scenario.dart';
import '../core/action.dart';
import '../core/assertion.dart';

class AllScenarios {
  static List<Scenario> get list => [
    _guestBooking,
    _platformAdmin,
    _edgeFunctionTests,
  ];

  // ─── SCENARIO 1: Guest Booking ───
  // Tests the guest Edge Function (create-order)
  static final _guestBooking = Scenario(
    id: 'guest-booking',
    description: 'Guest creates sparepart order via guest Edge Function',
    setupData: {'seed': true},
    steps: [
      ScenarioStep(
        id: 'create-guest-order',
        description: 'Guest creates order',
        action: SchematicAction(
          type: 'invoke', target: 'guest',
          body: {
            'action': 'create-order',
            'store_id': '175ea16e-7128-42c6-b4cd-c021e67f11ef',
            'device_type': 'android', 'brand': 'Samsung', 'device_model': 'Galaxy S24',
            'delivery_method': 'walk_in',
            'customer_name': 'Budi Santoso', 'phone_number': '08123456789',
            'items': [{'service_type': 'screen_replacement', 'complaint': 'Layar retak',
              'sparepart_id': '420e7371-2ece-4a63-988a-7ce1a4a494dc', 'item_price': 1200000}],
          },
        ),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
    ],
  );

  // ─── SCENARIO 2: Platform Admin ───
  // Tests admin Edge Function + auth flow
  static final _platformAdmin = Scenario(
    id: 'platform-admin',
    description: 'Platform admin login → list applications',
    steps: [
      ScenarioStep(
        id: 'login-admin',
        description: 'Login with admin credentials',
        action: SchematicAction(type: 'auth_login', target: '',
          body: {'email': 'admin@servisgadget.com', 'password': 'admin123'}),
        asserts: [Assertion(type: 'notNull', path: 'data.email')],
      ),
      ScenarioStep(
        id: 'list-applications',
        description: 'List pending store applications',
        action: SchematicAction(type: 'invoke', target: 'admin',
          body: {'action': 'applications'}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'notNull', path: 'data'),
        ],
      ),
    ],
  );

  // ─── SCENARIO 3: Edge Function Smoke Tests ───
  // Tests that all edge functions respond (not crash)
  static final _edgeFunctionTests = Scenario(
    id: 'edge-function-tests',
    description: 'Smoke test semua Edge Functions',
    steps: [
      ScenarioStep(
        id: 'test-guest-track',
        description: 'Guest function respond to track action',
        action: SchematicAction(type: 'invoke', target: 'guest',
          body: {'action': 'track', 'order_number': 'TEST', 'phone_number': '08123456789'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
      ScenarioStep(
        id: 'test-store-applications',
        description: 'Store application function responds',
        action: SchematicAction(type: 'invoke', target: 'store-applications',
          body: {'store_name': 'Test', 'applicant_name': 'Test', 'phone_number': '08123456789'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
    ],
  );
}
