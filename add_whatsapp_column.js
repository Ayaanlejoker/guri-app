const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- Add whatsapp_number column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS whatsapp_number TEXT;
`;

async function addWhatsAppColumn() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('whatsapp_number column added successfully!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

addWhatsAppColumn();
