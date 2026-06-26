import requests, json

ANON_KEY = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
H = {'apikey': ANON_KEY, 'Authorization': 'Bearer ' + ANON_KEY, 'Content-Type': 'application/json'}
EF = 'https://eboplbemgtvmviwhdlfa.supabase.co/functions/v1/guest'

# 1. Create order (new guest account)
r = requests.post(EF, headers=H, json={
    'action': 'create-order', 'store_id': 'a0000001-0000-0000-0000-000000000001',
    'device_type': 'android', 'brand': 'Samsung', 'device_model': 'S24',
    'delivery_method': 'walk_in', 'customer_name': 'Demo Guest',
    'phone_number': '089988880001',
    'items': [{'service_type': 'screen_replacement', 'complaint': 'Broken screen', 'item_price': 1200000}],
})
d = r.json()
assert d['success'], f"Create failed: {d}"
data = d['data']
oid, on, pw = data['order_id'], data['order_number'], data.get('temp_password')
print(f'ORDER: {on}')
print(f'PASSWORD: {pw}')

# 2. Track
r2 = requests.post(EF, headers=H, json={'action': 'track', 'order_number': on, 'phone_number': '089988880001'})
assert r2.json()['success']
print(f'TRACK status: {r2.json()["data"]["status"]}')

# 3. Credentials
r3 = requests.post(EF, headers=H, json={'action': 'credentials', 'order_id': oid, 'phone_number': '089988880001'})
c3 = r3.json()
assert c3['success']
print(f'CREDENTIALS: has={c3["data"]["has_credential"]}, activated={c3["data"]["is_activated"]}')

print()
print('ALL GUEST FLOWS: create > track > credentials = WORKING')
print('FULLY SERVERLESS - NO BACKEND SERVER')
