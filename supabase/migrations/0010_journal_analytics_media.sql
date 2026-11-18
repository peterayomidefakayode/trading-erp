-- Add execution-quality, behaviour and Google Drive link fields without removing existing data.
alter table public.trades
  add column if not exists entry_quality text,
  add column if not exists exit_quality text,
  add column if not exists market_condition text,
  add column if not exists mfe_amount numeric(20,8),
  add column if not exists mae_amount numeric(20,8),
  add column if not exists sleep_score smallint check (sleep_score between 1 and 5),
  add column if not exists stress_score smallint check (stress_score between 1 and 5),
  add column if not exists distraction_level smallint check (distraction_level between 0 and 5),
  add column if not exists correlated_exposure_group text,
  add column if not exists before_screenshot_url text,
  add column if not exists entry_screenshot_url text,
  add column if not exists after_screenshot_url text;

alter table public.plans
  add column if not exists screenshot_url text,
  add column if not exists image_url text;

alter table public.journal_entries
  add column if not exists image_url text,
  add column if not exists sleep_score smallint check (sleep_score between 1 and 5),
  add column if not exists stress_score smallint check (stress_score between 1 and 5),
  add column if not exists distraction_level smallint check (distraction_level between 0 and 5);

alter table public.strategies
  add column if not exists examples_url text;

create index if not exists trades_user_closed_at_idx on public.trades(user_id, closed_at) where status='closed' and deleted_at is null;

alter table public.trade_screenshots
  add column if not exists external_url text;

-- Refresh the API's cached schema so the newly added fields are immediately visible.
notify pgrst, 'reload schema';
