-- Strategy methodology fields. Existing strategies are preserved; new fields are editable by their owner.
alter table public.strategies
  add column if not exists applicable_instruments text not null default '',
  add column if not exists trading_sessions text not null default '',
  add column if not exists timeframes text not null default 'D1, 4H, 1H, 15M, 5M, 1M',
  add column if not exists entry_criteria text not null default '',
  add column if not exists exit_criteria text not null default '',
  add column if not exists stop_loss_rules text not null default '',
  add column if not exists take_profit_rules text not null default '',
  add column if not exists risk_rules text not null default '',
  add column if not exists confirmation_conditions text not null default '',
  add column if not exists examples_notes text not null default '',
  add column if not exists status text not null default 'active' check (status in ('active','archived','draft'));

create index if not exists strategies_user_status_idx on public.strategies(user_id,status);

-- Preserve the existing trade journal while adding the requested SMC and psychology detail.
alter table public.trades
  add column if not exists emotional_state_before text,
  add column if not exists emotional_state_during text,
  add column if not exists emotional_state_after text,
  add column if not exists psychology_flags text not null default '',
  add column if not exists market_structure text,
  add column if not exists liquidity_pools text,
  add column if not exists liquidity_sweep_details text,
  add column if not exists equal_highs_lows text,
  add column if not exists support_resistance text,
  add column if not exists supply_demand text,
  add column if not exists entry_confirmation text,
  add column if not exists invalidation_level text,
  add column if not exists target_liquidity text;

do $$ begin
  alter type public.trade_status add value if not exists 'partially_closed';
exception when duplicate_object then null; end $$;

-- Refresh PostgREST's schema cache so the application can see the new columns.
notify pgrst, 'reload schema';
