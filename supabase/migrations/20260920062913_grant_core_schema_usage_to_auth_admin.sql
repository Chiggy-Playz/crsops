-- GoTrue invokes the before_user_created hook as `supabase_auth_admin`. The
-- previous migration granted that role EXECUTE on the hook function, but not
-- USAGE on the schema it lives in — without schema usage the role can't even
-- resolve `core.check_allowed_signup`, so GoTrue fails with
-- "Error running hook URI: pg-functions://postgres/core/check_allowed_signup"
-- before it ever gets to run the function body.

grant usage on schema core to supabase_auth_admin;
