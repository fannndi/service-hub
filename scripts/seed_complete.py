import requests, json

AK = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
BASE = 'https://eboplbemgtvmviwhdlfa.supabase.co'
AUTH = f'{BASE}/auth/v1'
FN = f'{BASE}/functions/v1'
REST = f'{BASE}/rest/v1'

r = requests.post(f'{AUTH}/token?grant_type=password',
    headers={'apikey': AK, 'Content-Type': 'application/json'},
    json={'email': 'admin@servisgadget.com', 'password': 'admin123'})
token = r.json()['access_token']
H = {'apikey': AK, 'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

# CREATE 5 STORES
stores = [
    ('TechFix Center', 'Jl. Merdeka No. 10, Jakarta', '6281111111', 'Budi', '6281111111', 'toko123'),
    ('GadgetCare Plus', 'Jl. Sudirman No. 45, Bandung', '6281111112', 'Siti', '6281111112', 'toko123'),
    ('AppleOnly Service', 'Jl. Thamrin No. 67, Jakarta', '6281111113', 'Rudi', '6281111113', 'toko123'),
    ('Android Masters', 'Jl. Gatot Subroto No. 89, Surabaya', '6281111114', 'Dewi', '6281111114', 'toko123'),
    ('FixPedia', 'Jl. Diponegoro No. 12, Yogyakarta', '6281111115', 'Agus', '6281111115', 'toko123'),
]
sids = {}
print('MEMBUAT TOKO...')
for name, addr, phone, aname, aphone, pwd in stores:
    r2 = requests.post(f'{FN}/admin', headers=H, json={
        'action': 'create-store', 'store_name': name, 'address': addr,
        'store_phone': phone, 'admin_name': aname, 'admin_phone': aphone, 'password': pwd,
    })
    d = r2.json()
    sid = d.get('data', {}).get('store_id')
    sids[name] = sid
    status = 'OK' if sid else f"FAIL: {d.get('error',{}).get('message','?')}"
    print(f'  [{status}] {name} (admin: {aphone} / {pwd})')

# ADD SPAREPARTS
HEAD = {**H, 'Prefer': 'return=minimal'}
all_parts = {
    'TechFix Center': [
        ('Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Original', 1200000, 10),
        ('Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original', 350000, 15),
        ('Samsung', 'S24', 'charging_port', 'Flex Charging Samsung S24', 250000, 12),
        ('Samsung', 'S24', 'camera', 'Kamera Belakang Samsung S24', 800000, 4),
        ('Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 Original', 800000, 8),
        ('Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13', 250000, 10),
    ],
    'GadgetCare Plus': [
        ('Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Garansi 3bln', 1350000, 7),
        ('Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original+', 380000, 12),
        ('Samsung', 'S24', 'camera', 'Kamera Samsung S24 Set', 1200000, 3),
        ('Oppo', 'Reno 11', 'screen_replacement', 'LCD Oppo Reno 11 Original', 900000, 6),
        ('Oppo', 'Reno 11', 'battery_replacement', 'Baterai Oppo Reno 11', 300000, 8),
        ('Oppo', 'Reno 11', 'camera', 'Kamera Oppo Reno 11', 650000, 4),
    ],
    'AppleOnly Service': [
        ('Apple', 'iPhone 15', 'screen_replacement', 'Display iPhone 15 Original', 2000000, 5),
        ('Apple', 'iPhone 15', 'battery_replacement', 'Baterai iPhone 15 Original', 500000, 10),
        ('Apple', 'iPhone 15', 'charging_port', 'Charging Port iPhone 15', 350000, 6),
        ('Apple', 'iPhone 15 Pro', 'battery_replacement', 'Baterai iPhone 15 Pro', 550000, 7),
        ('Apple', 'iPhone 15 Pro', 'camera', 'Kamera iPhone 15 Pro', 1800000, 2),
    ],
    'Android Masters': [
        ('Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 AMOLED', 1100000, 15),
        ('Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 5000mAh', 320000, 20),
        ('Samsung', 'Galaxy A55', 'screen_replacement', 'LCD Galaxy A55 Original', 650000, 10),
        ('Samsung', 'Galaxy A55', 'battery_replacement', 'Baterai Galaxy A55', 280000, 12),
        ('Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 AMOLED', 750000, 8),
        ('Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13 5020mAh', 230000, 15),
        ('Google', 'Pixel 8', 'screen_replacement', 'Display Google Pixel 8', 1400000, 4),
        ('Google', 'Pixel 8', 'battery_replacement', 'Baterai Google Pixel 8', 400000, 6),
    ],
    'FixPedia': [
        ('Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Compatible', 950000, 3),
        ('Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24', 300000, 5),
        ('Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13', 700000, 2),
        ('Oppo', 'Reno 11', 'charging_port', 'Charging Port Oppo Reno 11', 160000, 4),
        ('Google', 'Pixel 8', 'camera', 'Kamera Google Pixel 8', 900000, 1),
    ],
}

total_parts = 0
print('\nMENAMBAH SPAREPART...')
for sname, parts in all_parts.items():
    sid = sids.get(sname)
    if not sid: continue
    count = 0
    for brand, model, ptype, pname, price, qty in parts:
        r3 = requests.post(f'{REST}/spareparts', headers=HEAD, json={
            'store_id': sid, 'brand': brand, 'device_model': model,
            'part_type': ptype, 'part_name': pname, 'price': price,
            'qty': qty, 'qty_reserved': 0, 'status': 'available',
        })
        if r3.status_code == 201: count += 1
    total_parts += count
    print(f'  {sname}: {count} sparepart')

# VERIFY
print(f'\nVERIFIKASI...')
r4 = requests.get(f'{REST}/stores?select=id,store_name', headers=H)
stores_db = r4.json()
r5 = requests.get(f'{REST}/spareparts?select=id,brand,device_model,part_name', headers=H)
parts_db = r5.json()
print(f'  Stores: {len(stores_db)}')
print(f'  Spareparts: {len(parts_db)}')
print(f'\nSELESAI. Semua data via API.')
