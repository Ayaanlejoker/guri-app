-- ==========================================
-- SUPABASE POSTGRESQL SCHEMA FOR RENTAL APP
-- ==========================================

-- 1. Create an Enum for User Roles
CREATE TYPE user_role AS ENUM ('user', 'admin');

-- ==========================================
-- TABLES DEFINITION
-- ==========================================

-- Users Table (Extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role DEFAULT 'user'::user_role NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone_number TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Properties Table
CREATE TABLE public.properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  price_per_month DECIMAL(10, 2) NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  bedrooms INTEGER NOT NULL DEFAULT 0,
  bathrooms INTEGER NOT NULL DEFAULT 0,
  square_meters DECIMAL(8, 2),
  is_available BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Property Media Table (Photos, Videos)
CREATE TABLE public.property_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
  media_url TEXT NOT NULL,
  is_thumbnail BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Promotions Table
CREATE TABLE public.promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
  discount_percentage DECIMAL(5, 2) NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_properties_owner_id ON public.properties(owner_id);
CREATE INDEX idx_properties_city ON public.properties(city);
CREATE INDEX idx_properties_is_available ON public.properties(is_available);
CREATE INDEX idx_property_media_property_id ON public.property_media(property_id);
CREATE INDEX idx_promotions_property_id ON public.promotions(property_id);
CREATE INDEX idx_promotions_is_active ON public.promotions(is_active);

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

-- Helper function to check if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------
-- Users Policies
-- ------------------------------------------
CREATE POLICY "Users can view their own profile or everyone if admin"
ON public.users FOR SELECT
USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Users can update their own profile or everyone if admin"
ON public.users FOR UPDATE
USING (auth.uid() = id OR public.is_admin())
WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY "Users can insert their own profile"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id OR public.is_admin());

-- ------------------------------------------
-- Properties Policies
-- ------------------------------------------
CREATE POLICY "Anyone can view available properties"
ON public.properties FOR SELECT
USING (is_available = true OR auth.uid() = owner_id OR public.is_admin());

CREATE POLICY "Users can create properties"
ON public.properties FOR INSERT
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own properties"
ON public.properties FOR UPDATE
USING (auth.uid() = owner_id OR public.is_admin())
WITH CHECK (auth.uid() = owner_id OR public.is_admin());

CREATE POLICY "Users can delete their own properties"
ON public.properties FOR DELETE
USING (auth.uid() = owner_id OR public.is_admin());

-- ------------------------------------------
-- Property Media Policies
-- ------------------------------------------
CREATE POLICY "Anyone can view property media for available properties"
ON public.property_media FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.properties 
    WHERE properties.id = property_media.property_id 
    AND (properties.is_available = true OR properties.owner_id = auth.uid() OR public.is_admin())
  )
);

CREATE POLICY "Users can insert media for their own properties"
ON public.property_media FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.properties 
    WHERE properties.id = property_media.property_id 
    AND properties.owner_id = auth.uid()
  ) OR public.is_admin()
);

CREATE POLICY "Users can update media for their own properties"
ON public.property_media FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.properties 
    WHERE properties.id = property_media.property_id 
    AND properties.owner_id = auth.uid()
  ) OR public.is_admin()
);

CREATE POLICY "Users can delete media for their own properties"
ON public.property_media FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.properties 
    WHERE properties.id = property_media.property_id 
    AND properties.owner_id = auth.uid()
  ) OR public.is_admin()
);

-- ------------------------------------------
-- Promotions Policies
-- ------------------------------------------
CREATE POLICY "Anyone can view active promotions"
ON public.promotions FOR SELECT
USING (is_active = true OR public.is_admin() OR EXISTS (
  SELECT 1 FROM public.properties 
  WHERE properties.id = promotions.property_id AND properties.owner_id = auth.uid()
));

CREATE POLICY "Only admins or owners can insert promotions"
ON public.promotions FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.properties 
    WHERE properties.id = promotions.property_id 
    AND properties.owner_id = auth.uid()
  ) OR public.is_admin()
);

CREATE POLICY "Only admins or owners can update promotions"
ON public.promotions FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.properties 
    WHERE properties.id = promotions.property_id 
    AND properties.owner_id = auth.uid()
  ) OR public.is_admin()
);

CREATE POLICY "Only admins or owners can delete promotions"
ON public.promotions FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.properties 
    WHERE properties.id = promotions.property_id 
    AND properties.owner_id = auth.uid()
  ) OR public.is_admin()
);
