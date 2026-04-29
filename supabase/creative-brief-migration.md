# Creative Brief Migration

Applied: **2026-04-28** to project `wqclspynbdghfsosqygg` (Propaganda Inc).

Adds the brief layer on top of the Propaganda OS multi-tenant pipeline. Sister to `propaganda-os-migration.sql` and `icps-migration.sql` — run those first. This file is re-runnable (`IF NOT EXISTS`, `OR REPLACE`, `DROP CONSTRAINT IF EXISTS`).

## What it does

1. **`concepts` becomes the brief-bearing entity.** Every concept now carries the full creative brief: lead type, awareness level, asset type, big idea, hypothesis, expected outcome, ICE scores, approval audit (who/when), the offer/ICP/swipe it pulls from, and a free-form `brief_json` for the rest (hooks, body framework, proof points, CTA, visual direction, production notes, voice).
2. **`batches` gets a test plan.** Adds `hypothesis`, `expected_outcomes`, `learnings` so each weekly batch documents the test it's running and what we learned when it closes.
3. **`creatives` gains denormalized `lead_type` + `asset_type`** for fast filtering on the kanban without joining concepts every time.
4. **The `generate_creative_name()` trigger is extended.** New filename pattern adds the lead-type token and asset-type code:

   ```
   {batch}-{angle}-{format}-{awareness}-{lead_type}-{asset_type}-B{n}-H{n}
   e.g.   MLMD-W5-Simplicity-UGC-PA-Story-IMG-B1-H1
   ```

   The trigger reads lead/asset from the row first, falls back to the parent concept, and **omits any segment that's null** so legacy creatives that predate this migration still get clean short names.
5. **`concepts_full` view** joins concepts with batch + client metadata so the UI can render a card with `client_code`, `batch_name`, `ice_score`, `lead_type` in one query.

## Field reference

### `concepts` (new columns)

| column            | type              | values                                                                       |
|-------------------|-------------------|------------------------------------------------------------------------------|
| `big_idea`        | text              | 1–2 sentence creative concept                                                |
| `lead_type`       | text              | `Story` / `Problem-Solution` / `Big Secret` / `Promise` / `Proclamation` / `Offer` |
| `awareness_level` | text              | `Unaware` / `Problem Aware` / `Solution Aware` / `Product Aware` / `Most Aware` |
| `asset_type`      | text (default IMG)| `IMG` / `VID` / `CAR`                                                        |
| `offer_id`        | uuid → offer_contexts | which offer this brief promotes                                          |
| `icp_id`          | uuid → icps       | target ICP                                                                   |
| `swipe_id`        | uuid → image_ad_swipes | optional inspiration reference                                          |
| `brief_json`      | jsonb             | hook_ideas, body_framework, proof_points, pain_focus, cta, visual_direction, production_notes, awareness_copy_notes, voice_notes, custom_image_prompt |
| `hypothesis`      | text              | what we expect to learn                                                      |
| `expected_outcome`| text              | what success looks like                                                      |
| `concept_category`| text              | `Control` (≥8.5 ICE) / `DataDriven` (≥7.5) / `Innovation` (≥7.0)            |
| `impact`          | int (1–10)        | ICE — potential effect                                                       |
| `confidence`      | int (1–10)        | ICE — execution certainty                                                    |
| `ease`            | int (1–10)        | ICE — production simplicity                                                  |
| `ice_score`       | numeric, generated| `ROUND((impact + confidence + ease) / 3.0, 2)`                               |
| `submitted_by`    | text              | who submitted the brief for approval                                         |
| `approved_by`     | text              | who approved it                                                              |
| `approved_at`     | timestamptz       | when approval happened                                                       |
| `rejected_at`     | timestamptz       | when rejection happened                                                      |
| `rejection_reason`| text              | why                                                                          |

### `concepts.status` lifecycle

```
draft → scored → approved → in_production → launched → archived
              ↘ rejected
```

### `batches` (new columns)

| column              | type | use                                              |
|---------------------|------|--------------------------------------------------|
| `hypothesis`        | text | what we expect to validate this week             |
| `expected_outcomes` | text | KPIs / success criteria                          |
| `learnings`         | text | retro after the batch closes                     |

### `creatives` (new columns)

| column       | type                | notes                                           |
|--------------|---------------------|-------------------------------------------------|
| `lead_type`  | text                | denormalized from concepts; row-level override |
| `asset_type` | text (default IMG)  | denormalized; row-level override                |

## Storage path convention (UI helper)

Files for a concept's creatives should live at:

```
ad-images/{client_code}/{batch_name}/{creative_name}.{ext}
```

The browser helper `window.PROPAGANDA.path()` in `config.js` produces these paths. n8n image-render flows should adopt the same convention when they next ship.

## Verification (already ran during apply)

```sql
-- Smoke test: creates batch + concept + creative, reads name + ice_score, then cleans up.
WITH
  c AS (SELECT id FROM clients WHERE code='HLTC' LIMIT 1),
  b AS (INSERT INTO batches (client_id, week_number, year, status)
        SELECT id, 99, 2099, 'planning' FROM c RETURNING id, name),
  cp AS (INSERT INTO concepts (batch_id, client_id, angle, format, lead_type, awareness_level, asset_type, impact, confidence, ease)
         SELECT b.id, c.id, 'TestAngle', 'UGC', 'Story', 'Problem Aware', 'IMG', 9, 8, 7
         FROM b, c RETURNING id, ice_score),
  cr AS (INSERT INTO creatives (concept_id, client_id, hook_number)
         SELECT cp.id, (SELECT id FROM c), 1 FROM cp RETURNING name)
SELECT (SELECT name FROM cr) AS creative_name,
       (SELECT ice_score FROM cp) AS ice;
-- Expected:
-- creative_name = 'HLTC-W99-TestAngle-UGC-PA-Story-IMG-B1-H1'
-- ice = 8.00
```

## Rollback (only if needed)

```sql
DROP VIEW IF EXISTS concepts_full;
ALTER TABLE concepts DROP COLUMN IF EXISTS ice_score;
ALTER TABLE concepts DROP COLUMN IF EXISTS impact, DROP COLUMN IF EXISTS confidence, DROP COLUMN IF EXISTS ease;
ALTER TABLE concepts DROP COLUMN IF EXISTS big_idea, DROP COLUMN IF EXISTS lead_type, DROP COLUMN IF EXISTS awareness_level,
                     DROP COLUMN IF EXISTS asset_type, DROP COLUMN IF EXISTS offer_id, DROP COLUMN IF EXISTS icp_id,
                     DROP COLUMN IF EXISTS swipe_id, DROP COLUMN IF EXISTS brief_json, DROP COLUMN IF EXISTS hypothesis,
                     DROP COLUMN IF EXISTS expected_outcome, DROP COLUMN IF EXISTS concept_category,
                     DROP COLUMN IF EXISTS approved_by, DROP COLUMN IF EXISTS approved_at, DROP COLUMN IF EXISTS rejected_at,
                     DROP COLUMN IF EXISTS rejection_reason, DROP COLUMN IF EXISTS submitted_by;
ALTER TABLE batches DROP COLUMN IF EXISTS hypothesis, DROP COLUMN IF EXISTS expected_outcomes, DROP COLUMN IF EXISTS learnings;
ALTER TABLE creatives DROP COLUMN IF EXISTS lead_type, DROP COLUMN IF EXISTS asset_type;
-- Then re-apply propaganda-os-migration.sql to restore the original generate_creative_name().
```
