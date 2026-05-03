const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- 1. Create promotion status enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE promotion_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Add status column to promotions table
ALTER TABLE public.promotions ADD COLUMN IF NOT EXISTS status promotion_status DEFAULT 'pending';

-- 3. Update existing promotions to approved
UPDATE public.promotions SET status = 'approved' WHERE status IS NULL;

-- 4. Update the is_promoted logic in the view to only show approved ones
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
    WHERE pr.property_id = p.id 
    AND pr.is_active = true 
    AND pr.status = 'approved'
    AND pr.start_date <= now() 
    AND pr.end_date >= now()
  ) as is_promoted
FROM public.properties p
WHERE p.is_available = true AND p.is_approved = true;
`;

async function updatePromotions() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Promotions table and view updated successfully with status!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

updatePromotions();
