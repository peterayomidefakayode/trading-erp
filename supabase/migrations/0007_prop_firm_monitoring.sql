-- Prop-firm programme settings. Existing trading data and owner_id conventions are preserved.
create table if not exists public.prop_firm_programs (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 account_id uuid references public.accounts(id) on delete set null,
 firm_name text not null,
 phase text not null default 'Evaluation',
 start_balance numeric(20,8) not null check(start_balance>0),
 profit_target numeric(12,8) not null default 10 check(profit_target>=0),
 max_daily_loss numeric(12,8) not null default 5 check(max_daily_loss>=0),
 max_total_loss numeric(12,8) not null default 10 check(max_total_loss>=0),
 min_trading_days integer not null default 0 check(min_trading_days>=0),
 start_date date not null default current_date,
 end_date date,
 status text not null default 'active' check(status in ('active','passed','failed','paused')),
 notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.prop_firm_programs enable row level security;
create policy prop_firm_programs_select on public.prop_firm_programs for select to authenticated using(user_id=auth.uid() or public.has_role(auth.uid(),'admin') or public.can_mentor_read(user_id));
create policy prop_firm_programs_insert on public.prop_firm_programs for insert to authenticated with check(user_id=auth.uid() and public.is_approved(auth.uid()));
create policy prop_firm_programs_update on public.prop_firm_programs for update to authenticated using(user_id=auth.uid() and public.is_approved(auth.uid())) with check(user_id=auth.uid() and public.is_approved(auth.uid()));
create policy prop_firm_programs_delete on public.prop_firm_programs for delete to authenticated using(user_id=auth.uid() and public.is_approved(auth.uid()));
create index if not exists prop_firm_programs_user_status_idx on public.prop_firm_programs(user_id,status);

-- Private storage for trade chart screenshots. Paths must begin with the authenticated user's UUID.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('trade-screenshots','trade-screenshots',false,10485760,array['image/png','image/jpeg','image/webp'])
on conflict(id) do nothing;
create policy "Trade screenshot owner upload" on storage.objects for insert to authenticated
with check(bucket_id='trade-screenshots' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "Trade screenshot owner read" on storage.objects for select to authenticated
using(bucket_id='trade-screenshots' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "Trade screenshot owner delete" on storage.objects for delete to authenticated
using(bucket_id='trade-screenshots' and (storage.foldername(name))[1]=auth.uid()::text);

-- Repair broker RLS for installations that applied an earlier draft of 0004.
drop policy if exists brokers_select on public.brokers;
drop policy if exists brokers_insert on public.brokers;
drop policy if exists brokers_update on public.brokers;
drop policy if exists brokers_delete on public.brokers;
create policy brokers_select on public.brokers for select to authenticated
using(owner_id=auth.uid() or public.has_role(auth.uid(),'admin'));
create policy brokers_insert on public.brokers for insert to authenticated
with check(owner_id=auth.uid() and public.is_approved(auth.uid()));
create policy brokers_update on public.brokers for update to authenticated
using(owner_id=auth.uid() and public.is_approved(auth.uid())) with check(owner_id=auth.uid() and public.is_approved(auth.uid()));
create policy brokers_delete on public.brokers for delete to authenticated
using(owner_id=auth.uid() and public.is_approved(auth.uid()));
