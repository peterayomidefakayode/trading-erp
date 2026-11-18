-- Enable RLS on every application table, including audit/import support.
do $$ declare t text; begin
 foreach t in array array[
 'profiles','user_roles','mentor_relationships','brokers','accounts','account_transactions',
 'instruments','instrument_broker_specs','strategies','strategy_versions','trades','trade_timeframe_analysis',
 'trade_screenshots','checklist_templates','checklist_items','trade_checklist_results','tags','trade_tags',
 'mistakes','emotions','plans','watchlist_items','alerts','reviews','review_actions','goals','risk_rules',
 'rule_violations','journal_entries','documents','notifications','audit_log','import_batches','import_rows','currency_rates'
 ] loop execute format('alter table public.%I enable row level security',t); end loop;
end $$;

-- Profiles: users read/update their own profile; admin may manage all.
create policy profiles_read_self_admin_mentor on public.profiles for select to authenticated
using(id=auth.uid() or public.has_role(auth.uid(),'admin') or public.can_mentor_read(id));
create policy profiles_update_self on public.profiles for update to authenticated
using(id=auth.uid()) with check(id=auth.uid());
create policy profiles_admin_all on public.profiles for all to authenticated
using(public.has_role(auth.uid(),'admin')) with check(public.has_role(auth.uid(),'admin'));

create policy roles_read_self_admin on public.user_roles for select to authenticated
using(user_id=auth.uid() or public.has_role(auth.uid(),'admin'));
create policy roles_admin_manage on public.user_roles for all to authenticated
using(public.has_role(auth.uid(),'admin')) with check(public.has_role(auth.uid(),'admin'));

create policy mentor_relationship_read_parties on public.mentor_relationships for select to authenticated
using(mentor_id=auth.uid() or trader_id=auth.uid() or public.has_role(auth.uid(),'admin'));
create policy mentor_relationship_request on public.mentor_relationships for insert to authenticated
with check(requested_by=auth.uid() and (mentor_id=auth.uid() or trader_id=auth.uid()));
create policy mentor_relationship_party_update on public.mentor_relationships for update to authenticated
using(mentor_id=auth.uid() or trader_id=auth.uid() or public.has_role(auth.uid(),'admin'))
with check(mentor_id=auth.uid() or trader_id=auth.uid() or public.has_role(auth.uid(),'admin'));

-- Brokers use owner_id (not user_id); keep this policy aligned with the foundation schema.
create policy brokers_select on public.brokers for select to authenticated
using(owner_id=auth.uid() or public.has_role(auth.uid(),'admin'));
create policy brokers_insert on public.brokers for insert to authenticated
with check(owner_id=auth.uid() and public.is_approved(auth.uid()));
create policy brokers_update on public.brokers for update to authenticated
using(owner_id=auth.uid() and public.is_approved(auth.uid())) with check(owner_id=auth.uid() and public.is_approved(auth.uid()));
create policy brokers_delete on public.brokers for delete to authenticated
using(owner_id=auth.uid() and public.is_approved(auth.uid()));

-- All user-owned records: owner, explicitly assigned mentor (read-only), or admin.
do $$ declare t text; begin
 foreach t in array array[
 'accounts','account_transactions','instrument_broker_specs','strategies','strategy_versions','trades',
 'trade_timeframe_analysis','trade_screenshots','checklist_templates','checklist_items','trade_checklist_results',
 'tags','trade_tags','mistakes','emotions','plans','watchlist_items','alerts','reviews','review_actions','goals',
 'risk_rules','rule_violations','journal_entries','documents','notifications','import_batches','import_rows','currency_rates'
 ] loop
  execute format('create policy %I on public.%I for select to authenticated using (user_id=auth.uid() or public.has_role(auth.uid(),''admin'') or public.can_mentor_read(user_id))',t||'_select',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (user_id=auth.uid() and public.is_approved(auth.uid()))',t||'_insert',t);
  execute format('create policy %I on public.%I for update to authenticated using (user_id=auth.uid() and public.is_approved(auth.uid())) with check (user_id=auth.uid() and public.is_approved(auth.uid()))',t||'_update',t);
  execute format('create policy %I on public.%I for delete to authenticated using (user_id=auth.uid() and public.is_approved(auth.uid()))',t||'_delete',t);
 end loop;
end $$;

-- Public instrument catalogue: authenticated users can read; approved users/admins can manage catalogue.
create policy instruments_read_authenticated on public.instruments for select to authenticated using(true);
create policy instruments_admin_write on public.instruments for all to authenticated
using(public.has_role(auth.uid(),'admin')) with check(public.has_role(auth.uid(),'admin'));

-- Audit log is append-only for clients; admin can read. No client update/delete policies.
create policy audit_log_read_admin_or_subject on public.audit_log for select to authenticated
using(public.has_role(auth.uid(),'admin') or actor_id=auth.uid() or subject_user_id=auth.uid());
create policy audit_log_insert_actor on public.audit_log for insert to authenticated
with check(actor_id=auth.uid());
