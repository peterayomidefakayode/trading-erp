-- Security and tenant-integrity hardening for the initial Phase 1-4 schema.
-- Apply after 0005. This migration deliberately does not invent the four
-- default-account names/configuration: those must be confirmed by the product owner.

-- A trader may edit profile preferences, but cannot approve/suspend themselves.
create or replace function public.guard_profile_privileged_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.has_role(auth.uid(), 'admin') then
    if new.approval_status is distinct from old.approval_status then
      raise exception 'Only an administrator may change account approval status'
        using errcode = '42501';
    end if;
    if new.id is distinct from old.id then
      raise exception 'Profile identity cannot be changed'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists profiles_guard_privileged_fields on public.profiles;
create trigger profiles_guard_privileged_fields
before update on public.profiles
for each row execute function public.guard_profile_privileged_fields();

-- Only the party receiving a pending invitation/request may accept it.
-- Either party or an administrator may decline/revoke an existing relationship.
create or replace function public.guard_mentor_relationship_transition()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if new.mentor_id is distinct from old.mentor_id
     or new.trader_id is distinct from old.trader_id
     or new.requested_by is distinct from old.requested_by then
    if not public.has_role(auth.uid(), 'admin') then
      raise exception 'Mentorship participants and requester cannot be changed'
        using errcode = '42501';
    end if;
  end if;

  if new.status = 'active' and old.status <> 'active'
     and not public.has_role(auth.uid(), 'admin')
     and auth.uid() = old.requested_by then
    raise exception 'The invited party must accept the mentorship request'
      using errcode = '42501';
  end if;

  if new.status = 'active' and old.status not in ('pending','active') then
    raise exception 'Only a pending relationship can be activated'
      using errcode = '23514';
  end if;
  return new;
end;
$$;
drop trigger if exists mentor_relationship_transition_guard on public.mentor_relationships;
create trigger mentor_relationship_transition_guard
before update on public.mentor_relationships
for each row execute function public.guard_mentor_relationship_transition();

-- Ensure foreign-key relationships cannot be used to attach another user's
-- broker/account/strategy/trade records to an otherwise owned row.
create or replace function public.enforce_account_broker_owner()
returns trigger language plpgsql set search_path=public as $$
begin
  if not exists (
    select 1 from public.brokers b
    where b.id = new.broker_id and b.owner_id = new.user_id
  ) then
    raise exception 'Broker must belong to the account owner' using errcode='23514';
  end if;
  return new;
end;
$$;
drop trigger if exists accounts_broker_owner_guard on public.accounts;
create trigger accounts_broker_owner_guard before insert or update of broker_id,user_id
on public.accounts for each row execute function public.enforce_account_broker_owner();

create or replace function public.enforce_user_account_parent()
returns trigger language plpgsql set search_path=public as $$
begin
  if tg_table_name = 'account_transactions' then
    if not exists(select 1 from public.accounts a where a.id=new.account_id and a.user_id=new.user_id) then
      raise exception 'Account must belong to record owner' using errcode='23514';
    end if;
  elsif tg_table_name = 'instrument_broker_specs' then
    if not exists(select 1 from public.brokers b where b.id=new.broker_id and b.owner_id=new.user_id) then
      raise exception 'Broker must belong to specification owner' using errcode='23514';
    end if;
  elsif tg_table_name = 'trades' then
    if not exists(select 1 from public.accounts a where a.id=new.account_id and a.user_id=new.user_id) then
      raise exception 'Trade account must belong to trade owner' using errcode='23514';
    end if;
    if new.strategy_id is not null and not exists(
      select 1 from public.strategies s where s.id=new.strategy_id and s.user_id=new.user_id
    ) then
      raise exception 'Strategy must belong to trade owner' using errcode='23514';
    end if;
    if new.strategy_version_id is not null and not exists(
      select 1 from public.strategy_versions sv where sv.id=new.strategy_version_id and sv.user_id=new.user_id
    ) then
      raise exception 'Strategy version must belong to trade owner' using errcode='23514';
    end if;
  elsif tg_table_name = 'plans' then
    if new.account_id is not null and not exists(
      select 1 from public.accounts a where a.id=new.account_id and a.user_id=new.user_id
    ) then
      raise exception 'Plan account must belong to plan owner' using errcode='23514';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists account_transactions_parent_guard on public.account_transactions;
create trigger account_transactions_parent_guard before insert or update of account_id,user_id
on public.account_transactions for each row execute function public.enforce_user_account_parent();
drop trigger if exists instrument_broker_specs_parent_guard on public.instrument_broker_specs;
create trigger instrument_broker_specs_parent_guard before insert or update of broker_id,user_id
on public.instrument_broker_specs for each row execute function public.enforce_user_account_parent();
drop trigger if exists trades_parent_guard on public.trades;
create trigger trades_parent_guard before insert or update of account_id,user_id,strategy_id,strategy_version_id
on public.trades for each row execute function public.enforce_user_account_parent();
drop trigger if exists plans_parent_guard on public.plans;
create trigger plans_parent_guard before insert or update of account_id,user_id
on public.plans for each row execute function public.enforce_user_account_parent();

-- Child rows must point to parent records owned by the same trader.
create or replace function public.enforce_trade_child_owner()
returns trigger language plpgsql set search_path=public as $$
begin
  if not exists(select 1 from public.trades t where t.id=new.trade_id and t.user_id=new.user_id) then
    raise exception 'Trade must belong to child record owner' using errcode='23514';
  end if;
  return new;
end;
$$;
drop trigger if exists timeframe_trade_owner_guard on public.trade_timeframe_analysis;
create trigger timeframe_trade_owner_guard before insert or update of trade_id,user_id
on public.trade_timeframe_analysis for each row execute function public.enforce_trade_child_owner();
drop trigger if exists screenshot_trade_owner_guard on public.trade_screenshots;
create trigger screenshot_trade_owner_guard before insert or update of trade_id,user_id
on public.trade_screenshots for each row execute function public.enforce_trade_child_owner();
drop trigger if exists checklist_result_trade_owner_guard on public.trade_checklist_results;
create trigger checklist_result_trade_owner_guard before insert or update of trade_id,user_id
on public.trade_checklist_results for each row execute function public.enforce_trade_child_owner();

-- Checklist items and strategy versions are also tenant-bound.
create or replace function public.enforce_checklist_item_owner()
returns trigger language plpgsql set search_path=public as $$
begin
  if not exists(select 1 from public.checklist_templates c where c.id=new.template_id and c.user_id=new.user_id) then
    raise exception 'Checklist template must belong to item owner' using errcode='23514';
  end if;
  return new;
end;
$$;
drop trigger if exists checklist_item_template_owner_guard on public.checklist_items;
create trigger checklist_item_template_owner_guard before insert or update of template_id,user_id
on public.checklist_items for each row execute function public.enforce_checklist_item_owner();

create or replace function public.enforce_strategy_version_owner()
returns trigger language plpgsql set search_path=public as $$
begin
  if not exists(select 1 from public.strategies s where s.id=new.strategy_id and s.user_id=new.user_id) then
    raise exception 'Strategy must belong to version owner' using errcode='23514';
  end if;
  return new;
end;
$$;
drop trigger if exists strategy_version_owner_guard on public.strategy_versions;
create trigger strategy_version_owner_guard before insert or update of strategy_id,user_id
on public.strategy_versions for each row execute function public.enforce_strategy_version_owner();

-- Indexes used by ownership checks and common dashboard filters.
create index if not exists mentor_relationships_active_trader_idx
  on public.mentor_relationships(trader_id, mentor_id) where status='active';
create index if not exists account_transactions_account_date_idx
  on public.account_transactions(user_id, account_id, occurred_at desc) where deleted_at is null;
create index if not exists trade_timeframe_analysis_trade_idx
  on public.trade_timeframe_analysis(user_id, trade_id);
create index if not exists trade_screenshots_trade_idx
  on public.trade_screenshots(user_id, trade_id);

create or replace function public.enforce_checklist_result_item_owner()
returns trigger language plpgsql set search_path=public as $$
begin
  if not exists(select 1 from public.checklist_items i where i.id=new.checklist_item_id and i.user_id=new.user_id) then
    raise exception 'Checklist item must belong to result owner' using errcode='23514';
  end if;
  return new;
end;
$$;
drop trigger if exists checklist_result_item_owner_guard on public.trade_checklist_results;
create trigger checklist_result_item_owner_guard before insert or update of checklist_item_id,user_id
on public.trade_checklist_results for each row execute function public.enforce_checklist_result_item_owner();

create or replace function public.enforce_trade_tag_owner()
returns trigger language plpgsql set search_path=public as $$
begin
  if not exists(select 1 from public.trades t where t.id=new.trade_id and t.user_id=new.user_id)
     or not exists(select 1 from public.tags g where g.id=new.tag_id and g.user_id=new.user_id) then
    raise exception 'Trade and tag must belong to trade-tag owner' using errcode='23514';
  end if;
  return new;
end;
$$;
drop trigger if exists trade_tag_owner_guard on public.trade_tags;
create trigger trade_tag_owner_guard before insert or update of trade_id,tag_id,user_id
on public.trade_tags for each row execute function public.enforce_trade_tag_owner();
