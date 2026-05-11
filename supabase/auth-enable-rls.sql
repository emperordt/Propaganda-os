-- ============================================
-- PROPAGANDA OS — ENABLE ROW-LEVEL SECURITY
-- ============================================
-- Run this AFTER:
--   1. At least one internal user exists in `client_users`
--      (`thomas.dtt15@gmail.com` is pre-staged in `pending_invites` — it auto-grants on first magic-link sign-in).
--   2. You've signed in once via login.html and confirmed everything still works.
--
-- This flips the security switch on every multi-tenant table.
-- After this, anon access stops — every request needs a JWT.
-- n8n is unaffected because it uses the service_role key, which bypasses RLS.
-- ============================================

ALTER TABLE client_users        ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_invites     ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients             ENABLE ROW LEVEL SECURITY;
ALTER TABLE concepts            ENABLE ROW LEVEL SECURITY;
ALTER TABLE creatives           ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_tests     ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches             ENABLE ROW LEVEL SECURITY;
ALTER TABLE icps                ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE offer_contexts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_steps    ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_ad_swipes     ENABLE ROW LEVEL SECURITY;

-- To roll back (e.g. while debugging): DISABLE ROW LEVEL SECURITY on the same tables.
