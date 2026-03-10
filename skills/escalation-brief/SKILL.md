---
name: escalation-brief
description: "UC4: Aggregate full context for a tenant/property into a 3-bullet brief and deliver via WhatsApp to the team."
metadata:
  {
    "openclaw":
      {
        "emoji": "🚨",
      },
  }
---

# Escalation Brief Skill

Aggregates all available context on a tenant or property into a concise 3-bullet escalation brief delivered to the team via WhatsApp.

## References

- `references/brief-template.md` — 3-bullet brief format and examples

## Trigger Phrases

- "escalate [tenant name] to the team"
- "escalate [address] to the team"
- "send escalation for [tenant/address]"
- "brief the team on [tenant/address]"

## Workflow

### Step 1: Identify Subject

Parse trigger for tenant name or property address. Resolve to tenant_id and property_id via `property-db`.

### Step 2: Single-Pass Data Query

```sql
SELECT
  p.address, p.city, p.status, p.fix, p.landlord_name, p.rent,
  t.tenant_id, t.name, t.phone, t.email,
  t.lease_start, t.rent_amount, t.birthday, t.last_rent_adjustment_date, t.note,
  (
    SELECT COALESCE(SUM(m.expense_amount), 0)
    FROM maintenance m WHERE m.property_id = p.property_id
  ) AS total_repair_expenses,
  (
    SELECT COUNT(*) FROM maintenance m
    WHERE m.property_id = p.property_id AND m.status != 'solved'
  ) AS open_issues
FROM tenant t
JOIN properties p ON t.property_id = p.property_id
WHERE t.name ILIKE '%[name]%' OR p.address ILIKE '%[address]%';
```

Then query last 5 interactions:
```sql
SELECT channel, summary, timestamp
FROM interactions
WHERE tenant_id = '[tenant_id]'
ORDER BY timestamp DESC
LIMIT 5;
```

### Step 3: Synthesize Brief

Format per `references/brief-template.md`:

- **Situation**: What is happening RIGHT NOW that requires team attention
- **Context**: Relevant history (tenancy length, payment pattern, past issues, total repairs)
- **Action needed**: Specific decision or approval required from team

### Step 4: Deliver Brief

Send via `wacli` to team WhatsApp group or manager number.

### Step 5: Log Escalation

```sql
INSERT INTO interactions (tenant_id, name, channel, summary, timestamp)
VALUES (
    '[tenant_id]',
    '[tenant_name]',
    'whatsapp',
    'Escalation brief sent to team: [first 100 chars of situation bullet]',
    now()
);
```

## Guidelines

- Keep each bullet to 2-3 sentences maximum
- Include specific numbers (amounts, dates, counts) — never vague
- Action needed must be a specific ask, not "discuss"
- Entire brief should fit in one WhatsApp message (< 1000 chars)
