const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

async function checkMessagesColumns() {
  try {
    await client.connect();
    const res = await client.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'messages'");
    console.log('Columns in messages:', res.rows.map(r => r.column_name).join(', '));
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

checkMessagesColumns();
