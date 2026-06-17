const https = require('https');
const fs = require('fs');
const path = require('path');

const BASE = 'https://www.emsifa.com/api-wilayah-indonesia/api';
const OUT = path.join(__dirname, '..', 'frontend', 'assets', 'data');

if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve(JSON.parse(data)));
      res.on('error', reject);
    });
  });
}

async function main() {
  // Provinces
  const provinces = await fetch(`${BASE}/provinces.json`);
  fs.writeFileSync(path.join(OUT, 'provinces.json'), JSON.stringify(provinces));
  console.log(`Provinces: ${provinces.length}`);

  // Cities for Jawa Tengah (33)
  const cities = await fetch(`${BASE}/regencies/33.json`);
  fs.writeFileSync(path.join(OUT, 'jateng_cities.json'), JSON.stringify(cities));
  console.log(`Cities: ${cities.length}`);

  // Districts for each city
  const districts = [];
  for (const city of cities) {
    const d = await fetch(`${BASE}/districts/${city.id}.json`);
    districts.push(...d);
    console.log(`  ${city.name}: ${d.length} districts`);
  }
  fs.writeFileSync(path.join(OUT, 'jateng_districts.json'), JSON.stringify(districts));
  console.log(`Districts total: ${districts.length}`);

  // Villages for each district
  const villages = [];
  let i = 0;
  for (const district of districts) {
    const v = await fetch(`${BASE}/villages/${district.id}.json`);
    villages.push(...v);
    i++;
    if (i % 50 === 0) console.log(`  Villages progress: ${i}/${districts.length}`);
  }
  fs.writeFileSync(path.join(OUT, 'jateng_villages.json'), JSON.stringify(villages));
  console.log(`Villages total: ${villages.length}`);
  console.log('Done!');
}

main().catch(console.error);
