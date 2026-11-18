-- Run in Supabase SQL Editor after the first administrator has registered.
-- The account must already exist in auth.users. No password is created or stored.
do $$
declare v_user_id uuid;
begin
 select id into v_user_id from auth.users where lower(email)=lower('peterayomidefakayode@gmail.com');
 if v_user_id is null then raise exception 'Admin account not found. Register first, then rerun.'; end if;
 update public.profiles set approval_status='approved' where id=v_user_id;
 insert into public.user_roles(user_id,role) values(v_user_id,'admin')
 on conflict(user_id,role) do nothing;
end $$;
