const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://voohzzpoldchogafchip.supabase.co';
const serviceRoleKey = 'sb_secret_7mF1aPKihd3DiC8j8i-zog_zr94sF84';

const supabase = createClient(supabaseUrl, serviceRoleKey);

const properties = [
  {
    title: 'Luxury Villa in Jazeera',
    description: 'Beautiful 5-bedroom villa with ocean view and modern amenities.',
    price_per_month: 2500,
    address: 'Jazeera Beach',
    city: 'Muqdisho',
    bedrooms: 5,
    bathrooms: 4,
    property_type: 'Villa',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=800&q=80'
  },
  {
    title: 'Modern Flat in Hodan',
    description: 'Clean and secure 3-bedroom apartment in the heart of Hodan.',
    price_per_month: 800,
    address: 'Wada-jir Street',
    city: 'Muqdisho',
    bedrooms: 3,
    bathrooms: 2,
    property_type: 'Apartment',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80'
  },
  {
    title: 'Spacious Villa in Masalaha',
    description: 'Large family villa with garden and parking space.',
    price_per_month: 1200,
    address: 'Masalaha District',
    city: 'Hargeysa',
    bedrooms: 6,
    bathrooms: 5,
    property_type: 'Villa',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80'
  },
  {
    title: 'Business Center Office',
    description: 'Prime location office space for startups and companies.',
    price_per_month: 1500,
    address: 'Independence Road',
    city: 'Hargeysa',
    bedrooms: 0,
    bathrooms: 2,
    property_type: 'Office',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80'
  },
  {
    title: 'City View Apartment',
    description: '2-bedroom apartment with great view of Borama city.',
    price_per_month: 400,
    address: 'Main Avenue',
    city: 'Borama',
    bedrooms: 2,
    bathrooms: 1,
    property_type: 'Apartment',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80'
  },
  {
    title: 'Commercial Shop Downtown',
    description: 'Busy street shop perfect for retail business.',
    price_per_month: 600,
    address: 'Market Area',
    city: 'Borama',
    bedrooms: 0,
    bathrooms: 1,
    property_type: 'Shop',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1534452203294-49c8913721b2?auto=format&fit=crop&w=800&q=80'
  },
  {
    title: 'Modern Villa in Garowe',
    description: 'Newly built 4-bedroom villa with solar power.',
    price_per_month: 900,
    address: 'Administrative Zone',
    city: 'Garowe',
    bedrooms: 4,
    bathrooms: 3,
    property_type: 'Villa',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80'
  },
  {
    title: 'Beachfront Apartment',
    description: 'Stunning 3-bedroom apartment near Kismaayo port.',
    price_per_month: 750,
    address: 'Port Road',
    city: 'Kismaayo',
    bedrooms: 3,
    bathrooms: 2,
    property_type: 'Apartment',
    is_available: true,
    thumbnail_url: 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=800&q=80'
  }
];

async function seedProperties() {
  // 1. Get the super admin user
  const { data: admin, error: userError } = await supabase
    .from('users')
    .select('id')
    .eq('role', 'super_admin')
    .limit(1)
    .single();

  if (userError || !admin) {
    console.error('No super admin found. Please check your users table.');
    return;
  }

  const ownerId = admin.id;

  // 2. Insert properties
  for (const prop of properties) {
    const { data, error } = await supabase
      .from('properties')
      .insert([{
        ...prop,
        owner_id: ownerId
      }])
      .select();

    if (error) {
      console.error(`Error inserting ${prop.title}:`, error);
    } else {
      console.log(`Successfully added: ${prop.title}`);
    }
  }
}

seedProperties();
