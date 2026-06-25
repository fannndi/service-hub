/**
 * Push SQL migrations to Supabase via Management API (HTTPS, no IPv6 needed).
 *
 * Usage:
 *   SUPABASE_ACCESS_TOKEN=sbp_xxx node scripts/push-sql.js
 *
 * Get your access token at: https://supabase.com/dashboard/account/tokens
 */

const fs = require('fs');
const path = require('path');

const PROJECT_REF = 'eboplbemgtvmviwhdlfa';
const TOKEN = process.env.SUPABASE_ACCESS_TOKEN;

if (!TOKEN) {
  console.error('Missing SUPABASE_ACCESS_TOKEN');
  console.error('Get one at: https://supabase.com/dashboard/account/tokens');
  process.exit(1);
}

const DRY_RUN = process.env.DRY_RUN === 'true';
const MIGRATIONS_DIR = path.join(__dirname, '..', 'supabase', 'migrations');

async function executeSql(sql) {
  const res = await fetch(`https://api.supabase.com/v1/projects/${PROJECT_REF}/query`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query: sql }),
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(`API error ${res.status}: ${JSON.stringify(data)}`);
  }
  return data;
}

async function main() {
  console.log(`Project: ${PROJECT_REF}`);
  console.log('Pushing SQL migrations via Management API...\n');

  const files = fs.readdirSync(MIGRATIONS_DIR)
    .filter(f => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf-8');
    console.log(`Applying: ${file} (${sql.split('\n').length} lines)`);
    if (DRY_RUN) {
      console.log(`  DRY-RUN — skipped`);
      continue;
    }
    try {
      const result = await executeSql(sql);
      console.log(`  OK`);
    } catch (err) {
      console.error(`  FAILED: ${err.message}`);
      process.exit(1);
    }
  }

  console.log('\nAll migrations applied successfully!');
}

main().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});
