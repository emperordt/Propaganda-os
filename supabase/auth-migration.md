# Auth & Multi-User Access — Rollout

## What this ships

Magic-link auth + role-based access (internal / collaborator / client) across the Propaganda OS pages. Built on Supabase Auth + RLS.

## Files in this change

- `supabase/auth-migration.sql` — schema, helpers, RLS policies (already applied)
- `supabase/auth-enable-rls.sql` — flips RLS ON, table by table (run when ready)
- `auth.js` — browser-side auth client + role helpers + `requireAuth()`
- `login.html` — magic-link login
- `28-team.html` — invite / revoke (internal only)
- `config.js` — adds Team to sidebar, gates internal-only nav, renders user pill + sign-out
- 23, 24, 25, 26, 27 — load `supabase-js` + `auth.js`, call `requireAuth({allowRoles})`

## Roles

| Role | Sees | Can do |
|---|---|---|
| `internal` | All clients, all pages | Everything (incl. approve, edit ICE, run onboarding, manage team) |
| `collaborator` | Assigned clients only | Pipeline drag (except idea→approved), brief read-only |
| `client` | Assigned client only | Phase-2 client portal (not built yet) |

## Rollout sequence

```
1. ✅ auth-migration.sql       — applied (table + helpers + policies)
2. ✅ DT pre-staged in pending_invites as internal — auto-grants on first sign-in
3. Open /login.html → enter thomas.dtt15@gmail.com → click magic link in email
4. You're now `internal`. Confirm by visiting /28-team.html and seeing yourself in Members.
5. Smoke-test: open 23, 24, 25, 26, 27 — everything should still work, sidebar now shows user pill at the bottom.
6. Invite your first collaborator (test account) via /28-team.html
7. Verify: log them in (use an incognito window), confirm they see only the clients you granted, can't approve concepts, can't see Tests/Onboarding/Team.
8. When happy with #5–7 → run auth-enable-rls.sql to make RLS authoritative.
```

## Why not enable RLS in step 1?

Bootstrap chicken-and-egg: enabling RLS before any internal user exists would lock the database (anon read goes away, no JWT yet). Staging the schema first means we can roll forward or back without breaking anyone.

## Invite flow under the hood

1. Admin enters email + role + clients in `/28-team.html`.
2. Page calls `find_user_id_by_email` RPC.
3. **If user exists**: inserts grant rows into `client_users` directly.
4. **If not**: inserts rows into `pending_invites` keyed on email.
5. Either way: sends a magic-link OTP.
6. When the user first clicks the link, the `on_auth_user_created_drain_invites` trigger copies `pending_invites` → `client_users` automatically.

## n8n

No changes needed. n8n's existing webhook flows use the `service_role` key which bypasses RLS by design. Image-gen, onboarding-agent, etc. keep working.

## Storage

`ad-images/*` bucket policies are not yet RLS-gated. Phase-2 task.

## Phase 2 (not in this ship)

- Client portal (read-only pipeline + Wins page)
- Storage bucket RLS
- Email/Slack notifications on stage changes
- Comment threads on concept cards (for client feedback in-app)
