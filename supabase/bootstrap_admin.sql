-- 1. In Supabase Dashboard > Authentication > Users, create and confirm:
--    Email: admin@nesting.local
--    Password: choose a password with at least 6 characters
-- 2. Then run this statement in the SQL Editor once.
update public.profiles
set role = 'admin', display_name = 'Admin', is_active = true
where username = 'admin';
