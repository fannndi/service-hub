const https = require('https');
const TOKEN = process.env.SUPABASE_ACCESS_TOKEN;
if (!TOKEN) { console.error('ERROR: SUPABASE_ACCESS_TOKEN env var required'); process.exit(1); }
const PROJECT_REF = process.env.SUPABASE_PROJECT_REF || 'eboplbemgtvmviwhdlfa';
const headers = { 'Authorization': `Bearer ${TOKEN}`, 'Content-Type': 'application/json' };

async function sql(q) {
  const b = JSON.stringify({ query: q });
  const o = { hostname: 'api.supabase.com', path: `/v1/projects/${PROJECT_REF}/database/query`, method: 'POST', headers };
  return new Promise((resolve, reject) => {
    const r = https.request(o, res => { let d=''; res.on('data',c=>d+=c); res.on('end',()=>{ if(res.statusCode>=200&&res.statusCode<300) resolve(d); else reject(new Error(`HTTP ${res.statusCode}: ${d}`)); }); });
    r.on('error', reject); r.write(b); r.end();
  });
}

async function main() {
  // Fix 1: Add gen_random_uuid() default to all id columns that need it
  console.log('Fixing ID defaults...');
  const tables = ['users','store_admins','stores','spareparts','service_orders','order_items','service_tracking','payments','reviews','coupons','disputes','failed_notifications'];
  for (const t of tables) {
    try { await sql(`ALTER TABLE ${t} ALTER COLUMN id SET DEFAULT gen_random_uuid()`); console.log(`  ${t}: OK`); }
    catch(e) { console.log(`  ${t}: ${e.message.split('\n')[0]}`); }
  }

  // Fix 2: Set platform_admins id default too, then seed
  try { await sql(`ALTER TABLE platform_admins ALTER COLUMN id SET DEFAULT gen_random_uuid()`); console.log(`  platform_admins: OK`); } catch(e) {}

  // Fix 3: Seed platform admin
  console.log('\nSeeding platform admin...');
  try {
    await sql(`INSERT INTO platform_admins (username, password_hash, full_name, is_active) VALUES ('admin', '$2a$12$LJ3m4ys3Lg3YOG.xKbY8O.YSLhps/iG5FMbPmIdkHeStY92Ss6qOa', 'Platform Admin', true) ON CONFLICT (username) DO NOTHING`);
    console.log('  OK');
  } catch(e) { console.log(`  ${e.message.split('\n')[0]}`); }

  // Fix 4: Enable RLS on tables
  console.log('\nEnabling RLS on all tables...');
  const rlsTables = ['users','store_admins','stores','spareparts','service_orders','order_items','service_tracking','payments','reviews','coupons','disputes','failed_notifications','platform_admins'];
  for (const t of rlsTables) {
    try { await sql(`ALTER TABLE ${t} ENABLE ROW LEVEL SECURITY`); }
    catch(e) { /* may already be enabled */ }
  }
  console.log('  OK');

  // Fix 5: Apply RLS policies with UUID::text casting
  console.log('\nApplying RLS policies...');
  try {
    await sql(`
      CREATE POLICY anon_stores_select ON stores FOR SELECT TO anon USING (is_active = true);
      CREATE POLICY anon_spareparts_select ON spareparts FOR SELECT TO anon USING (status = 'available');
      CREATE POLICY anon_reviews_select ON reviews FOR SELECT TO anon USING (is_public = true);
    `);
    console.log('  anon policies: OK');
  } catch(e) { console.log(`  anon: ${e.message.split('\n')[0]}`); }

  try {
    await sql(`
      CREATE POLICY customer_orders_select ON service_orders FOR SELECT TO authenticated USING (user_id::text = auth.uid()::text);
      CREATE POLICY customer_orders_insert ON service_orders FOR INSERT TO authenticated WITH CHECK (user_id::text = auth.uid()::text);
      CREATE POLICY customer_orders_update ON service_orders FOR UPDATE TO authenticated USING (user_id::text = auth.uid()::text);
      CREATE POLICY customer_payments_select ON payments FOR SELECT TO authenticated USING (user_id::text = auth.uid()::text);
      CREATE POLICY customer_payments_insert ON payments FOR INSERT TO authenticated WITH CHECK (user_id::text = auth.uid()::text);
      CREATE POLICY customer_reviews_select ON reviews FOR SELECT TO authenticated USING (user_id::text = auth.uid()::text);
      CREATE POLICY customer_reviews_insert ON reviews FOR INSERT TO authenticated WITH CHECK (user_id::text = auth.uid()::text);
      CREATE POLICY customer_coupons_select ON coupons FOR SELECT TO authenticated USING (user_id::text = auth.uid()::text);
      CREATE POLICY customer_disputes_select ON disputes FOR SELECT TO authenticated USING (user_id::text = auth.uid()::text);
      CREATE POLICY customer_disputes_insert ON disputes FOR INSERT TO authenticated WITH CHECK (user_id::text = auth.uid()::text);
      CREATE POLICY customer_users_select ON users FOR SELECT TO authenticated USING (id::text = auth.uid()::text);
      CREATE POLICY customer_users_update ON users FOR UPDATE TO authenticated USING (id::text = auth.uid()::text);
    `);
    console.log('  customer policies: OK');
  } catch(e) { console.log(`  customer: ${e.message.split('\n')[0]}`); }

  try {
    await sql(`
      CREATE POLICY store_admin_orders_select ON service_orders FOR SELECT TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY store_admin_orders_update ON service_orders FOR UPDATE TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY store_admin_spareparts_select ON spareparts FOR SELECT TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY store_admin_spareparts_insert ON spareparts FOR INSERT TO authenticated WITH CHECK (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY store_admin_spareparts_update ON spareparts FOR UPDATE TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY store_admin_payments_select ON payments FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text)));
      CREATE POLICY store_admin_payments_update ON payments FOR UPDATE TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text)));
      CREATE POLICY store_admin_disputes_select ON disputes FOR SELECT TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY store_admin_disputes_update ON disputes FOR UPDATE TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY store_admin_tracking_select ON service_tracking FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text)));
      CREATE POLICY store_admin_tracking_insert ON service_tracking FOR INSERT TO authenticated WITH CHECK (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text)));
      CREATE POLICY store_admin_order_items_select ON order_items FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text)));
      CREATE POLICY store_admin_order_items_update ON order_items FOR UPDATE TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text)));
      CREATE POLICY store_admin_reviews_select ON reviews FOR SELECT TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id::text = auth.uid()::text));
    `);
    console.log('  store admin policies: OK');
  } catch(e) { console.log(`  store_admin: ${e.message.split('\n')[0]}`); }

  try {
    await sql(`
      CREATE POLICY platform_admin_all_stores ON stores FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_users ON users FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_orders ON service_orders FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_spareparts ON spareparts FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_payments ON payments FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_reviews ON reviews FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_disputes ON disputes FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_tracking ON service_tracking FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_coupons ON coupons FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_order_items ON order_items FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_store_admins ON store_admins FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_platform_admins ON platform_admins FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
      CREATE POLICY platform_admin_all_failed_notifications ON failed_notifications FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));
    `);
    console.log('  platform admin policies: OK');
  } catch(e) { console.log(`  platform_admin: ${e.message.split('\n')[0]}`); }

  console.log('\nAll done!');
}

main().catch(err => { console.error('FATAL:', err.message); process.exit(1); });
