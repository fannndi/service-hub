#!/usr/bin/env python3
"""
SIMULASI LENGKAP: Service Hub — Fully Serverless
Tiap langkah manual via API. Tanpa data dummy.
"""
import requests, json, time, secrets, string
pw = lambda: ''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(8))

ANON_KEY = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
BASE = 'https://eboplbemgtvmviwhdlfa.supabase.co'
H = {'apikey': ANON_KEY, 'Authorization': f'Bearer {ANON_KEY}', 'Content-Type': 'application/json'}
FN = f'{BASE}/functions/v1'
AUTH = f'{BASE}/auth/v1'
REST = f'{BASE}/rest/v1'

def sep(n='='): print(f'\n{n*60}')

# ─── STEP 1: PLATFORM ADMIN — Login & Buat Toko ───
sep()
print("STEP 1: Platform Admin login & buat toko")
print("(via Flutter app — Admin Platform > login: admin / admin123)")
print()
print("Aksi manual di Flutter:")
print("  1. Buka app -> Admin Platform")
print("  2. Login admin / admin123")
print("  3. Buka tab Stores -> + Buat Toko Baru")
print("  4. Isi: TechFix Center, Jl. Merdeka, 6281111111")
print("  5. Admin: Budi Teknisi, 6281111111, password toko123")
print()
print("=== ATAU via API ===")
store_pw = pw()
admin_pw = pw()

# Call admin EF to create store
resp = requests.post(f'{FN}/admin', headers=H, json={
    'action': 'create-store', 'store_name': 'TechFix Center',
    'address': 'Jl. Merdeka No. 10, Jakarta',
    'store_phone': '6281111111', 'admin_name': 'Budi Teknisi',
    'admin_phone': '6281111111', 'password': admin_pw,
})
print(f"Create store: {resp.status_code}")
r = resp.json()
print(json.dumps(r, indent=2)[:400])
store_id = r.get('data', {}).get('store_id')
admin_id = r.get('data', {}).get('admin_id')

# ─── STEP 2: GUEST — Booking tanpa login ───
sep()
print("STEP 2: Guest booking (tanpa login)")
print("Aksi di Flutter: Buka app -> Ajukan Servis")
print()
print("=== VIA API ===")
items = [{'service_type': 'screen_replacement', 'complaint': 'LCD retak setelah jatuh', 'item_price': 500000}]
resp = requests.post(f'{FN}/guest', headers=H, json={
    'action': 'create-order', 'store_id': store_id,
    'device_type': 'android', 'brand': 'Samsung', 'device_model': 'S24',
    'delivery_method': 'walk_in', 'customer_name': 'Ahmad',
    'phone_number': '081234567890', 'items': items,
})
r = resp.json()
print(f"Create order: {resp.status_code}")
print(json.dumps(r, indent=2)[:500])
order_id = r.get('data', {}).get('order_id')
order_no = r.get('data', {}).get('order_number')
guest_pw = r.get('data', {}).get('temp_password')
print(f">> Order: {order_no}")
print(f">> Password guest: {guest_pw}")

# ─── STEP 3: GUEST — Cek tracking ───
sep()
print("STEP 3: Guest cek tracking")
resp = requests.post(f'{FN}/guest', headers=H, json={
    'action': 'track', 'order_number': order_no, 'phone_number': '081234567890',
})
r = resp.json()
print(f"Track: {resp.status_code}")
print(json.dumps(r, indent=2)[:500])

# ─── STEP 4: STORE ADMIN — Login & Terima Device ───
sep()
print("STEP 4: Store admin login & terima device")
print("Aksi di Flutter: Portal Toko -> login 6281111111 / <password>")
print()
print(f">> Login di Flutter dengan: 6281111111 / {admin_pw}")
print(">> Buka tab Order -> tap order -> Terima Perangkat")
print()
print("=== VIA API (butuh JWT store admin) ===")
print(">> Login store admin & call orders EF action=status status=device_received")
print(">> (manual di Flutter karena butuh session JWT)")

# ─── STEP 5: DATA SAAT INI ───
sep()
print("RINGKASAN")
print(f"Store: TechFix Center ({store_id})")
print(f"Store admin: 6281111111 / {admin_pw}")
print(f"Guest: 081234567890 / {guest_pw}")
print(f"Guest order: {order_no}")
print()
print("Database: CLEAN (no dummy SQL)")
print("Semua data dibuat via Edge Functions.")
print("FULLY SERVERLESS — No backend server.")
