const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const http = require('http');

// 1. Firebase Admin Setup
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountJson) {
  console.error('FIREBASE_SERVICE_ACCOUNT is missing!');
  process.exit(1);
}
const serviceAccount = JSON.parse(serviceAccountJson);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// 2. Supabase Setup
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// 3. Simple HTTP server for Render Health Check (Mandatory for Web Service)
const port = process.env.PORT || 10000;
http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Worker is running...\n');
}).listen(port, '0.0.0.0', () => {
  console.log(`Health check server listening on port ${port}`);
});

console.log('--- Cloud Notification Worker Started ---');

// 4. Listen for new notifications
supabase
  .channel('public:notifications')
  .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, async (payload) => {
    const notification = payload.new;
    console.log('New notification:', notification.title);
    try {
      const { data: user } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('id', notification.user_id)
        .single();

      if (user?.fcm_token) {
        await admin.messaging().send({
          notification: { title: notification.title, body: notification.message },
          token: user.fcm_token,
        });
        console.log('Push notification sent');
      }
    } catch (error) {
      console.error('Error:', error);
    }
  })
  .subscribe();
