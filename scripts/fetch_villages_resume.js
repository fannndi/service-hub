const https = require('https');
const fs = require('fs');
const path = require('path');

const BASE = 'https://www.emsifa.com/api-wilayah-indonesia/api';
const OUT = path.join(__dirname, '..', 'frontend', 'assets', 'data');

if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });

function fetch(url, retries = 3) {
  return new Promise((resolve, reject) => {
    function attempt(n) {
      https.get(url, { timeout: 30000 }, (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          try { resolve(JSON.parse(data)); } catch(e) { reject(e); }
        });
        res.on('error', (e) => {
          if (n > 0) { console.log(`  Retry ${4-n}...`); setTimeout(() => attempt(n-1), 2000); }
          else reject(e);
        });
      }).on('error', (e) => {
        if (n > 0) { console.log(`  Retry ${4-n}...`); setTimeout(() => attempt(n-1), 2000); }
        else reject(e);
      }).on('timeout', () => { reject(new Error('timeout')); });
    }
    attempt(retries);
  });
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function loadExisting(file) {
  const p = path.join(OUT, file);
  if (fs.existsSync(p)) {
    try { return JSON.parse(fs.readFileSync(p, 'utf-8')); } catch(_) { return []; }
  }
  return [];
}

async function main() {
  const villagesFile = 'jateng_villages.json';
  const existing = loadExisting(villagesFile);
  const fetchedIds = new Set(existing.map(v => v.district_id));

  const districts = loadExisting('jateng_districts.json');
  if (districts.length === 0) {
    console.log('Districts file missing - please run full script first');
    return;
  }

  const remaining = districts.filter(d => !fetchedIds.has(d.id));
  console.log(`${existing.length} villages already fetched, ${remaining.length} districts remaining`);

  const villages = [...existing];
  let i = 0;
  for (const district of remaining) {
    try {
      const v = await fetch(`${BASE}/villages/${district.id}.json`);
      villages.push(...v);
      i++;
      if (i % 10 === 0) {
        console.log(`  Progress: ${i}/${remaining.length} (total: ${villages.length} villages)`);
        fs.writeFileSync(path.join(OUT, villagesFile), JSON.stringify(villages));
      }
    } catch (e) {
      console.log(`  FAILED ${district.name}: ${e.message}, saving progress...`);
      fs.writeFileSync(path.join(OUT, villagesFile), JSON.stringify(villages));
    }
    await sleep(500);
  }

  fs.writeFileSync(path.join(OUT, villagesFile), JSON.stringify(villages));
  console.log(`Final villages total: ${villages.length}`);
  console.log('Done!');
}

main().catch(console.error);
