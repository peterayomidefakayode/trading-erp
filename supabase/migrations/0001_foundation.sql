-- Trading ERP foundation. Apply with: supabase db push
create extension if not exists pgcrypto;
create type public.app_role as enum ('admin','trader','mentor');
create type public.account_mode as enum ('live','demo','prop');
create type public.asset_class as enum ('forex','commodity','index','stock','crypto','synthetic');
create type public.trade_direction as enum ('long','short');
create type public.trade_status as enum ('planned','pending','open','closed','cancelled','missed','skipped');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text,
 email text,
 approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected','suspended')),
 base_currency char(3) not null default 'USD',
 timezone text not null default 'Africa/Lagos',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.user_roles (
 user_id uuid not null references public.profiles(id) on delete cascade,
 role public.app_role not null,
 granted_by uuid references public.profiles(id),
 created_at timestamptz not null default now(),
 primary key(user_id,role)
);
create table public.mentor_relationships (
 id uuid primary key default gen_random_uuid(),
 mentor_id uuid not null references public.profiles(id) on delete cascade,
 trader_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','active','declined','revoked')),
 requested_by uuid not null references public.profiles(id),
 approved_at timestamptz,
 created_at timestamptz not null default now(),
 unique(mentor_id,trader_id),
 check(mentor_id <> trader_id)
);
create table public.brokers (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id) on delete cascade,
 name text not null,
 website text,
 created_at timestamptz not null default now(),
 unique(owner_id,name)
);
create table public.accounts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 broker_id uuid not null references public.brokers(id) on delete cascade,
 name text not null,
 account_mode public.account_mode not null,
 platform text,
 account_reference text,
 currency char(3) not null default 'USD',
 leverage numeric(12,4),
 starting_balance numeric(20,8) not null default 0 check(starting_balance>=0),
 is_active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(user_id,broker_id,name)
);
create table public.account_transactions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 account_id uuid not null references public.accounts(id) on delete cascade,
 transaction_type text not null check(transaction_type in ('deposit','withdrawal','transfer_in','transfer_out','adjustment','fee')),
 amount numeric(20,8) not null check(amount>0),
 currency char(3) not null,
 occurred_at timestamptz not null default now(),
 reference text,
 notes text,
 deleted_at timestamptz,
 created_at timestamptz not null default now()
);
create index on public.accounts(user_id);
create index on public.account_transactions(user_id,account_id,occurred_at desc);

create table public.instruments (
 id uuid primary key default gen_random_uuid(),
 symbol text not null unique,
 name text not null,
 asset_class public.asset_class not null,
 base_currency char(3),
 quote_currency char(3),
 default_contract_size numeric(24,10),
 default_tick_size numeric(24,12),
 default_tick_value numeric(24,12),
 default_pip_point_size numeric(24,12),
 default_min_volume numeric(24,10),
 default_volume_step numeric(24,10),
 default_max_volume numeric(24,10),
 default_margin_rate numeric(12,8),
 trading_hours jsonb not null default '{}'::jsonb,
 verification_status text not null default 'unverified' check(verification_status in ('unverified','partially_verified','verified')),
 verification_notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.instrument_broker_specs (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 instrument_id uuid not null references public.instruments(id) on delete cascade,
 broker_id uuid not null references public.brokers(id) on delete cascade,
 broker_symbol text not null,
 contract_size numeric(24,10) not null,
 tick_size numeric(24,12) not null,
 tick_value numeric(24,12) not null,
 pip_point_size numeric(24,12),
 min_volume numeric(24,10) not null,
 volume_step numeric(24,10) not null,
 max_volume numeric(24,10) not null,
 margin_rate numeric(12,8),
 quote_to_account_rate numeric(24,12) not null default 1,
 verified boolean not null default false,
 verified_at timestamptz,
 verification_source text,
 created_at timestamptz not null default now(),
 unique(user_id,instrument_id,broker_id),
 check(tick_size>0 and tick_value>0 and min_volume>0 and volume_step>0 and max_volume>=min_volume)
);
create index on public.instrument_broker_specs(user_id,instrument_id);
