const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- Add is_approved to users table if not exists
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT true;

-- Update existing users
UPDATE public.users SET is_approved = true WHERE is_approved IS NULL;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
`;

async function reloadSchema() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Schema updated and PostgREST notified to reload!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

reloadSchema();
