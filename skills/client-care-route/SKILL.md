---
name: client-care-route
description: "UC1b: Daily geo-optimized property visit route. Query properties needing visits, send tenant confirmation emails, compile confirmed/unconfirmed route, deliver to manager via WhatsApp at 5pm."
metadata:
  {
    "openclaw":
      {
        "emoji": "🗺️",
      },
  }
---

# Client Care Route Skill

Runs daily (7am cron) to plan property visits and (5pm) deliver the confirmed route to the manager.

## References

- `references/route-template.md` — Output format for confirmed and unconfirmed lists

## Daily Workflow

### Morning Phase (7am — cron trigger)

**Step 1: Query Properties Needing Visits**

```sql
-- Properties needing visits today
SELECT p.property_id, p.address, p.city, p.postalcode, p.status, p.fix,
       t.name AS tenant_name, t.email AS tenant_email, t.phone AS tenant_phone,
       t.lease_start, t.last_rent_adjustment_date,
       MAX(i.timestamp) AS last_contact
FROM properties p
JOIN tenant t ON t.property_id = p.property_id
LEFT JOIN interactions i ON i.tenant_id = t.tenant_id
GROUP BY p.property_id, t.tenant_id
HAVING
  p.status IN ('fix_needed', 'late_payment')
  OR (t.lease_start + interval '11 months') <= CURRENT_DATE  -- lease anniversary approaching
  OR MAX(i.timestamp) < CURRENT_DATE - interval '30 days'  -- no contact in 30 days
ORDER BY p.postalcode;
```

**Step 2: Send Confirmation Emails**

For each property, send a confirmation email via `himalaya`:
```
Subject: Visit Confirmation — [address]
Body:
Hi [tenant name],

Our team is planning to visit [address] on [today's date in DD/MM/YYYY].
Please reply YES to confirm this visit works for you.

Thank you,
[manager name]
```

**Step 3: Log Confirmation Requests**

For each outbound confirmation, insert into interactions:
```sql
INSERT INTO interactions (tenant_id, name, channel, summary, timestamp)
VALUES ('[tenant_id]', '[name]', 'email', 'Sent visit confirmation request for [date]', now());
```

### Evening Phase (5pm or when manager requests route)

**Step 4: Check Replies**

Query interactions for today's confirmation responses:
```sql
SELECT tenant_id, summary FROM interactions
WHERE DATE(timestamp) = CURRENT_DATE
AND channel = 'email'
AND summary ILIKE '%YES%';
```

**Step 5: Compile Route**

- **Confirmed**: Sort by postal code (geographic grouping — similar codes are near each other)
- **Unconfirmed**: Separate list with note "no reply received"

**Step 6: Send Route to Manager**

Format per `references/route-template.md` and send via `wacli`.

## Manual Trigger

Manager can say: "Build today's route" or "Check who confirmed for today's visit"
Respond with current confirmation status and route.

## Notes

- AI sends confirmation requests autonomously (morning phase)
- Manager sees and approves the final confirmed route before any visits
- Unconfirmed tenants should be called by manager, not visited unannounced
- Geo-sorting by postal code: Canadian postal codes group geographically (e.g., M5V → downtown Toronto)
