-- The `enforce_allowed_signup` trigger (migration 1) rejects disallowed emails by
-- raising a plain Postgres exception. GoTrue can't tell that apart from a genuine
-- DB failure, so it discards our message and reports a generic
-- {"code":"unexpected_failure","message":"Database error saving new user"} to the
-- client instead — the real reason never reaches the app.
--
-- Auth Hooks are the mechanism Supabase provides for exactly this: a function
-- GoTrue calls explicitly and whose returned `error` object it forwards to the
-- client as-is (message + http_code), rather than treating any failure as an
-- opaque internal error. Still a plain plpgsql function reading a plain table —
-- only the wiring (config.toml + the supabase_auth_admin grant below) is
-- Supabase-specific, not the logic itself.

drop trigger if exists enforce_allowed_signup on auth.users;
drop function if exists core.check_allowed_signup();

create function core.check_allowed_signup(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = core, public
as $$
declare
  signup_email text := event -> 'user' ->> 'email';
begin
  if not exists (
    select 1 from core.allowed_signup_emails
    where lower(email) = lower(signup_email)
  ) then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 403,
        'message', 'Sign-up not permitted for this email address.'
      )
    );
  end if;

  return jsonb_build_object();
end;
$$;

-- GoTrue calls this as supabase_auth_admin, not as `authenticated` — and the
-- schema's `alter default privileges ... grant execute ... to authenticated`
-- (migration 3) would otherwise hand every signed-in user execute on this too.
grant execute on function core.check_allowed_signup(jsonb) to supabase_auth_admin;
revoke execute on function core.check_allowed_signup(jsonb) from authenticated, anon, public;
