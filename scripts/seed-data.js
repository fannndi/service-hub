const https = require('https');
const TOKEN = process.env.SUPABASE_ACCESS_TOKEN;
if (!TOKEN) { console.error('ERROR: need SUPABASE_ACCESS_TOKEN'); process.exit(1); }
const SRK = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SRK) { console.error('ERROR: need SUPABASE_SERVICE_ROLE_KEY env'); process.exit(1); }
const REF = 'eboplbemgtvmviwhdlfa';

async function sql(q) {
  const b = JSON.stringify({ query: q });
  const o = { hostname: 'api.supabase.com', path: `/v1/projects/${REF}/database/query`, method: 'POST', headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' } };
  return new Promise((resolve, reject) => {
    const r = https.request(o, res => { let d=''; res.on('data',c=>d+=c); res.on('end',()=>{ if(res.statusCode>=200&&res.statusCode<300) resolve(JSON.parse(d)); else reject(new Error(`HTTP ${res.statusCode}: ${d.slice(0,300)}`)); }); });
    r.on('error', reject); r.write(b); r.end();
  });
}

function rnd(n) { return 100000 + Math.floor(Math.random() * (n - 100000)); }

async function main() {
  // 1. Create 4 stores
  console.log('Creating stores...');
  const stores = [
    ['TechFix Android', '08123456701', 'Jl. Merdeka No.1 Jakarta', true, false],
    ['GadgetCare Android', '08123456702', 'Jl. Sudirman No.45 Bandung', true, false],
    ['iServis Pro', '08123456703', 'Jl. Thamrin No.88 Jakarta', false, true],
    ['AppleFix Center', '08123456704', 'Jl. Bypass No.12 Denpasar', false, true],
  ];

  const storeIds = [];
  for (const [name, phone, addr, android, ios] of stores) {
    const r = await sql(`INSERT INTO stores (store_name, phone_number, address, is_active, config, updated_at) VALUES ('${name}', '${phone}', '${addr}', true, '{"handles_android":${android},"handles_ios":${ios}}', now()) ON CONFLICT DO NOTHING RETURNING id`);
    if (r.length > 0) { storeIds.push(r[0].id); console.log(`  ${name}: ${r[0].id}`); }
  }

  // 2. Bulk spareparts per store
  console.log('\nCreating spareparts...');
  const partTypes = [
    { type: 'screen_replacement', label: 'LCD', basePrice: 350000, range: 300000 },
    { type: 'screen_replacement', label: 'Touch Screen', basePrice: 250000, range: 200000 },
    { type: 'battery_replacement', label: 'Baterai', basePrice: 180000, range: 150000 },
    { type: 'charging_port', label: 'Flex Charging', basePrice: 85000, range: 50000 },
    { type: 'camera', label: 'Kamera Belakang', basePrice: 120000, range: 100000 },
  ];

  const allBrands = [
    ['Samsung', ['Galaxy S24', 'Galaxy S23', 'Galaxy A55', 'Galaxy A35', 'Galaxy Z Fold6']],
    ['Xiaomi', ['Redmi Note 13', 'Redmi Note 12', 'Xiaomi 14T', 'POCO X6', 'POCO F6']],
    ['Realme', ['Realme 12 Pro', 'Realme 11', 'Realme C67']],
    ['Oppo', ['Oppo Reno 12', 'Oppo A98', 'Oppo A78']],
    ['Vivo', ['Vivo V40', 'Vivo Y100', 'Vivo X100 Pro']],
    ['Apple', ['iPhone 15', 'iPhone 15 Pro Max', 'iPhone 14', 'iPhone 13']],
    ['Google', ['Pixel 9', 'Pixel 8 Pro', 'Pixel 8']],
    ['OnePlus', ['OnePlus 12', 'OnePlus Nord 4']],
  ];

  const storeConfigs = [
    { android: true, ios: false },
    { android: true, ios: false },
    { android: false, ios: true },
    { android: false, ios: true },
  ];

  for (let i = 0; i < storeIds.length; i++) {
    const storeId = storeIds[i];
    if (!storeId) continue;
    const cfg = storeConfigs[i];

    for (const [brand, models] of allBrands) {
      if (!cfg.ios && brand === 'Apple') continue;
      if (!cfg.android && !['Apple'].includes(brand)) continue;

      const values = [];
      for (const model of models) {
        for (const p of partTypes) {
          values.push(`('${storeId}','${brand}','${model}','${p.type}','${p.label} ${brand} ${model} Original',${rnd(p.basePrice + p.range)},${5+Math.floor(Math.random()*20)},0,'available',now(),now())`);
        }
      }

      if (values.length > 0) {
        const q = `INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status, created_at, updated_at) VALUES ${values.join(',')}`;
        try { await sql(q); }
        catch(e) { console.log(`  WARN: ${brand} ${storeConfigs[i].android?'Android':'iOS'}: ${e.message.split('\n')[0]}`); }
      }
    }
    console.log(`  Spareparts done for store ${i+1}`);
  }

  // 3. Create customer auth user
  console.log('\nCreating customer...');
  try {
    await fetch(`https://eboplbemgtvmviwhdlfa.supabase.co/auth/v1/admin/users`, {
      method: 'POST',
      headers: { apikey: SRK, Authorization: `Bearer ${SRK}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: '08123456789@customer.servisgadget.com',
        password: 'customer123',
        email_confirm: true,
        user_metadata: { role: 'customer', full_name: 'Budi Santoso' },
      }),
    });
    console.log('  Customer created: 08123456789 / customer123');
  } catch(e) { console.log('  Customer:', e.message); }

  // 4. Create demo order
  console.log('\nCreating demo order...');
  const allStores = await sql('SELECT id, store_name FROM stores LIMIT 1');
  if (allStores.length > 0) {
    const storeId = allStores[0].id;
    const parts = await sql(`SELECT id, part_name, price FROM spareparts WHERE store_id='${storeId}' LIMIT 1`);
    if (parts.length > 0) {
      const p = parts[0];
      const custUser = await sql("SELECT id FROM auth.users WHERE email='08123456789@customer.servisgadget.com'");
      if (custUser.length > 0) {
        const cid = custUser[0].id;
        const orderId = (await sql(`INSERT INTO service_orders (user_id, store_id, order_number, device_type, brand, device_model, delivery_method, status, total_estimasi, updated_at) VALUES ('${cid}','${storeId}','SG-DEMO-001','android','Samsung','Galaxy S24','walk_in','waiting_device',${p.price},now()) RETURNING id`))[0]?.id;
        if (orderId) {
          await sql(`INSERT INTO order_items (order_id, sparepart_id, service_type, complaint, item_price) VALUES ('${orderId}','${p.id}','screen_replacement','Layar retak dari pojok kiri bawah',${p.price})`);
          console.log(`  Order SG-DEMO-001 created`);
        }
      }
    }
  }

  console.log('\n=== SEED COMPLETE ===');
}

main().catch(err => console.error('FATAL:', err.message));
