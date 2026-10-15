-- REHLA starter schema for Supabase/PostgreSQL.
-- Review and tighten policies before accepting real orders. Never expose service_role keys in the browser.
create extension if not exists pgcrypto;
create type public.app_role as enum ('customer','merchant','courier','admin');
create type public.order_status as enum ('new','accepted','preparing','ready','assigned','on_the_way','delivered','cancelled');
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text not null default '',
  role public.app_role not null default 'customer',
  area text not null default 'كفر الشيخ',
  address text not null default '',
  created_at timestamptz not null default now()
);
create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  name text not null,
  category text not null,
  description text not null default '',
  logo_url text,
  phone text not null default '',
  address text not null default '',
  area text not null default 'كفر الشيخ',
  delivery_fee numeric(10,2) not null default 12 check(delivery_fee >= 0),
  minimum_order numeric(10,2) not null default 0 check(minimum_order >= 0),
  estimated_delivery text not null default '30–45 دقيقة',
  is_approved boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null,
  description text not null default '',
  image_url text,
  price numeric(10,2) not null check(price >= 0),
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.couriers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete cascade,
  employee_code text unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number bigint generated always as identity unique,
  customer_id uuid references public.profiles(id) on delete set null,
  shop_id uuid not null references public.shops(id),
  courier_id uuid references public.couriers(id) on delete set null,
  customer_name text not null,
  customer_phone text not null,
  delivery_area text not null,
  delivery_address text not null,
  customer_notes text not null default '',
  subtotal numeric(10,2) not null check(subtotal >= 0),
  delivery_fee numeric(10,2) not null check(delivery_fee >= 0),
  discount numeric(10,2) not null default 0 check(discount >= 0),
  total numeric(10,2) not null check(total >= 0),
  payment_method text not null default 'cash_on_delivery',
  payment_status text not null default 'pending',
  status public.order_status not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price numeric(10,2) not null check(unit_price >= 0),
  quantity integer not null check(quantity > 0),
  line_total numeric(10,2) not null check(line_total >= 0)
);
create table if not exists public.delivery_zones (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  fee numeric(10,2) not null default 12 check(fee >= 0),
  is_active boolean not null default true
);
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
create table if not exists public.merchant_applications (
  id uuid primary key default gen_random_uuid(),
  owner_name text not null,
  shop_name text not null,
  category text not null,
  phone text not null,
  address text not null,
  notes text not null default '',
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.shops enable row level security;
alter table public.products enable row level security;
alter table public.couriers enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.delivery_zones enable row level security;
alter table public.app_settings enable row level security;
alter table public.merchant_applications enable row level security;

-- Starter read policies only. Mutations/admin/merchant/courier policies and secure order creation
-- should be implemented with verified role checks or server-side Edge Functions before production.
create policy "public can view approved active shops" on public.shops for select using (is_approved = true and is_active = true);
create policy "public can view available products from approved shops" on public.products for select using (is_available = true and exists(select 1 from public.shops s where s.id=shop_id and s.is_approved=true and s.is_active=true));
create policy "public can view active delivery zones" on public.delivery_zones for select using (is_active=true);
create policy "users can read own profile" on public.profiles for select to authenticated using (auth.uid()=id);
create policy "users can update own profile" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);
-- Do not enable public order insertion until server-side validation protects prices, shop IDs, and totals.
