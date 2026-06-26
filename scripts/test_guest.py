import requests, json

ANON_KEY = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
H = {'apikey': ANON_KEY, 'Authorization': 'Bearer ' + ANON_KEY, 'Content-Type': 'application/json'}
EF = 'https://eboplbemgtvmviwhdlfa.supabase.co/functions/v1/guest'

# 1. Create guest order (new account)
r = requests.post(EF, headers=H, json={
    'action': 'create-order', 'store_id': 'a0000001-0000-0000-0000-000000000001',
    'device_type': 'android', 'brand': 'Samsung', 'device_model': 'S24',
    'delivery_method': 'walk_in', 'customer_name': 'Fresh Guest',
    'phone_number': '087711110001',
    'items': [{'service_type': 'battery_replacement', 'complaint': 'Battery drains fast', 'item_price': 350000}],
})
d = r.json()
print('1. CREATE ORDER:', 'SUCCESS' if d.get('success') else 'FAIL')
if d.get('success'):
    data = d['data']
    print(f'   Order: {data["order_number"]}')
    print(f'   New customer: {data["is_new_customer"]}')
    print(f'   Temp password: {data.get("temp_password")}')
    oid, on = data['order_id'], data['order_number']

    # 2. Track
    r2 = requests.post(EF, headers=H, json={'action': 'track', 'order_number': on, 'phone_number': '087711110001'})
    d2 = r2.json()
    print('2. TRACK:', 'SUCCESS' if d2.get('success') else 'FAIL')
    if d2.get('success'):
        print(f'   Status: {d2["data"]["status"]}')

    # 3. Credentials
    r3 = requests.post(EF, headers=H, json={'action': 'credentials', 'order_id': oid, 'phone_number': '087711110001'})
    d3 = r3.json()
    print('3. CREDENTIALS:', 'SUCCESS' if d3.get('success') else 'FAIL')
    if d3.get('success'):
        print(f'   hasCredential: {d3["data"]["has_credential"]}, isActivated: {d3["data"]["is_activated"]}')

# 4. Verify DB state
BASE = 'https://eboplbemgtvmviwhdlfa.supabase.co/rest/v1'
r4 = requests.get(BASE + '/users?select=id,full_name,phone_number,account_status&order=created_at.desc&limit=5', headers=H)
users = r4.json()
print('\n4. DB USERS:')
for u in users[:3]:
    print(f'   {u["full_name"]} ({u["phone_number"]}) - {u["account_status"]}')

r5 = requests.get(BASE + '/service_orders?select=order_number,status&order=created_at.desc&limit=5', headers=H)
print('5. DB ORDERS:')
for o in r5.json()[:3]:
    print(f'   {o["order_number"]} - {o["status"]}')

r6 = requests.get(BASE + '/notifications?select=title,role,type&order=created_at.desc&limit=5', headers=H)
print('6. DB NOTIFICATIONS:')
for n in r6.json()[:5]:
    print(f'   [{n["role"]}] {n["title"]} ({n["type"]})')
