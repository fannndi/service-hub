with open('supabase/functions/orders/index.ts', encoding='utf-8') as f:
    c = f.read()
c = c.replace(".toLocaleString('id-ID')", '.toLocaleString()')
with open('supabase/functions/orders/index.ts', 'w', encoding='utf-8') as f:
    f.write(c)
print('Done')
