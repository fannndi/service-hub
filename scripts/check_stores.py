#!/usr/bin/env python3
"""Check existing stores and create TechFix with new phone"""
import requests, json

ANON_KEY = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
BASE = 'https://eboplbemgtvmviwhdlfa.supabase.co'
AUTH = f'{BASE}/auth/v1'
FN = f'{BASE}/functions/v1'
REST = f'{BASE}/rest/v1'

r = requests.post(f'{AUTH}/token?grant_type=password',
    headers={'apikey': ANON_KEY, 'Content-Type': 'application/json'},
    json={'email': 'admin@servisgadget.com', 'password': 'admin123'})
token = r.json()['access_token']
H = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

# Check existing
r = requests.get(f'{REST}/stores?select=id,store_name,phone_number', headers=H)
existing = r.json()
print(f'Existing stores: {len(existing)}')
for s in existing:
    print(f"  {s['store_name']} ({s['phone_number']})")

# Create TechFix with fresh phone
r2 = requests.post(f'{FN}/admin', headers=H, json={
    'action': 'create-store', 'store_name': 'TechFix Center',
    'address': 'Jl. Merdeka No. 10, Jakarta',
    'store_phone': '6281111116', 'admin_name': 'Budi',
    'admin_phone': '6281111116', 'password': 'toko123',
})
d = r2.json()
print(f"\nCreate TechFix: {'OK' if d.get('success') else 'FAIL'}")
sid = d.get('data', {}).get('store_id')

# Get all stores now
r3 = requests.get(f'{REST}/stores?select=id,store_name,phone_number', headers=H)
print(f'\nTotal stores: {len(r3.json())}')
for s in r3.json():
    print(f"  {s['store_name']} (ID: {s['id'][:8]}...)")
