# Supabase Schema Reference

## Table 1: properties

| Column | Type | Description |
|--------|------|-------------|
| property_id | UUID PK | Auto-generated |
| address | TEXT NOT NULL | Street address |
| city | TEXT NOT NULL | City |
| province | TEXT NOT NULL | Province (e.g., Ontario) |
| postalcode | TEXT NOT NULL | Postal code |
| landlord_name | TEXT | Owner name |
| rent | NUMERIC(10,2) | Monthly rent |
| status | TEXT | `normal` \| `late_payment` \| `fix_needed` |
| fix | TEXT | Description of current fix needed |
| note | TEXT | General notes |
| appliances | JSONB | `{"washer": "Samsung WF45T6000AW", "furnace": "Carrier 58TP"}` |
| time_stamp | TIMESTAMPTZ | Record created time |

## Table 2: tenant

| Column | Type | Description |
|--------|------|-------------|
| tenant_id | UUID PK | Auto-generated |
| property_id | UUID FK → properties | Linked property |
| address | TEXT | Tenant's address (matches property) |
| city | TEXT | City |
| province | TEXT | Province |
| postalcode | TEXT | Postal code |
| name | TEXT NOT NULL | Full name |
| phone | TEXT | Phone number |
| email | TEXT | Email address |
| lease_start | DATE | Lease start date (YYYY-MM-DD) |
| rent_amount | NUMERIC(10,2) | Current monthly rent |
| birthday | DATE | Tenant's birthday |
| last_rent_adjustment_date | DATE | Date of last rent increase |
| note | TEXT | General notes |
| time_stamp | TIMESTAMPTZ | Record created time |

## Table 3: interactions

| Column | Type | Description |
|--------|------|-------------|
| interaction_id | UUID PK | Auto-generated |
| tenant_id | UUID FK → tenant | Linked tenant |
| name | TEXT | Tenant name (denormalized for quick display) |
| channel | TEXT | `email` \| `whatsapp` \| `sms` \| `in-person` |
| summary | TEXT | Summary of the interaction |
| timestamp | TIMESTAMPTZ | When it occurred |

## Table 4: maintenance

| Column | Type | Description |
|--------|------|-------------|
| maintenance_id | UUID PK | Auto-generated |
| property_id | UUID FK → properties | Linked property |
| property_address | TEXT | Address (denormalized) |
| issue_type | TEXT | `Improper Surface Grading` \| `water damage` \| `electrical damage` \| `appliance` \| `roof` \| `HVAC` \| `maintenance` |
| proof | TEXT | Comma-separated photo/video attachment URLs |
| status | TEXT | `problem raised` \| `waiting` \| `assigned` \| `fixing` \| `solved` |
| assigned_worker | TEXT | Name of vendor/contractor assigned |
| expense_amount | NUMERIC(10,2) | Repair cost including tax |
| expense_note | TEXT | Expense description |
| time_stamp | TIMESTAMPTZ | Record created time |

## Table 5: vendors

| Column | Type | Description |
|--------|------|-------------|
| vendor_id | UUID PK | Auto-generated |
| name | TEXT NOT NULL | Vendor/company name |
| trade_type | TEXT | `plumber` \| `electrician` \| `HVAC` \| `roofer` \| `appliance` \| `general` |
| phone | TEXT | Contact phone |
| email | TEXT | Contact email |
| city | TEXT | City they serve |
| notes | TEXT | Rates, availability, preferences |
| time_stamp | TIMESTAMPTZ | Record created time |

## Relationships

```
properties (1) ──< tenant (many)
properties (1) ──< maintenance (many)
tenant (1) ──< interactions (many)
```

## Valid Enum Values

### properties.status
- `normal` — no issues
- `late_payment` — rent overdue
- `fix_needed` — maintenance required

### maintenance.issue_type
- `Improper Surface Grading`
- `water damage`
- `electrical damage`
- `appliance`
- `roof`
- `HVAC`
- `maintenance`

### maintenance.status
- `problem raised` — logged, not yet assigned
- `waiting` — waiting on vendor availability
- `assigned` — vendor confirmed
- `fixing` — repair in progress
- `solved` — resolved

### vendors.trade_type
- `plumber`
- `electrician`
- `HVAC`
- `roofer`
- `appliance`
- `general`

### interactions.channel
- `email`
- `whatsapp`
- `sms`
- `in-person`
