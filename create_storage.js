const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('property_media', 'property_media', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public access to the bucket
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'property_media');

-- Allow authenticated users to upload
CREATE POLICY "Auth Upload" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'property_media' 
  AND auth.role() = 'authenticated'
);

-- Allow users to update/delete their own uploads (optional, but good)
CREATE POLICY "Auth Update" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'property_media' 
  AND auth.uid() = owner
);

CREATE POLICY "Auth Delete" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'property_media' 
  AND auth.uid() = owner
);
`;

async function runStorage() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Storage bucket created and policies added!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

runStorage();
