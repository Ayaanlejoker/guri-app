const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- Add super_admin to enum if it doesn't exist
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'super_admin';

-- Add is_approved to properties
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT true;

-- Update the view to only show approved properties (unless admin)
DROP VIEW IF EXISTS public.property_listings;

CREATE VIEW public.property_listings AS
SELECT 
  p.id,
  p.owner_id,
  p.title,
  p.price_per_month,
  p.address,
  p.city,
  p.property_type,
  p.bedrooms,
  p.bathrooms,
  p.is_available,
  p.is_approved,
  p.created_at,
  (
    SELECT media_url 
    FROM public.property_media pm 
    WHERE pm.property_id = p.id AND pm.is_thumbnail = true 
    LIMIT 1
  ) as thumbnail_url,
  EXISTS (
    SELECT 1 FROM public.promotions pr 
    WHERE pr.property_id = p.id AND pr.is_active = true AND pr.start_date <= now() AND pr.end_date >= now()
  ) as is_promoted
FROM public.properties p
WHERE p.is_available = true AND p.is_approved = true;

-- Update is_admin helper to include super_admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND (role = 'admin' OR role = 'super_admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
`;

async function runAdminDb() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Admin schema updated successfully!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

runAdminDb();
