# Skill: Vercel Deployer (Onboarding Agent — Phase D)

## When to use
After the DR-lander skill returns 3 HTML strings, push them live to a new dedicated Vercel project for this client.

## Inputs
- `client_code` — e.g. "CLLX"
- `client_name` — e.g. "Callix"
- `index_html`, `book_html`, `confirmed_html` — the three full HTML strings
- `vercel_token` — credential, set in n8n
- `team_id` — optional, scopes to your team if set

## Project naming
- Project name: `${client_code.toLowerCase()}-onboarding` (e.g. `cllx-onboarding`)
- This avoids stomping on the client's existing production project (like `callix` or `mailmend-agency`).

## Steps (this is implemented as n8n HTTP nodes, not LLM tool calls)

### Step 1 — Create or find the project
```
GET https://api.vercel.com/v9/projects/{project_name}
  Headers: Authorization: Bearer {vercel_token}
```
- If 404: create it via `POST /v10/projects` with `{ "name": "{project_name}", "framework": null }`
- If 200: keep its `id`

### Step 2 — Deploy the 3 files
```
POST https://api.vercel.com/v13/deployments
  Headers: Authorization: Bearer {vercel_token}, Content-Type: application/json
  Body: {
    "name": "{project_name}",
    "project": "{project_name}",
    "target": "production",
    "files": [
      { "file": "index.html",     "data": "<base64 of index_html>",     "encoding": "base64" },
      { "file": "book.html",      "data": "<base64 of book_html>",      "encoding": "base64" },
      { "file": "confirmed.html", "data": "<base64 of confirmed_html>", "encoding": "base64" }
    ],
    "projectSettings": { "framework": null }
  }
```

The response contains `url` (the deployment URL) and `id`.

### Step 3 — Persist to client_pages
For each of the 3 pages, insert:
```sql
INSERT INTO client_pages (
  client_id, page_type, slug, title,
  vercel_project_id, vercel_project_name, vercel_deployment_id,
  url, html_content, generated_by, run_id
)
VALUES (...)
```

### Step 4 — Return URLs to onboarding_runs
Update onboarding_runs row with:
- `vercel_project_id`, `vercel_project_name`
- `lp_url` = `https://{deployment_url}/`
- `booking_url` = `https://{deployment_url}/book`
- `ty_url` = `https://{deployment_url}/confirmed`

## Notes
- The deployment URL is the auto-generated `{project}-{hash}.vercel.app` — we can rename later.
- Each redeploy creates a new immutable URL but the project's "production" alias updates automatically.
- Custom domain assignment is a Phase-2 task (out of scope for v1).
