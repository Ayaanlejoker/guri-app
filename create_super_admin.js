const { createClient } = require('@supabase/supabase-js');
const { Client } = require('pg');

const supabaseUrl = 'https://voohzzpoldchogafchip.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvb2h6enBvbGRjaG9nYWZjaGlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyOTUzNzUsImV4cCI6MjA5Mjg3MTM3NX0.uapUV0SAblKzY8h3m0gnBsvXyewOG5cyb1peFw9bjkQ';
const supabase = createClient(supabaseUrl, supabaseKey);

const pgConnectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';
const pgClient = new Client({
  connectionString: pgConnectionString,
  ssl: { rejectUnauthorized: false }
});

async function createAdmin() {
  try {
    console.log('Signing up admin@admin.com...');
    const { data, error } = await supabase.auth.signUp({
      email: 'admin@admin.com',
      password: '000111',
    });

    if (error) {
      if (error.message.includes('User already registered')) {
        console.log('User already exists, proceeding to update role...');
      } else {
        throw error;
      }
    }

    console.log('Connecting to postgres...');
    await pgClient.connect();

    console.log('Updating role to super_admin in public.users...');
    // If sign up just happened, the trigger might have already inserted into public.users.
    // Give it a second.
    await new Promise(r => setTimeout(r, 2000));

    await pgClient.query(`
      UPDATE public.users 
      SET role = 'super_admin' 
      WHERE first_name = 'admin' OR id IN (
        SELECT id FROM auth.users WHERE email = 'admin@admin.com'
      );
    `);

    console.log('Super admin created successfully!');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pgClient.end();
  }
}

createAdmin();
