import '../core/scenario.dart';
import '../core/action.dart';
import '../core/assertion.dart';

class AllScenarios {
  static List<Scenario> get list => [
    _platformAdmin,
    _guestBooking,
    _dataVerification,
    _edgeFunctionChecks,
  ];

  // ─── SCENARIO 1: Platform Admin ───
  static final _platformAdmin = Scenario(
    id: 'platform-admin',
    description: 'Platform admin login → manage applications via Edge Function',
    steps: [
      ScenarioStep(
        id: 'login-admin',
        description: 'Login dengan admin@servisgadget.com',
        action: SchematicAction(type: 'auth_login', target: '',
          body: {'email': 'admin@servisgadget.com', 'password': 'admin123'}),
        asserts: [Assertion(type: 'notNull', path: 'data.email')],
      ),
      ScenarioStep(
        id: 'list-applications',
        description: 'List store applications via admin edge function',
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
  static final _guestBooking = Scenario(
    id: 'guest-booking',
    description: 'Guest booking via Edge Function — create order',
    steps: [
      ScenarioStep(
        id: 'create-guest-order',
        description: 'Create sparepart order as guest',
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
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'notNull', path: 'data.order_id'),
          Assertion(type: 'notNull', path: 'data.order_number'),
        ],
      ),
    ],
  );

  // ─── SCENARIO 3: Data Verification via Service Role Key ───
  static final _dataVerification = Scenario(
    id: 'data-verification',
    description: 'Verifikasi database — stores, spareparts, users via service_role key',
    steps: [
      ScenarioStep(
        id: 'check-stores',
        description: 'Data toko di database',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'stores', 'select': 'id,store_name,is_active,rating_avg::int', 'limit': 5}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'length_gt', path: 'data', expected: 0),
        ],
      ),
      ScenarioStep(
        id: 'check-spareparts',
        description: 'Data sparepart di database',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'spareparts', 'select': 'id,part_name,price::int,qty', 'limit': 5}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'length_gt', path: 'data', expected: 0),
        ],
      ),
      ScenarioStep(
        id: 'check-users',
        description: 'Data users di database',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'users', 'select': 'id,full_name,phone_number', 'limit': 5}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'length_gt', path: 'data', expected: 0),
        ],
      ),
      ScenarioStep(
        id: 'check-orders',
        description: 'Data service orders',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'service_orders', 'select': 'id,order_number,status', 'limit': 5}),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
      ScenarioStep(
        id: 'check-payments',
        description: 'Data payments',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'payments', 'select': 'id,amount::int,status', 'limit': 5}),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
    ],
  );

  // ─── SCENARIO 4: Edge Function Connectivity ───
  static final _edgeFunctionChecks = Scenario(
    id: 'edge-function-checks',
    description: 'Verifikasi semua Edge Functions reachable',
    steps: [
      ScenarioStep(
        id: 'check-guest',
        description: 'guest.track reachable',
        action: SchematicAction(type: 'invoke', target: 'guest',
          body: {'action': 'track', 'order_number': 'SG-20260702-DIS5XC', 'phone_number': '08123456789'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
      ScenarioStep(
        id: 'check-store-apps',
        description: 'store-applications reachable',
        action: SchematicAction(type: 'invoke', target: 'store-applications',
          body: {'store_name': 'Test Store', 'applicant_name': 'Test', 'phone_number': '08123456789',
            'address': 'Jl. Test No. 1', 'admin_phone': '08123456789'}),
        asserts: [Assertion(type: 'notNull', path: 'success')],
      ),
      ScenarioStep(
        id: 'check-admin-login',
        description: 'admin login',
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
