# Onboarding Agent v2 — Setup Guide

Everything you need to make the agent actually run after the code ships.

## What's already done (in code)
- ✅ Schema migrated: `onboarding_runs`, `competitors`, `customer_voice`, `obstacles`, `client_pages`, `headline_bank`
- ✅ Skill prompts written: `skills/market-research/`, `skills/direct-response-lander/`, `skills/vercel-deployer/`
- ✅ Frontend: `29-onboarding-agent.html` (input form + live progress poller + review)
- ✅ Tracking: `30-client-pages.html` (lists every page deployed for every client)
- ✅ Sidebar links wired in `config.js`
- ✅ Webhook slot `ONBOARDING_AGENT_V2` declared in `config.js`

## What YOU need to do (one-time, ~20 min)

### 1. Import the n8n workflow
- Open n8n at `https://n8n.dtthomas.cloud`
- Workflows → Import from File → choose `n8n/onboarding-agent-v2.json`
- Don't activate yet

### 2. Add credentials in n8n
Three creds are referenced by the flow:

| Credential name | Type | Value |
|---|---|---|
| `supabase` | HTTP Header Auth | Service-role key from Supabase project settings (the long `sb_secret_…` one — NOT the publishable key) |
| `anthropic` | HTTP Header Auth | Your `ANTHROPIC_API_KEY` |
| `vercel` | HTTP Header Auth | Your Vercel access token (created at https://vercel.com/account/tokens) |

For each: n8n → Credentials → New → pick HTTP Header Auth → name it exactly as above.

### 3. Paste skill prompts into the workflow
The flow has two HTTP nodes that call Anthropic (`Anthropic: research agent` and `Anthropic: LP designer`). Both have a `system` field with a `<<<PASTE … HERE>>>` marker.

For **research agent**: paste the contents of `skills/market-research/system-prompt.md` followed by `skills/market-research/SKILL.md` into the `system` string.

For **LP designer**: paste `skills/direct-response-lander/system-prompt.md` + `skills/direct-response-lander/SKILL.md`.

(Reason for paste-time: n8n can't read files from the repo at runtime. The prompts are versioned in the repo so you can iterate on them, but the workflow needs them baked in. When you update a prompt, re-paste.)

### 4. Activate the workflow
Switch the workflow to Active. The webhook URL becomes `https://n8n.dtthomas.cloud/webhook/onboarding-agent-v2`.

### 5. Test
- Visit `https://propagandaos.vercel.app/29-onboarding-agent.html`
- Sign in with master password
- Pick a test client (or create a new one like "Test Brand")
- URL: any real site you want it to research (e.g. `https://callix.io`)
- Context dump: paste anything — meeting notes, founder bio
- Click "Start onboarding"
- Watch the progress rows fill in. Should take 2-5 minutes end to end.
- When done, check the 3 URLs work and `30-client-pages.html` shows the 3 rows.

## File layout

```
skills/
  SETUP.md                            ← this file
  market-research/
    SKILL.md                          ← when/how/output contract for research
    system-prompt.md                  ← system message header
  direct-response-lander/
    SKILL.md                          ← LP structure, copy rules, SVG library
    system-prompt.md                  ← system message header
  vercel-deployer/
    SKILL.md                          ← reference for n8n nodes that talk to Vercel

n8n/
  onboarding-agent-v2.json            ← the workflow to import

29-onboarding-agent.html              ← the UI (URL+context form + progress)
30-client-pages.html                  ← Vercel page tracker for every client
config.js                             ← webhook slot + sidebar nav (additive)
```

## Updating prompts

When you iterate on a skill prompt:
1. Edit the .md in `skills/<skill>/`
2. Commit + push (so it's tracked)
3. Re-paste into the matching n8n node (research agent or LP designer)
4. Save the workflow

## Adding a NEW skill

Follow the same pattern:
1. Create `skills/<new-skill>/SKILL.md` + `system-prompt.md`
2. Add a new HTTP node in the n8n flow that calls Anthropic with that system prompt
3. Wire it into the chain in the right phase

## Troubleshooting

- **Run stays "researching" forever**: Check n8n Executions for the failing node. Most common: Anthropic API key wrong, or web_search beta header missing.
- **LP HTML truncated**: Bump `max_tokens` in the LP designer node from 32000 to higher.
- **Vercel deployment fails with 401**: Re-check the Vercel token is current and has full team scope.
- **`client_pages` table empty after a run**: The insert node ran but maybe with bad JSON. Check the Webhook node's input + the Extract URLs node output.
- **Run row stuck**: Manually patch `onboarding_runs` set status='error' for that id, fix the issue, retry.

## Future ideas (out of scope for v1)
- Custom domain mapping per client (point `{client}.io/quotes` at the Vercel deployment)
- LP variant generation (multiple hero hooks per onboarding for split-testing)
- Auto-image-gen for hero visuals (currently SVG only)
- Onboarding "diff" mode — re-run with updated context, keep old artifacts, show what changed
