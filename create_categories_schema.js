const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Allow anyone to view categories
CREATE POLICY "Anyone can view categories"
ON public.categories FOR SELECT
USING (true);

-- Only admins can manage categories
CREATE POLICY "Admins can manage categories"
ON public.categories FOR ALL
USING (public.is_admin());

-- Insert default categories
INSERT INTO public.categories (name) VALUES 
('Apartment'), 
('Villa'), 
('House'), 
('Office'), 
('Shop'), 
('Land')
ON CONFLICT (name) DO NOTHING;
`;

async function runCategoriesDb() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Categories table created successfully!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

runCategoriesDb();
