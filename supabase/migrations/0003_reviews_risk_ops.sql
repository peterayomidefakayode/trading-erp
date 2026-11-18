create table public.reviews (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 review_type text not null check(review_type in ('daily','weekly','monthly')), period_start date not null, period_end date not null,
 mood text, sleep_score smallint check(sleep_score between 1 and 5), stress_score smallint check(stress_score between 1 and 5),
 focus_score smallint check(focus_score between 1 and 5), reflection text, created_at timestamptz not null default now(),
 check(period_end>=period_start)
);
create table public.review_actions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 review_id uuid references public.reviews(id) on delete set null, title text not null, description text,
 due_date date, status text not null default 'todo' check(status in ('todo','in_progress','done','cancelled')), created_at timestamptz not null default now()
);
create table public.goals (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 name text not null, metric text not null, target_value numeric(20,8) not null, current_value numeric(20,8) not null default 0,
 period_start date, period_end date, is_active boolean not null default true, created_at timestamptz not null default now()
);
create table public.risk_rules (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 account_id uuid references public.accounts(id) on delete cascade, name text not null,
 rule_type text not null check(rule_type in ('max_risk_per_trade','max_daily_loss','max_weekly_loss','max_trades_per_day','max_consecutive_losses','min_rr','max_open_risk')),
 numeric_value numeric(20,8) not null check(numeric_value>=0), enabled boolean not null default true,
 enforcement text not null default 'block' check(enforcement in ('warn','block')), created_at timestamptz not null default now()
);
create table public.rule_violations (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 account_id uuid references public.accounts(id), trade_id uuid references public.trades(id), risk_rule_id uuid references public.risk_rules(id),
 rule_type text not null, severity text not null check(severity in ('warning','blocked','override')),
 details jsonb not null default '{}'::jsonb, override_reason text, created_at timestamptz not null default now()
);
create table public.journal_entries (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 entry_date date not null default current_date, entry_type text not null default 'note', title text, content text not null,
 mood text, created_at timestamptz not null default now()
);
create table public.documents (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 title text not null, storage_path text not null, mime_type text, tags text[] not null default '{}', created_at timestamptz not null default now()
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 channel text not null default 'in_app', title text not null, body text not null, read_at timestamptz,
 metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create table public.audit_log (
 id bigint generated always as identity primary key, actor_id uuid references public.profiles(id),
 subject_user_id uuid references public.profiles(id), table_name text not null, record_id text not null,
 operation text not null, old_data jsonb, new_data jsonb, reason text, created_at timestamptz not null default now()
);
create table public.import_batches (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 account_id uuid not null references public.accounts(id), source_format text not null check(source_format in ('csv','html')),
 file_name text, status text not null default 'uploaded' check(status in ('uploaded','reviewing','committed','rejected','failed')),
 row_count int not null default 0, created_at timestamptz not null default now()
);
create table public.import_rows (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 batch_id uuid not null references public.import_batches(id) on delete cascade, row_number int not null,
 raw_data jsonb not null, normalized_data jsonb, validation_errors jsonb not null default '[]'::jsonb,
 duplicate_fingerprint text, decision text not null default 'pending' check(decision in ('pending','import','skip')),
 created_at timestamptz not null default now()
);
create table public.currency_rates (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 base_currency char(3) not null, quote_currency char(3) not null, rate numeric(24,12) not null check(rate>0),
 observed_at timestamptz not null, source text, unique(user_id,base_currency,quote_currency,observed_at)
);

-- Helper functions. Role claims are always read from protected database tables.
create or replace function public.has_role(_user uuid, _role public.app_role)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.user_roles where user_id=_user and role=_role); $$;
create or replace function public.is_approved(_user uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=_user and approval_status='approved'); $$;
create or replace function public.can_mentor_read(_trader uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.mentor_relationships mr where mr.trader_id=_trader and mr.mentor_id=auth.uid() and mr.status='active'); $$;

-- Updated timestamp trigger
create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end $$;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger instruments_updated_at before update on public.instruments for each row execute function public.set_updated_at();
create trigger trades_updated_at before update on public.trades for each row execute function public.set_updated_at();

-- Registration creates a pending profile and trader role; admin approval is still required.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public
as $$ begin
 insert into public.profiles(id,email,display_name,approval_status) values(new.id,new.email,coalesce(new.raw_user_meta_data->>'display_name',''),'pending');
 insert into public.user_roles(user_id,role) values(new.id,'trader');
 return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- Admin promotion snippet is in docs/ADMIN_SETUP.sql.
