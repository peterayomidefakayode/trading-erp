-- ONE-TIME OWNER BOOTSTRAP
-- Run this in Supabase SQL Editor while signed in as the project owner.
-- Replace the email below with the exact email address used to register your own account.
-- This grants that one account admin rights and approves it. Do not use an email you do not control.
do $$
declare
  v_email text := lower('REPLACE-WITH-YOUR-LOGIN-EMAIL@example.com');
  v_user_id uuid;
begin
  if v_email = 'replace-with-your-login-email@example.com' then
    raise exception 'Replace the example email with the exact email of your own registered account.';
  end if;
  select id into v_user_id from auth.users where lower(email) = v_email;
  if v_user_id is null then
    raise exception 'No registered auth.users account found for %. Register first and retry.', v_email;
  end if;
  update public.profiles set approval_status = 'approved' where id = v_user_id;
  insert into public.user_roles(user_id, role, granted_by)
  values (v_user_id, 'admin', v_user_id)
  on conflict (user_id, role) do nothing;
end $$;

-- Confirm the result. This should show your email, approved, and admin.
select p.email, p.approval_status, r.role
from public.profiles p
left join public.user_roles r on r.user_id = p.id
where lower(p.email) = lower('REPLACE-WITH-YOUR-LOGIN-EMAIL@example.com');
