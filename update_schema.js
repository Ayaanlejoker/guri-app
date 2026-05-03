const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS property_type TEXT DEFAULT 'Apartment';

DROP VIEW IF EXISTS public.property_listings;

CREATE VIEW public.property_listings AS
SELECT 
  p.id,
  p.title,
  p.price_per_month,
  p.address,
  p.city,
  p.property_type,
  p.bedrooms,
  p.bathrooms,
  p.is_available,
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
WHERE p.is_available = true;
`;

async function updateDb() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Database updated successfully with property_type!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

updateDb();
