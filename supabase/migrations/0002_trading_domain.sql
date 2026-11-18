create table public.strategies (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 name text not null, description text, is_archived boolean not null default false, created_at timestamptz not null default now()
);
create table public.strategy_versions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 strategy_id uuid not null references public.strategies(id) on delete cascade, version_number int not null,
 rules jsonb not null default '{}'::jsonb, effective_from date not null default current_date, created_at timestamptz not null default now(),
 unique(strategy_id,version_number)
);
create table public.trades (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 account_id uuid not null references public.accounts(id), instrument_id uuid not null references public.instruments(id),
 direction public.trade_direction not null, order_type text not null default 'market' check(order_type in ('market','limit','stop')),
 status public.trade_status not null default 'planned', opened_at timestamptz, closed_at timestamptz,
 session text, position_size numeric(24,10) not null default 0, entry_price numeric(24,12), stop_loss numeric(24,12),
 take_profit numeric(24,12), exit_price numeric(24,12), planned_risk_amount numeric(20,8), planned_risk_percent numeric(12,8),
 planned_reward_amount numeric(20,8), planned_rr numeric(12,6), gross_pnl numeric(20,8), commission numeric(20,8) not null default 0,
 swap numeric(20,8) not null default 0, fees numeric(20,8) not null default 0, net_pnl numeric(20,8),
 initial_risk_amount numeric(20,8), actual_r numeric(16,8), pips_points numeric(24,10), spread numeric(24,10), slippage numeric(24,10),
 strategy_id uuid references public.strategies(id), strategy_version_id uuid references public.strategy_versions(id),
 setup_type text, confidence smallint check(confidence between 1 and 5), entry_trigger text, confirmation_timeframe text,
 followed_plan text check(followed_plan in ('yes','partial','no')), exit_reason text,
 notes text, lessons text, deleted_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(closed_at is null or opened_at is null or closed_at>=opened_at)
);
create index trades_user_opened_idx on public.trades(user_id,opened_at desc);
create index trades_account_idx on public.trades(account_id);
create index trades_instrument_idx on public.trades(instrument_id);
create index trades_status_idx on public.trades(user_id,status) where deleted_at is null;

create table public.trade_timeframe_analysis (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 trade_id uuid not null references public.trades(id) on delete cascade,
 timeframe text not null check(timeframe in ('D1','4H','1H','15M','5M','1M')),
 bias text not null check(bias in ('bullish','bearish','ranging','unknown')),
 structure_event text check(structure_event in ('BOS','CHoCH','none')),
 key_zone text, aligned boolean, order_block_high numeric(24,12), order_block_low numeric(24,12),
 bos_choch_level numeric(24,12), liquidity_swept boolean, fvg_present boolean, premium_discount text check(premium_discount in ('premium','discount','equilibrium')),
 notes text, created_at timestamptz not null default now(), unique(trade_id,timeframe)
);
create table public.trade_screenshots (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 trade_id uuid not null references public.trades(id) on delete cascade,
 storage_path text not null, stage text not null check(stage in ('before','during','after')),
 tradingview_url text, annotation jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create table public.checklist_templates (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 name text not null, strategy_id uuid references public.strategies(id), is_active boolean not null default true, created_at timestamptz not null default now()
);
create table public.checklist_items (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 template_id uuid not null references public.checklist_templates(id) on delete cascade,
 label text not null, sort_order int not null default 0, required boolean not null default true
);
create table public.trade_checklist_results (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 trade_id uuid not null references public.trades(id) on delete cascade, checklist_item_id uuid not null references public.checklist_items(id),
 checked boolean not null default false, override_reason text, checked_at timestamptz, unique(trade_id,checklist_item_id)
);
create table public.tags (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 name text not null, category text not null default 'general', unique(user_id,name,category)
);
create table public.trade_tags (
 user_id uuid not null references public.profiles(id) on delete cascade, trade_id uuid not null references public.trades(id) on delete cascade,
 tag_id uuid not null references public.tags(id) on delete cascade, primary key(trade_id,tag_id)
);
create table public.mistakes (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 name text not null, description text, unique(user_id,name)
);
create table public.emotions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 name text not null, unique(user_id,name)
);
create table public.plans (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 instrument_id uuid not null references public.instruments(id), account_id uuid references public.accounts(id),
 planned_for timestamptz, status text not null default 'planned' check(status in ('planned','converted','missed','skipped','invalidated')),
 direction public.trade_direction, d1_bias text, h4_bias text, h1_bias text, m15_bias text, zone text, trigger text,
 stop_price numeric(24,12), target_price numeric(24,12), invalidation text, scenarios jsonb not null default '[]'::jsonb,
 notes text, created_at timestamptz not null default now()
);
create table public.watchlist_items (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 instrument_id uuid not null references public.instruments(id), notes text, timeframe_bias jsonb not null default '{}'::jsonb,
 key_levels jsonb not null default '[]'::jsonb, created_at timestamptz not null default now(), unique(user_id,instrument_id)
);
create table public.alerts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 instrument_id uuid not null references public.instruments(id), target_price numeric(24,12), condition text,
 source text default 'manual', notes text, is_active boolean not null default true, created_at timestamptz not null default now()
);
