---
name: ltb-forms
description: "UC3: Auto-populate Ontario LTB forms (N4/N9/N12) using tenant/property data from Supabase. Generate expense reports for maintenance costs."
metadata:
  {
    "openclaw":
      {
        "emoji": "📋",
      },
  }
---

# LTB Forms Skill

Fills Ontario Landlord and Tenant Board (LTB) forms using pypdf and Supabase data.

## References

- `scripts/fill_ltb_form.py` — pypdf field mapping and PDF generation
- Blank forms: `assets/N4-blank.pdf`, `assets/N9-blank.pdf`, `assets/N12-blank.pdf`

## Form Types

| Form | Purpose | Trigger Phrase |
|------|---------|----------------|
| N4 | Notice to End Tenancy — Non-Payment of Rent | "generate N4 for [tenant]" |
| N9 | Tenant's Notice to Terminate Tenancy | "generate N9 for [tenant]" |
| N12 | Notice to End Tenancy — Landlord's Own Use | "generate N12 for [tenant]" |

## Workflow

### Step 1: Identify Form and Tenant

Parse trigger phrase to identify form type (N4/N9/N12) and tenant name or address.

### Step 2: Query Supabase

```sql
SELECT t.name, t.email, t.phone, t.lease_start, t.rent_amount,
       p.address, p.city, p.province, p.postalcode, p.landlord_name
FROM tenant t
JOIN properties p ON t.property_id = p.property_id
WHERE t.name ILIKE '%[name]%' OR p.address ILIKE '%[address]%';
```

### Step 3: Inspect Form Fields

Run `fill_ltb_form.py --inspect` to list all fillable fields in the blank PDF:
```bash
python skills/ltb-forms/scripts/fill_ltb_form.py \
    --form skills/ltb-forms/assets/N4-blank.pdf \
    --inspect
```

### Step 4: Fill Form

Run `fill_ltb_form.py --fill` with mapped data:
```bash
python skills/ltb-forms/scripts/fill_ltb_form.py \
    --form skills/ltb-forms/assets/N4-blank.pdf \
    --output /data/workspace/forms/[tenant_id]_N4.pdf \
    --fields '{"tenant_name": "Jane Doe", "address": "123 Main St", ...}'
```

### Step 5: Manager Approval

Send via `wacli`:
```
📋 FORM READY — N4 for [tenant name]
Property: [address]
Rent owing: $[amount]

Saved to: /data/workspace/forms/[tenant_id]_N4.pdf
Reply APPROVE to confirm this form is final.
```

### Fallback

If pypdf field mapping fails (field name mismatch), use `nano-pdf` skill for manual visual fill:
```
nano-pdf open skills/ltb-forms/assets/N4-blank.pdf
```

## Expense Reports

When manager says "generate expense report for [address]":

```sql
SELECT m.time_stamp, m.issue_type, m.expense_note, m.expense_amount, m.assigned_worker
FROM maintenance m
JOIN properties p ON m.property_id = p.property_id
WHERE p.address ILIKE '%[address]%'
AND m.expense_amount IS NOT NULL
ORDER BY m.time_stamp;
```

Format as text summary:
```
EXPENSE REPORT — [address]
Generated: [date]

DATE        ISSUE TYPE     VENDOR              COST
[date]      [type]         [worker]            $[amount]
[date]      [type]         [worker]            $[amount]
─────────────────────────────────────────────────────
TOTAL:                                         $[total]
(Prices include applicable tax)
```

Save to `/data/workspace/forms/[property_address]_expenses.txt` and send summary via `wacli`.
