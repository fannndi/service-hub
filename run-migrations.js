const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const SUPABASE_DB_PASSWORD = process.env.SUPABASE_DB_PASSWORD;
if (!SUPABASE_DB_PASSWORD) { console.error('ERROR: need SUPABASE_DB_PASSWORD env'); process.exit(1); }
const SUPABASE_DB_HOST = process.env.SUPABASE_DB_HOST;
if (!SUPABASE_DB_HOST) { console.error('ERROR: need SUPABASE_DB_HOST env'); process.exit(1); }

const pool = new Pool({
  host: SUPABASE_DB_HOST,
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: SUPABASE_DB_PASSWORD,
  ssl: { rejectUnauthorized: false },
});

const migrationsDir = path.join(__dirname, 'supabase', 'migrations');

async function runMigrations() {
  const client = await pool.connect();
  try {
    const files = fs.readdirSync(migrationsDir).filter(f => f.endsWith('.sql')).sort();
    
    // Create migrations tracking table
    await client.query(`
      CREATE TABLE IF NOT EXISTS _supabase_migrations (
        version TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ DEFAULT now()
      )
    `);
    
    for (const file of files) {
      const version = file.replace('.sql', '');
      const { rows } = await client.query(
        'SELECT version FROM _supabase_migrations WHERE version = $1',
        [version]
      );
      
      if (rows.length === 0) {
        console.log(`Applying: ${file}`);
        const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');
        await client.query(sql);
        await client.query(
          'INSERT INTO _supabase_migrations (version) VALUES ($1)',
          [version]
        );
        console.log(`  Applied successfully`);
      } else {
        console.log(`Skipping: ${file} (already applied)`);
      }
    }
    
    console.log('All migrations completed!');
  } catch (err) {
    console.error('Migration failed:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
