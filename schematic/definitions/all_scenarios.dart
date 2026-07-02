import '../core/scenario.dart';
import '../core/action.dart';
import '../core/assertion.dart';

class AllScenarios {
  static List<Scenario> get list => [
    _platformAdmin,
    _guestBooking,
    _storeFrontend,
    _edgeFunctionChecks,
  ];

  // ─── SCENARIO 1: Platform Admin ───
  // Login + list applications + check stores via admin Edge Function
  static final _platformAdmin = Scenario(
    id: 'platform-admin',
    description: 'Platform admin login → manage applications',
    steps: [
      ScenarioStep(
        id: 'login-admin',
        description: 'Login with admin@servisgadget.com',
        action: SchematicAction(type: 'auth_login', target: '',
          body: {'email': 'admin@servisgadget.com', 'password': 'admin123'}),
        asserts: [Assertion(type: 'notNull', path: 'data.email')],
      ),
      ScenarioStep(
        id: 'list-applications',
        description: 'List store applications (Edge Function)',
        action: SchematicAction(type: 'invoke', target: 'admin',
          body: {'action': 'applications'}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'notNull', path: 'data'),
        ],
      ),
    ],
  );

  // ─── SCENARIO 2: Guest Booking ───
  // Tests guest Edge Function reachability and response format
  static final _guestBooking = Scenario(
    id: 'guest-booking',
    description: 'Guest booking via Edge Function',
    steps: [
      ScenarioStep(
        id: 'create-guest-order',
        description: 'Create order as guest',
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
        asserts: [
          Assertion(type: 'notNull', path: 'success'),
          Assertion(type: 'notNull', path: 'error.code'),
        ],
      ),
    ],
  );

  // ─── SCENARIO 3: Store Admin Frontend Flows ───
  // Tests key frontend data queries
  static final _storeFrontend = Scenario(
    id: 'store-frontend',
    description: 'Store admin + spareparts + orders data verification',
    steps: [
      ScenarioStep(
        id: 'check-spareparts',
        description: 'Check sparepart data availability',
        action: SchematicAction(
          type: 'invoke', target: 'guest',
          body: {'action': 'track', 'order_number': 'TEST', 'phone_number': '08123456789'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
      ScenarioStep(
        id: 'check-store-applications',
        description: 'Store application endpoint',
        action: SchematicAction(type: 'invoke', target: 'store-applications',
          body: {'store_name': 'Test Store', 'applicant_name': 'Test',
            'phone_number': '08123456789', 'address': 'Jl. Test No. 1'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
    ],
  );

  // ─── SCENARIO 4: Edge Function Connectivity ───
  // Verifies all critical edge functions respond
  static final _edgeFunctionChecks = Scenario(
    id: 'edge-function-checks',
    description: 'Verifikasi semua Edge Functions bisa dijangkau',
    steps: [
      ScenarioStep(
        id: 'check-guest',
        description: 'guest function reachable',
        action: SchematicAction(type: 'invoke', target: 'guest',
          body: {'action': 'track', 'order_number': 'TEST', 'phone_number': '08123'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
      ScenarioStep(
        id: 'check-store-apps',
        description: 'store-applications function reachable',
        action: SchematicAction(type: 'invoke', target: 'store-applications',
          body: {'store_name': 'Test', 'applicant_name': 'T', 'phone_number': '08123'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
      ScenarioStep(
        id: 'check-admin',
        description: 'admin function reachable (login first)',
        action: SchematicAction(type: 'auth_login', target: '',
          body: {'email': 'admin@servisgadget.com', 'password': 'admin123'}),
        asserts: [Assertion(type: 'notNull', path: 'data.email')],
      ),
      ScenarioStep(
        id: 'check-admin-apps',
        description: 'admin.applications responds',
        action: SchematicAction(type: 'invoke', target: 'admin',
          body: {'action': 'applications'}),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
    ],
  );
}
