import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Note: You will need to set these secrets in your Supabase project:
// FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY
// Use: supabase secrets set --env-file .env

serve(async (req) => {
  try {
    const { record } = await req.json()
    
    // 1. Get Notification details
    const { user_id, title, message } = record

    // 2. Initialize Supabase Client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 3. Get user's FCM token
    const { data: user } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', user_id)
      .single()

    if (!user?.fcm_token) {
      return new Response(JSON.stringify({ message: 'No FCM token' }), { status: 200 })
    }

    // 4. Send to FCM (Simplified logic for demonstration)
    // In a real edge function, you'd use a service account to get an OAuth token.
    // For now, this is the logic structure.
    
    console.log(`Sending notification to ${user_id}: ${title}`)

    return new Response(JSON.stringify({ success: true }), { 
      headers: { "Content-Type": "application/json" },
      status: 200 
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
