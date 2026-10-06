-- core.clean_text deleted every \r. Some old addresses break their lines with
-- a lone \r (old Mac style), which the old app printed as a new line, so
-- deleting it ran two address lines together. Now \r\n and a lone \r both
-- become \n; everything else is unchanged.
create or replace function core.clean_text(p_value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  cleaned text := p_value;
begin
  cleaned := replace(cleaned, E'\r\n', E'\n');
  cleaned := replace(cleaned, E'\r', E'\n');
  cleaned := regexp_replace(cleaned, '[ \t]+', ' ', 'g');
  cleaned := regexp_replace(cleaned, ' ?\n ?', E'\n', 'g');
  cleaned := btrim(cleaned, E' \n');
  return nullif(cleaned, '');
end;
$$;
