const { Client } = require('pg');

const connectionString = 'postgresql://postgres.voohzzpoldchogafchip:Muumin1223%40@aws-1-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

const sql = `
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Allow users to see their own messages (sent or received)
CREATE POLICY "Users can view their own messages"
ON public.messages FOR SELECT
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Allow users to insert messages
CREATE POLICY "Users can insert messages"
ON public.messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);

-- Enable realtime for messages table
alter publication supabase_realtime add table public.messages;
`;

async function runChatDb() {
  try {
    await client.connect();
    await client.query(sql);
    console.log('Messages table and realtime created successfully!');
  } catch(e) {
    console.error(e);
  } finally {
    await client.end();
  }
}

runChatDb();
