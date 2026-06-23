const https = require('https');
const fs = require('fs');
const path = require('path');

const TOKEN = process.env.SUPABASE_ACCESS_TOKEN;
if (!TOKEN) { console.error('Need SUPABASE_ACCESS_TOKEN env var'); process.exit(1); }

const sql = fs.readFileSync(path.join(__dirname, '..', 'supabase', 'migrations', '003_functions.sql'), 'utf-8');
const b = JSON.stringify({ query: sql });
const o = {
  hostname: 'api.supabase.com',
  path: '/v1/projects/eboplbemgtvmviwhdlfa/database/query',
  method: 'POST',
  headers: { 'Authorization': `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
};
const r = https.request(o, res => {
  let d = '';
  res.on('data', c => d += c);
  res.on('end', () => {
    if (res.statusCode >= 200 && res.statusCode < 300) console.log('OK — functions updated');
    else console.log('ERROR ' + res.statusCode + ': ' + d.slice(0, 500));
  });
});
r.on('error', e => console.error('FATAL:', e.message));
r.write(b);
r.end();
