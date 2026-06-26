import requests, json

AK = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
BASE = 'https://eboplbemgtvmviwhdlfa.supabase.co'

r = requests.post(f'{BASE}/auth/v1/token?grant_type=password',
    headers={'apikey': AK, 'Content-Type': 'application/json'},
    json={'email': 'admin@servisgadget.com', 'password': 'admin123'})
token = r.json()['access_token']
H = {'apikey': AK, 'Authorization': f'Bearer {token}'}

# Check existing stores
r2 = requests.get(f'{BASE}/rest/v1/stores?select=id,store_name,phone_number', headers=H)
stores = r2.json()
print(f'Existing: {len(stores)} stores')
for s in stores:
    print(f"  {s['store_name']}: {s['phone_number']}")

# Create TechFix with different phone
FN = f'{BASE}/functions/v1'
Hf = {'apikey': AK, 'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
r3 = requests.post(f'{FN}/admin', headers=Hf, json={
    'action': 'create-store', 'store_name': 'TechFix Center',
    'address': 'Jl. Merdeka No. 10, Jakarta',
    'store_phone': '6281111116', 'admin_name': 'Budi',
    'admin_phone': '6281111116', 'password': 'toko123',
})
d = r3.json()
print(f"Create TechFix: {'OK' if d.get('success') else 'FAIL'}")
sid = d.get('data', {}).get('store_id')

if sid:
    # Add spareparts for TechFix via REST
    HEAD = {**H, 'Content-Type': 'application/json', 'Prefer': 'return=minimal'}
    parts = [
        ('Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Original', 1200000, 10),
        ('Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original', 350000, 15),
        ('Samsung', 'S24', 'charging_port', 'Flex Charging Samsung S24', 250000, 12),
        ('Samsung', 'S24', 'camera', 'Kamera Belakang Samsung S24', 800000, 4),
        ('Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 Original', 800000, 8),
        ('Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13', 250000, 10),
    ]
    added = 0
    for brand, model, ptype, pname, price, qty in parts:
        r4 = requests.post(f'{BASE}/rest/v1/spareparts', headers=HEAD, json={
            'store_id': sid, 'brand': brand, 'device_model': model,
            'part_type': ptype, 'part_name': pname, 'price': price,
            'qty': qty, 'qty_reserved': 0, 'status': 'available',
        })
        if r4.status_code == 201: added += 1
    print(f'Spareparts added: {added}')

# Final
r5 = requests.get(f'{BASE}/rest/v1/stores?select=id,store_name', headers=H)
final = r5.json()
print(f'\nTotal stores: {len(final)}')
for s in final:
    print(f"  {s['store_name']}")
