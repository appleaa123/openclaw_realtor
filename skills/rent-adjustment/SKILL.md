---
name: rent-adjustment
description: "UC1a: Cron-triggered or manual lease review. Calculate legal rent increase limit, research market rates, generate adjustment brief with birthday and cheque alerts."
metadata:
  {
    "openclaw":
      {
        "emoji": "💰",
      },
  }
---

# Rent Adjustment Skill

Produces a complete rent adjustment advisory brief for a tenant/property. Triggered by the weekly cron or manually with "run rent review for [address]".

## References

- `references/ontario-guidelines.md` — RTA rules, calculation formula, notice timeline, sample brief format

## Workflow

### Step 1: Query Tenant Data

```sql
SELECT t.tenant_id, t.name, t.email, t.phone, t.lease_start, t.rent_amount,
       t.last_rent_adjustment_date, t.birthday, p.postalcode, p.city, p.address
FROM tenant t
JOIN properties p ON t.property_id = p.property_id
WHERE p.address ILIKE '%[address]%';
```

### Step 2: Calculations

1. **Months to anniversary**: Count months from `last_rent_adjustment_date` (or `lease_start`) to today
2. **Legal max rent**: `rent_amount × 1.021` (Ontario 2026 guideline: 2.1%)
3. **Notice required**: 90 days written notice before increase takes effect
4. **Birthday check**: Days until next birthday — flag if within 30 days
5. **Cheque check**: Count months of post-dated cheques remaining from `lease_start` month — flag if < 3 months remain

### Step 3: Market Research

Web search for comparable rental listings in the same city and postal code area:
- Search realtor.ca for "[city] [postal code prefix] rental"
- Search Zumper for "[city] rental [bedrooms]"
- Collect 3+ comparable listings with rent prices
- Calculate median market rent

### Step 4: Generate Brief

Format per `references/ontario-guidelines.md` sample brief template.

### Step 5: Send to Manager

Send complete brief via `wacli` to manager WhatsApp.
