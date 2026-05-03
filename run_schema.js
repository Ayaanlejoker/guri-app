const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

async function runSchema() {
  try {
    console.log('Connecting to Supabase PostgreSQL using Pooler...');
    await client.connect();
    
    console.log('Connected! Reading database_schema.sql...');
    const schemaSql = fs.readFileSync(path.join(__dirname, 'database_schema.sql'), 'utf8');
    
    console.log('Executing schema SQL...');
    await client.query(schemaSql);
    
    console.log('Success! The schema has been created successfully.');
  } catch (err) {
    console.error('Error executing schema:', err.message);
  } finally {
    await client.end();
  }
}

runSchema();
