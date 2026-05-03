const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

// 1. Firebase Admin Setup (Using Environment Variables for security)
// On Render, you will paste the contents of your Service Account JSON into an environment variable
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountJson) {
  console.error('FIREBASE_SERVICE_ACCOUNT environment variable is missing!');
  process.exit(1);
}

const serviceAccount = JSON.parse(serviceAccountJson);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// 2. Supabase Setup
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Use Service Role Key for backend access

if (!supabaseUrl || !supabaseKey) {
  console.error('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing!');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('--- Cloud Notification Worker Started ---');

// 3. Listen for new notifications
supabase
  .channel('public:notifications')
  .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, async (payload) => {
    const notification = payload.new;
    console.log('New notification:', notification.title);

    try {
      // 4. Get receiver's FCM token
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('id', notification.user_id)
        .single();

      if (userError || !user || !user.fcm_token) {
        console.log('No FCM token for user:', notification.user_id);
        return;
      }

      // 5. Send Push Notification
      const message = {
        notification: {
          title: notification.title,
          body: notification.message,
        },
        token: user.fcm_token,
      };

      await admin.messaging().send(message);
      console.log('Push notification sent successfully');
    } catch (error) {
      console.error('Error:', error);
    }
  })
  .subscribe();

// Keep alive
setInterval(() => {}, 1000 * 60 * 60);
