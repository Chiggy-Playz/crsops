-- Sign-up: core.check_allowed_signup is the auth hook that only lets listed
-- emails make an account.

create function tests.test_only_listed_emails_can_sign_up()
returns setof text
language plpgsql
as $$
begin
  insert into core.allowed_signup_emails (email) values ('Listed@Test.invalid');

  return next is(
    core.check_allowed_signup('{"user": {"email": "listed@test.invalid"}}'),
    '{}'::jsonb, 'a listed email may sign up, ignoring case');
  return next is(
    core.check_allowed_signup('{"user": {"email": "stranger@test.invalid"}}') -> 'error' ->> 'http_code',
    '403', 'any other email is refused');
end;
$$;
