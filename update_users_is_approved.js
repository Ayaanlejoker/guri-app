const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- Add is_approved to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT true;

-- Update existing users to be approved by default
UPDATE public.users SET is_approved = true WHERE is_approved IS NULL;

-- Ensure properties table also has is_approved (just in case)
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT true;
`;

async function updateUsersTable() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Users table updated successfully with is_approved column!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

updateUsersTable();
