const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
CREATE TYPE analytics_event_type AS ENUM ('view', 'call_click', 'whatsapp_click');

CREATE TABLE IF NOT EXISTS public.property_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Nullable if guest (though app requires auth)
  event_type analytics_event_type NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Allow anyone to insert analytics data
ALTER TABLE public.property_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to insert analytics" 
ON public.property_analytics FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Only admins/super_admins and property owners can read analytics
CREATE POLICY "Owners and admins can view analytics"
ON public.property_analytics FOR SELECT
USING (
  public.is_admin() OR 
  auth.uid() IN (SELECT owner_id FROM public.properties WHERE id = property_analytics.property_id)
);
`;

async function runAnalyticsSchema() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Analytics schema created successfully!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

runAnalyticsSchema();
