#!/usr/bin/env python3
"""Simulasi lengkap: buat toko + sparepart via API (bukan SQL)"""
import requests, json, secrets, string, time
pw = lambda: ''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(8))

ANON_KEY = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
BASE = 'https://eboplbemgtvmviwhdlfa.supabase.co'
AUTH = f'{BASE}/auth/v1'
FN = f'{BASE}/functions/v1'
REST = f'{BASE}/rest/v1'

# Login platform admin
r = requests.post(f'{AUTH}/token?grant_type=password',
    headers={'apikey': ANON_KEY, 'Content-Type': 'application/json'},
    json={'email': 'admin@servisgadget.com', 'password': 'admin123'})
token = r.json()['access_token']
H = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
HEAD = {'apikey': ANON_KEY, 'Authorization': f'Bearer {token}', 'Content-Type': 'application/json', 'Prefer': 'return=representation'}

def step(n, msg): print(f'\n{n}. {msg}')

# ─── 1. CREATE STORES ───
step(1, 'Buat 5 toko via admin EF')
stores = [
    ('TechFix Center', 'Jl. Merdeka No. 10, Jakarta', '6281111111', 'Budi', '6281111111', 'toko123'),
    ('GadgetCare Plus', 'Jl. Sudirman No. 45, Bandung', '6281111112', 'Siti', '6281111112', 'toko123'),
    ('AppleOnly Service', 'Jl. Thamrin No. 67, Jakarta', '6281111113', 'Rudi', '6281111113', 'toko123'),
    ('Android Masters', 'Jl. Gatot Subroto No. 89, Surabaya', '6281111114', 'Dewi', '6281111114', 'toko123'),
    ('FixPedia', 'Jl. Diponegoro No. 12, Yogyakarta', '6281111115', 'Agus', '6281111115', 'toko123'),
]
store_ids = []
for name, addr, phone, admin_name, admin_phone, pwd in stores:
    r2 = requests.post(f'{FN}/admin', headers=H, json={
        'action': 'create-store', 'store_name': name, 'address': addr,
        'store_phone': phone, 'admin_name': admin_name, 'admin_phone': admin_phone, 'password': pwd,
    })
    d = r2.json()
    sid = d.get('data', {}).get('store_id')
    store_ids.append(sid)
    print(f'  [{"OK" if sid else "FAIL"}] {name} (admin: {admin_phone} / {pwd})')

# ─── 2. SPAREPARTS ───
step(2, f'Tambah sparepart ke tiap toko via Supabase REST API')

spareparts = [
    # TechFix Center: Samsung + Xiaomi
    ('a0000001-0000-0000-0000-000000000001', store_ids[0], 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Original', 1200000, 10),
    ('a0000001-0000-0000-0000-000000000001', store_ids[0], 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original', 350000, 15),
    ('a0000001-0000-0000-0000-000000000001', store_ids[0], 'Samsung', 'S24', 'charging_port', 'Flex Charging Samsung S24', 250000, 12),
    ('a0000001-0000-0000-0000-000000000001', store_ids[0], 'Samsung', 'S24', 'camera', 'Kamera Belakang Samsung S24', 800000, 4),
    ('a0000001-0000-0000-0000-000000000001', store_ids[0], 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 Original', 800000, 8),
    ('a0000001-0000-0000-0000-000000000001', store_ids[0], 'Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13', 250000, 10),
    ('a0000001-0000-0000-0000-000000000001', store_ids[0], 'Xiaomi', 'Redmi Note 13', 'charging_port', 'Flex Charging Redmi Note 13', 180000, 6),

    # GadgetCare Plus: Samsung + Oppo
    ('a0000001-0000-0000-0000-000000000002', store_ids[1], 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Garansi 3bln', 1350000, 7),
    ('a0000001-0000-0000-0000-000000000002', store_ids[1], 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original+', 380000, 12),
    ('a0000001-0000-0000-0000-000000000002', store_ids[1], 'Samsung', 'S24', 'camera', 'Kamera Samsung S24 Set', 1200000, 3),
    ('a0000001-0000-0000-0000-000000000002', store_ids[1], 'Oppo', 'Reno 11', 'screen_replacement', 'LCD Oppo Reno 11 Original', 900000, 6),
    ('a0000001-0000-0000-0000-000000000002', store_ids[1], 'Oppo', 'Reno 11', 'battery_replacement', 'Baterai Oppo Reno 11', 300000, 8),
    ('a0000001-0000-0000-0000-000000000002', store_ids[1], 'Oppo', 'Reno 11', 'camera', 'Kamera Oppo Reno 11', 650000, 4),

    # AppleOnly: iPhone only
    ('a0000001-0000-0000-0000-000000000003', store_ids[2], 'Apple', 'iPhone 15', 'screen_replacement', 'Display iPhone 15 Original', 2000000, 5),
    ('a0000001-0000-0000-0000-000000000003', store_ids[2], 'Apple', 'iPhone 15', 'battery_replacement', 'Baterai iPhone 15 Original', 500000, 10),
    ('a0000001-0000-0000-0000-000000000003', store_ids[2], 'Apple', 'iPhone 15', 'charging_port', 'Charging Port iPhone 15', 350000, 6),
    ('a0000001-0000-0000-0000-000000000003', store_ids[2], 'Apple', 'iPhone 15 Pro', 'battery_replacement', 'Baterai iPhone 15 Pro', 550000, 7),
    ('a0000001-0000-0000-0000-000000000003', store_ids[2], 'Apple', 'iPhone 15 Pro', 'camera', 'Kamera iPhone 15 Pro', 1800000, 2),

    # Android Masters: Samsung + Xiaomi + Google
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 AMOLED', 1100000, 15),
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 5000mAh', 320000, 20),
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Samsung', 'Galaxy A55', 'screen_replacement', 'LCD Galaxy A55 Original', 650000, 10),
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Samsung', 'Galaxy A55', 'battery_replacement', 'Baterai Galaxy A55', 280000, 12),
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 AMOLED', 750000, 8),
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13 5020mAh', 230000, 15),
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Google', 'Pixel 8', 'screen_replacement', 'Display Google Pixel 8', 1400000, 4),
    ('a0000001-0000-0000-0000-000000000004', store_ids[3], 'Google', 'Pixel 8', 'battery_replacement', 'Baterai Google Pixel 8', 400000, 6),

    # FixPedia: all brands limited stock
    ('a0000001-0000-0000-0000-000000000005', store_ids[4], 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Compatible', 950000, 3),
    ('a0000001-0000-0000-0000-000000000005', store_ids[4], 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24', 300000, 5),
    ('a0000001-0000-0000-0000-000000000005', store_ids[4], 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13', 700000, 2),
    ('a0000001-0000-0000-0000-000000000005', store_ids[4], 'Oppo', 'Reno 11', 'charging_port', 'Charging Port Oppo Reno 11', 160000, 4),
    ('a0000001-0000-0000-0000-000000000005', store_ids[4], 'Google', 'Pixel 8', 'camera', 'Kamera Google Pixel 8', 900000, 1),
]

total = 0
for fake_id, sid, brand, model, ptype, pname, price, qty in spareparts:
    payload = {
        'store_id': sid, 'brand': brand, 'device_model': model,
        'part_type': ptype, 'part_name': pname, 'price': price,
        'qty': qty, 'qty_reserved': 0, 'status': 'available',
    }
    r3 = requests.post(f'{REST}/spareparts', headers=HEAD, json=payload)
    if r3.status_code == 201:
        total += 1
    elif r3.status_code != 409:  # ignore duplicates
        pass

print(f'  Total sparepart ditambahkan: {total}')

# ─── 3. VERIFY ───
step(3, 'Verifikasi data via API')
r4 = requests.get(f'{REST}/stores?select=id,store_name', headers=H)
stores_db = r4.json()
print(f'  Stores: {len(stores_db)}')

r5 = requests.get(f'{REST}/spareparts?select=id,brand,device_model,part_name,price&order=created_at.asc&limit=5', headers=H)
parts_db = r5.json()
print(f'  Spareparts: {len(parts_db)} (menampilkan 5 pertama)')
for p in parts_db[:5]:
    print(f'    {p["brand"]} {p["device_model"]} - {p["part_name"]}: Rp{p["price"]:,.0f}')

print()
print('✅ SIMULASI SELESAI')
print(f'  {len(stores_db)} toko, {total} sparepart')
print(f'  Semua via API (admin EF + Supabase REST), tanpa SQL dummy.')
