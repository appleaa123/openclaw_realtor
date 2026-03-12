---
name: property-db
description: "Query and update property management data in Supabase via MCP. Use for all property, tenant, vendor, maintenance, and interaction records."
metadata: { "openclaw": { "emoji": "🏠" } }
---

# Property Database Skill

All property management data lives in Supabase. Use the `exec` tool with `curl` against the Supabase REST API for every data operation. Never hard-code data in responses — always query live.

## References

- `references/schema.md` — All 5 table schemas, field descriptions, valid enum values, relationship map

## REST API Usage

Use the `exec` tool to run `curl` commands against the Supabase REST API. The env vars
`SUPABASE_URL` and `SUPABASE_SERVICE_KEY` are available in the gateway process at runtime.

### Security: URL-encode filter values

Always URL-encode variable data used in query-string filters (addresses, names, UUIDs).
For simple equality filters PostgREST handles quoting automatically via `eq.<value>` syntax.
For ILIKE patterns, use `ilike.*value*` — PostgREST handles SQL escaping server-side.
Never concatenate raw user input directly into the `-d` JSON body without JSON-encoding it first;
use `jq` or construct the JSON value safely.

### Read Examples

```bash
# Get all properties with current status
exec: curl -s "$SUPABASE_URL/rest/v1/properties?select=property_id,address,city,status,fix" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY"

# Get tenant for a property (join via ?select= embedding)
exec: curl -s "$SUPABASE_URL/rest/v1/tenant?select=name,email,phone,lease_start,rent_amount,birthday,properties(address)&properties.address=ilike.*123+Main*" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY"

# Get vendors by trade type and city
exec: curl -s "$SUPABASE_URL/rest/v1/vendors?select=name,phone,email,notes&trade_type=eq.plumber&city=eq.Toronto" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY"

# Get maintenance history for a property (by property_id)
exec: curl -s "$SUPABASE_URL/rest/v1/maintenance?select=issue_type,status,assigned_worker,expense_amount,time_stamp&property_id=eq.<property_uuid>&order=time_stamp.desc" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY"

# Get last 5 interactions for a tenant
exec: curl -s "$SUPABASE_URL/rest/v1/interactions?select=channel,summary,timestamp&tenant_id=eq.<uuid>&order=timestamp.desc&limit=5" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY"
```

### Write Examples

```bash
# Insert new maintenance record
exec: curl -s -X POST "$SUPABASE_URL/rest/v1/maintenance" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"property_id":"<property_uuid>","property_address":"123 Main St","issue_type":"appliance","status":"problem raised","proof":"https://...","time_stamp":"now()"}'

# Update maintenance status
exec: curl -s -X PATCH "$SUPABASE_URL/rest/v1/maintenance?maintenance_id=eq.<uuid>" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status":"assigned","assigned_worker":"Bob Plumbing"}'

# Log an interaction
exec: curl -s -X POST "$SUPABASE_URL/rest/v1/interactions" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"tenant_id":"<tenant_uuid>","name":"Jane Doe","channel":"email","summary":"Reported leaking faucet in kitchen"}'

# Update property status
exec: curl -s -X PATCH "$SUPABASE_URL/rest/v1/properties?property_id=eq.<uuid>" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status":"fix_needed","fix":"Leaking kitchen faucet"}'
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
