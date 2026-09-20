-- core.employee_timeline never selected `amount` or `id` — the payment
-- amount was silently unreachable (not just unrendered), and with no `id`
-- exposed there was no way to target a specific entry for deletion either.
-- amount is null for event-kind rows (no amount concept there), the real
-- value for ledger-kind rows.

drop view if exists core.employee_timeline;

create view core.employee_timeline
with (security_invoker = true)
as
select id, employee_id, event_date as entry_date, 'event'::text as kind, event_type as label, note, null::numeric as amount
from core.employee_events
union all
select id, employee_id, entry_date, 'ledger'::text as kind, entry_type as label, note, amount
from core.employee_ledger_entries
order by entry_date desc;
