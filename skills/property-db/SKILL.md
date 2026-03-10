---
name: property-db
description: "Query and update property management data in Supabase via MCP. Use for all property, tenant, vendor, maintenance, and interaction records."
metadata:
  {
    "openclaw":
      {
        "emoji": "🏠",
      },
  }
---

# Property Database Skill

All property management data lives in Supabase. Use the Supabase MCP server (`execute_sql`) for every data operation. Never hard-code data in responses — always query live.

## References

- `references/schema.md` — All 5 table schemas, field descriptions, valid enum values, relationship map

## MCP Usage

The Supabase MCP server is configured in OpenClaw settings. Use the `execute_sql` tool for all queries.

### Security: Parameterized Queries

Always pass variable data (tenant names, addresses, UUIDs) via MCP's parameterized query
mechanism — never via string concatenation. The SQL examples in this skill use literal values
for illustration only. Concatenating user-supplied strings directly into SQL creates SQL
injection risk.

### Read Examples

```sql
-- Get all properties with current status
SELECT property_id, address, city, status, fix FROM properties;

-- Get tenant for a property
SELECT t.name, t.email, t.phone, t.lease_start, t.rent_amount, t.birthday
FROM tenant t
JOIN properties p ON t.property_id = p.property_id
WHERE p.address ILIKE '%123 Main%';

-- Get vendors by trade type and city
SELECT name, phone, email, notes
FROM vendors
WHERE trade_type = 'plumber' AND city = 'Toronto';

-- Get maintenance history for a property
SELECT m.issue_type, m.status, m.assigned_worker, m.expense_amount, m.time_stamp
FROM maintenance m
JOIN properties p ON m.property_id = p.property_id
WHERE p.address ILIKE '%123 Main%'
ORDER BY m.time_stamp DESC;

-- Get last 5 interactions for a tenant
SELECT channel, summary, timestamp
FROM interactions
WHERE tenant_id = '<uuid>'
ORDER BY timestamp DESC
LIMIT 5;
```

### Write Examples

```sql
-- Insert new maintenance record
INSERT INTO maintenance (property_id, property_address, issue_type, status, proof, time_stamp)
VALUES ('<property_uuid>', '123 Main St', 'appliance', 'problem raised', 'https://...', now());

-- Update maintenance status
UPDATE maintenance SET status = 'assigned', assigned_worker = 'Bob Plumbing' WHERE maintenance_id = '<uuid>';

-- Log an interaction
INSERT INTO interactions (tenant_id, name, channel, summary, timestamp)
VALUES ('<tenant_uuid>', 'Jane Doe', 'email', 'Reported leaking faucet in kitchen', now());

-- Update property status
UPDATE properties SET status = 'fix_needed', fix = 'Leaking kitchen faucet' WHERE property_id = '<uuid>';
```

## HITL Rules

- **Read operations**: execute freely to answer questions
- **Write operations (INSERT/UPDATE)**: always show the proposed change to the manager and wait for "Approve" before executing
- **DELETE**: never delete records without explicit written manager approval
- **Financial data**: read freely, but updating rent or expense fields requires APPROVE

## Date Handling

- Database format: `YYYY-MM-DD` (ISO 8601)
- Display format to humans: `DD/MM/YYYY`
- Always use `now()` for timestamp inserts

## Query Patterns

When a manager says "check [address]":
1. Query properties by address ILIKE match
2. Join tenant to get occupant info
3. Query last 3 maintenance records
4. Query last 3 interactions
5. Return a summary: tenant name, rent, status, open issues, last contact

When a manager says "find a [trade] vendor in [city]":
1. Query vendors by trade_type + city
2. Return name, phone, email, notes for top 3 results
