const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- Add fcm_token column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
`;

async function addFcmTokenColumn() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('fcm_token column added successfully!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

addFcmTokenColumn();
