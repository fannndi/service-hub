import '../core/scenario.dart';
import '../core/action.dart';
import '../core/assertion.dart';

class AllScenarios {
  static List<Scenario> get list => [
    _guestBooking,
    _platformAdmin,
    _dataVerification,
    _completeWorkflow,
  ];

  // ─── SCENARIO 1: Guest Booking Samsung S24 ───
  static final _guestBooking = Scenario(
    id: 'guest-booking',
    description: 'Pelanggan (Budi Santoso) booking perbaikan Samsung S24 secara guest',
    steps: [
      ScenarioStep(
        id: 'create-order',
        description: 'Buat order perbaikan LCD Samsung S24 di TechFix Center',
        action: SchematicAction(
          type: 'invoke', target: 'guest',
          body: {
            'action': 'create-order',
            'store_id': '175ea16e-7128-42c6-b4cd-c021e67f11ef',
            'device_type': 'android', 'brand': 'Samsung', 'device_model': 'Galaxy S24',
            'delivery_method': 'walk_in',
            'customer_name': 'Budi Santoso', 'phone_number': '081298765432',
            'items': [{'service_type': 'screen_replacement', 'complaint': 'LCD retak setelah jatuh, layar tidak merespon sentuhan',
              'sparepart_id': '420e7371-2ece-4a63-988a-7ce1a4a494dc', 'item_price': 1200000}],
          },
        ),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'notNull', path: 'data.order_id'),
          Assertion(type: 'notNull', path: 'data.order_number'),
        ],
      ),
      ScenarioStep(
        id: 'track-order',
        description: 'Cek status order via tracking',
        action: SchematicAction(type: 'invoke', target: 'guest',
          body: {'action': 'track', 'order_number': '{order_number}', 'phone_number': '081298765432'}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'notNull', path: 'data.status'),
        ],
      ),
      ScenarioStep(
        id: 'check-temp-password',
        description: 'Ambil password sementara dari credentials endpoint',
        action: SchematicAction(type: 'invoke', target: 'guest',
          body: {'action': 'credentials', 'order_id': '{order_number}', 'phone_number': '081298765432'}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
        ],
      ),
    ],
  );

  // ─── SCENARIO 2: Platform Admin ───
  static final _platformAdmin = Scenario(
    id: 'platform-admin',
    description: 'Admin platform (admin@servisgadget.com) login dan manage aplikasi toko',
    steps: [
      ScenarioStep(
        id: 'login-platform',
        description: 'Login dengan akun platform admin',
        action: SchematicAction(type: 'auth_login', target: '',
          body: {'email': 'admin@servisgadget.com', 'password': 'admin123'}),
        asserts: [Assertion(type: 'notNull', path: 'data.email')],
      ),
      ScenarioStep(
        id: 'list-store-apps',
        description: 'Lihat daftar aplikasi pendaftaran toko yang masuk',
        action: SchematicAction(type: 'invoke', target: 'admin',
          body: {'action': 'applications'}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'notNull', path: 'data'),
        ],
      ),
    ],
  );

  // ─── SCENARIO 3: Data Verification ───
  static final _dataVerification = Scenario(
    id: 'data-verification',
    description: 'Verifikasi data di database via service_role key',
    steps: [
      ScenarioStep(
        id: 'verify-stores',
        description: 'Cek data toko aktif di database',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'stores', 'select': 'id,store_name,is_active', 'limit': 10}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'length_gt', path: 'data', expected: 3),
        ],
      ),
      ScenarioStep(
        id: 'verify-spareparts',
        description: 'Cek data sparepart tersedia',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'spareparts', 'select': 'id,part_name,price::int,qty', 'limit': 10}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'length_gt', path: 'data', expected: 5),
        ],
      ),
      ScenarioStep(
        id: 'verify-users',
        description: 'Cek data pengguna terdaftar',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'users', 'select': 'id,full_name,phone_number', 'limit': 10}),
        asserts: [
          Assertion(type: 'equals', path: 'success', expected: true),
          Assertion(type: 'length_gt', path: 'data', expected: 1),
        ],
      ),
    ],
  );

  // ─── SCENARIO 4: Complete Store Admin Workflow ───
  static final _completeWorkflow = Scenario(
    id: 'complete-workflow',
    description: 'Simulasi lengkap — store admin Budi menerima device, diagnosa, repair, hingga selesai',
    steps: [
      ScenarioStep(
        id: 'login-store-admin',
        description: 'Login sebagai store admin Budi (TechFix Center)',
        action: SchematicAction(type: 'auth_login', target: '',
          body: {'email': '6281111111@store.servisgadget.com', 'password': 'admin123'}),
        asserts: [Assertion(type: 'notNull', path: 'data.email')],
      ),
      ScenarioStep(
        id: 'receive-device',
        description: 'Terima device dari customer (waiting_device → device_received)',
        action: SchematicAction(type: 'invoke', target: 'orders',
          body: {'action': 'status', 'order_id': 'a47a6bc7-15e6-45b9-8357-9c55b6f4ddcc', 'status': 'device_received'}),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
      ScenarioStep(
        id: 'set-diagnosing',
        description: 'Set status diagnosing (device_received → diagnosing)',
        action: SchematicAction(type: 'invoke', target: 'orders',
          body: {'action': 'status', 'order_id': 'a47a6bc7-15e6-45b9-8357-9c55b6f4ddcc', 'status': 'diagnosing'}),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
      ScenarioStep(
        id: 'submit-diagnosis',
        description: 'Submit diagnosis hasil pemeriksaan',
        action: SchematicAction(type: 'invoke', target: 'orders',
          body: {'action': 'diagnosis', 'order_id': 'a47a6bc7-15e6-45b9-8357-9c55b6f4ddcc',
            'diagnosis_note': 'LCD retak total, perlu diganti dengan Samsung original. Tidak ada kerusakan lain.',
            'service_fee': 50000,
            'items': [{'id': 'item_1', 'sparepart_id': '420e7371-2ece-4a63-988a-7ce1a4a494dc', 'final_item_price': 1200000}]}),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
      ScenarioStep(
        id: 'verify-db-state',
        description: 'Verifikasi data order di database',
        action: SchematicAction(type: 'admin_table', target: '',
          body: {'table': 'service_orders', 'select': 'id,order_number,status',
            'limit': 5}),
        asserts: [Assertion(type: 'equals', path: 'success', expected: true)],
      ),
    ],
  );
}
