-- Basic database-side preflight gate. Edge Functions should call this before accepting an execution intent.
create or replace function public.evaluate_trade_preflight(
 p_account_id uuid, p_risk_amount numeric, p_rr numeric default null
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid(); r record; v_daily numeric:=0; v_count int:=0; v_open_risk numeric:=0; v_blocked boolean:=false; v_messages jsonb:='[]'::jsonb;
begin
 if v_user is null or not public.is_approved(v_user) then raise exception 'Approved authenticated user required'; end if;
 if not exists(select 1 from public.accounts where id=p_account_id and user_id=v_user and is_active) then raise exception 'Account not accessible'; end if;
 select coalesce(sum(net_pnl),0) into v_daily from public.trades where user_id=v_user and account_id=p_account_id and status='closed' and closed_at>=date_trunc('day',now()) and deleted_at is null;
 select count(*) into v_count from public.trades where user_id=v_user and account_id=p_account_id and opened_at>=date_trunc('day',now()) and status in ('open','closed') and deleted_at is null;
 select coalesce(sum(planned_risk_amount),0) into v_open_risk from public.trades where user_id=v_user and account_id=p_account_id and status='open' and deleted_at is null;
 for r in select * from public.risk_rules where user_id=v_user and enabled and (account_id is null or account_id=p_account_id) loop
  if r.rule_type='max_risk_per_trade' and p_risk_amount>r.numeric_value then
   v_messages:=v_messages||jsonb_build_array(jsonb_build_object('rule',r.rule_type,'limit',r.numeric_value,'actual',p_risk_amount));
   if r.enforcement='block' then v_blocked:=true; end if;
  elsif r.rule_type='max_daily_loss' and v_daily<=-r.numeric_value then
   v_messages:=v_messages||jsonb_build_array(jsonb_build_object('rule',r.rule_type,'daily_pnl',v_daily));
   if r.enforcement='block' then v_blocked:=true; end if;
  elsif r.rule_type='max_trades_per_day' and v_count>=r.numeric_value then
   v_messages:=v_messages||jsonb_build_array(jsonb_build_object('rule',r.rule_type,'count',v_count));
   if r.enforcement='block' then v_blocked:=true; end if;
  elsif r.rule_type='min_rr' and (p_rr is null or p_rr<r.numeric_value) then
   v_messages:=v_messages||jsonb_build_array(jsonb_build_object('rule',r.rule_type,'rr',p_rr));
   if r.enforcement='block' then v_blocked:=true; end if;
  elsif r.rule_type='max_open_risk' and v_open_risk+p_risk_amount>r.numeric_value then
   v_messages:=v_messages||jsonb_build_array(jsonb_build_object('rule',r.rule_type,'open_risk',v_open_risk,'proposed_risk',p_risk_amount));
   if r.enforcement='block' then v_blocked:=true; end if;
  end if;
 end loop;
 return jsonb_build_object('allowed',not v_blocked,'blocked',v_blocked,'daily_pnl',v_daily,'trades_today',v_count,'open_risk',v_open_risk,'violations',v_messages);
end $$;

create or replace view public.trade_performance_summary with (security_invoker=true) as
select user_id, account_id, count(*) filter(where status='closed') as closed_trades,
 count(*) filter(where status='closed' and net_pnl>0) as winners,
 count(*) filter(where status='closed' and net_pnl<0) as losers,
 coalesce(sum(net_pnl) filter(where status='closed'),0) as net_pnl,
 avg(actual_r) filter(where status='closed') as average_r,
 case when count(*) filter(where status='closed')>0 then
  count(*) filter(where status='closed' and net_pnl>0)::numeric/count(*) filter(where status='closed')*100 else null end as win_rate
from public.trades where deleted_at is null group by user_id,account_id;

create index if not exists trades_closed_user_account_idx on public.trades(user_id,account_id,closed_at desc) where status='closed' and deleted_at is null;
create index if not exists rule_violations_user_created_idx on public.rule_violations(user_id,created_at desc);
