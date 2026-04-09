# Propaganda OS Migration

Adds multi-tenant client support and an auto-named creative pipeline to the existing Supabase schema.

## What this migration does

**Adds 5 new tables:**
- `clients` — multi-tenant root (Mailmend, Callix, Propinc, etc.)
- `batches` — weekly production batches per client (auto-named: `MLMD-W6`)
- `concepts` — angle/format groupings within a batch
- `creatives` — individual ads with auto-naming (`CALX-W15-PainAgitate-ImageAd-PA-B1-H1`)
- `onboarding_steps` — 8 rows per client tracking onboarding progress

**Modifies 3 existing tables:**
- `brand_profiles` — adds `client_id` column
- `image_ad_generations` — adds `client_id` column
- `vercel_projects` — adds `client_id` column

**Adds 2 Postgres functions + triggers for auto-naming:**
- `generate_batch_name()` — sets `batches.name` to `{client_code}-W{week_number}` on insert
- `generate_creative_name()` — sets `creatives.name` to the full naming convention on insert

## How to run

1. Open the Supabase SQL Editor: https://wqclspynbdghfsosqygg.supabase.co/project/_/sql
2. Copy the contents of `propaganda-os-migration.sql`
3. Paste into a new query
4. Click **Run**

The migration is **re-runnable** — uses `IF NOT EXISTS` and `DROP IF EXISTS` throughout. Safe to run multiple times.

## Verification queries

After running, verify with:

```sql
-- Check all 5 new tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('clients', 'batches', 'concepts', 'creatives', 'onboarding_steps');

-- Check client_id columns were added
SELECT table_name, column_name FROM information_schema.columns
WHERE column_name = 'client_id'
AND table_name IN ('brand_profiles', 'image_ad_generations', 'vercel_projects');

-- Check triggers exist
SELECT tgname, tgrelid::regclass FROM pg_trigger
WHERE tgname IN ('set_batch_name', 'set_creative_name');
```

## Test the auto-naming

```sql
-- 1. Create a test client
INSERT INTO clients (name, code, status)
VALUES ('Callix', 'CALX', 'active')
RETURNING id;
-- Note the returned UUID, use it below

-- 2. Create a batch (name should auto-populate)
INSERT INTO batches (client_id, week_number, year)
VALUES ('<client_id>', 15, 2026)
RETURNING id, name;
-- Expected: name = 'CALX-W15'

-- 3. Create a concept
INSERT INTO concepts (batch_id, client_id, angle, format)
VALUES ('<batch_id>', '<client_id>', 'PainAgitate', 'ImageAd')
RETURNING id;

-- 4. Create a creative (name should auto-populate)
INSERT INTO creatives (concept_id, client_id, hook_number, awareness_level, hook_text)
VALUES ('<concept_id>', '<client_id>', 1, 'Problem Aware', 'Test hook')
RETURNING name;
-- Expected: name = 'CALX-W15-PainAgitate-ImageAd-PA-B1-H1'
```

## Awareness level codes

| Awareness Level | Code |
|---|---|
| Unaware | UA |
| Problem Aware | PA |
| Solution Aware | SA |
| Product Aware | PrA |
| Most Aware | MA |
| (none / unknown) | XX |

## Rollback

If you need to undo:

```sql
DROP TABLE IF EXISTS creatives CASCADE;
DROP TABLE IF EXISTS concepts CASCADE;
DROP TABLE IF EXISTS batches CASCADE;
DROP TABLE IF EXISTS onboarding_steps CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP FUNCTION IF EXISTS generate_batch_name();
DROP FUNCTION IF EXISTS generate_creative_name();
ALTER TABLE brand_profiles DROP COLUMN IF EXISTS client_id;
ALTER TABLE image_ad_generations DROP COLUMN IF EXISTS client_id;
ALTER TABLE vercel_projects DROP COLUMN IF EXISTS client_id;
```
