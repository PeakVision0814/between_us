-- The anniversaries migration replaced create_couple_space(text, date) with
-- create_couple_space(text), but CREATE OR REPLACE cannot change a function's
-- argument list. Keeping both overloads makes PostgREST RPC resolution brittle
-- for client.rpc('create_couple_space') with no params.
drop function if exists public.create_couple_space(text, date);

revoke all on function public.create_couple_space(text) from public;
revoke all on function public.create_couple_space(text) from anon;
grant execute on function public.create_couple_space(text) to authenticated;

grant select, insert, update, delete on public.anniversaries to authenticated;

notify pgrst, 'reload schema';
