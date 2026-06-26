import requests, json

ANON_KEY = 'sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
H = {'apikey': ANON_KEY, 'Authorization': 'Bearer ' + ANON_KEY, 'Content-Type': 'application/json'}
EF = 'https://eboplbemgtvmviwhdlfa.supabase.co/functions/v1/guest'

# Use known order number from previous test
on = 'SG-20260626-YDEDLL'
oid = '8cb2dd62-7bf8-4cb5-9824-d6b36ce11e07'

print('TRACK:')
r = requests.post(EF, headers=H, json={'action': 'track', 'order_number': on, 'phone_number': '087711110001'})
print(json.dumps(r.json(), indent=2)[:600])

print('\nCREDENTIALS:')
r2 = requests.post(EF, headers=H, json={'action': 'credentials', 'order_id': oid, 'phone_number': '087711110001'})
print(json.dumps(r2.json(), indent=2)[:600])
