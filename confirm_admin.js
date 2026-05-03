const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://voohzzpoldchogafchip.supabase.co';
const serviceRoleKey = 'sb_secret_7mF1aPKihd3DiC8j8i-zog_zr94sF84';

const supabase = createClient(supabaseUrl, serviceRoleKey);

async function confirmAdmin() {
  const { data: users, error: listError } = await supabase.auth.admin.listUsers();
  
  if (listError) {
    console.error('Error listing users:', listError);
    return;
  }

  const adminUser = users.users.find(u => u.email === 'admin@admin.com');

  if (adminUser) {
    const { data, error } = await supabase.auth.admin.updateUserById(
      adminUser.id,
      { email_confirm: true }
    );
    if (error) console.error('Error confirming admin:', error);
    else console.log('admin@admin.com successfully confirmed!');
  } else {
    console.log('Admin user not found.');
  }
}

confirmAdmin();
