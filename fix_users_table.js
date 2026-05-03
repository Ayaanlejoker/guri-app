const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- 1. Add email and registered_by columns to public.users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS registered_by UUID REFERENCES public.users(id);

-- 2. Sync emails from auth.users to public.users for existing records
UPDATE public.users u
SET email = a.email
FROM auth.users a
WHERE u.id = a.id AND u.email IS NULL;

-- 3. Update the handle_new_user trigger function to include email
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, role, first_name, email, created_at, updated_at)
  VALUES (new.id, 'user', split_part(new.email, '@', 1), new.email, now(), now());
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-grant permissions (just in case)
GRANT ALL ON public.users TO postgres;
GRANT ALL ON public.users TO service_role;
GRANT SELECT, UPDATE, INSERT ON public.users TO authenticated;
`;

async function fixUsersTable() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Users table fixed: email column added, trigger updated, and emails synced!');
  } catch(e) {
    console.error('Error fixing users table:', e);
  } finally {
    await client.end();
  }
}

fixUsersTable();
