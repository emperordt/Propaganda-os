-- ============================================
-- PROPAGANDA OS — AUTH & MULTI-USER ACCESS
-- ============================================
-- Adds:
--   1. client_users table (user ↔ client ↔ role)
--   2. Permission helper functions
--   3. RLS policies on multi-tenant tables (CREATED but NOT enabled by default)
--
-- IMPORTANT: This migration creates the policies and helpers but does NOT
-- enable RLS on any table. The companion migration `auth-enable-rls.sql`
-- flips that switch — run it ONLY after at least one internal user exists
-- in `client_users` (otherwise you lock yourself out of the database).
-- ============================================

-- 1. client_users join table
CREATE TABLE IF NOT EXISTS client_users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id     UUID REFERENCES clients(id) ON DELETE CASCADE,
  role          TEXT NOT NULL CHECK (role IN ('internal','collaborator','client')),
  display_name  TEXT,
  invited_by    UUID REFERENCES auth.users(id),
  created_at    TIMESTAMPTZ DEFAULT now(),
  -- Allow multiple (user_id, client_id) rows ONLY when client_id is null
  CONSTRAINT client_users_unique_assignment UNIQUE (user_id, client_id)
);

CREATE INDEX IF NOT EXISTS idx_client_users_user    ON client_users(user_id);
CREATE INDEX IF NOT EXISTS idx_client_users_client  ON client_users(client_id);

COMMENT ON TABLE client_users IS
  'Multi-tenant access control. role=internal+client_id=null means see-everything. role=collaborator means freelance editor/designer scoped to one or more clients. role=client means end-client read-mostly access.';

-- 2. Permission helpers (SECURITY DEFINER so they bypass RLS recursion on client_users)
CREATE OR REPLACE FUNCTION is_internal()
RETURNS BOOLEAN
LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM client_users
    WHERE user_id = auth.uid()
      AND role = 'internal'
      AND client_id IS NULL
  );
$$;

CREATE OR REPLACE FUNCTION can_see_client(target_client_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT
    is_internal()
    OR EXISTS (
      SELECT 1 FROM client_users
      WHERE user_id = auth.uid()
        AND client_id = target_client_id
    );
$$;

CREATE OR REPLACE FUNCTION user_role_for(target_client_id UUID)
RETURNS TEXT
LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT COALESCE(
    (SELECT role FROM client_users
       WHERE user_id = auth.uid()
       AND role = 'internal'
       AND client_id IS NULL
       LIMIT 1),
    (SELECT role FROM client_users
       WHERE user_id = auth.uid()
       AND client_id = target_client_id
       LIMIT 1)
  );
$$;

COMMENT ON FUNCTION is_internal() IS 'True if caller is on the internal team (client_id IS NULL row in client_users).';
COMMENT ON FUNCTION can_see_client(UUID) IS 'True if caller is internal or has explicit grant for the given client.';
COMMENT ON FUNCTION user_role_for(UUID) IS 'Returns role string for caller scoped to a client. internal > explicit grant.';

-- 3. RLS Policies — define them now, ENABLE separately in auth-enable-rls.sql

-- client_users: users can read their own rows; internals can read+manage all
DROP POLICY IF EXISTS client_users_read_own  ON client_users;
DROP POLICY IF EXISTS client_users_internal_all ON client_users;
CREATE POLICY client_users_read_own ON client_users
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY client_users_internal_all ON client_users
  FOR ALL USING (is_internal()) WITH CHECK (is_internal());

-- clients
DROP POLICY IF EXISTS clients_visible ON clients;
DROP POLICY IF EXISTS clients_internal_write ON clients;
CREATE POLICY clients_visible ON clients
  FOR SELECT USING (can_see_client(id));
CREATE POLICY clients_internal_write ON clients
  FOR ALL USING (is_internal()) WITH CHECK (is_internal());

-- Per-client tables: visible if user has access to client; internal can mutate freely;
-- collaborators can update (but for now we leave fine-grained write rules to the app layer).
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'concepts','creatives','marketing_tests','batches',
    'icps','brand_profiles','offer_contexts','onboarding_steps'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I_visible ON %I', t, t);
    EXECUTE format('DROP POLICY IF EXISTS %I_internal_or_collab ON %I', t, t);
    EXECUTE format(
      'CREATE POLICY %I_visible ON %I FOR SELECT USING (can_see_client(client_id))',
      t, t);
    EXECUTE format(
      'CREATE POLICY %I_internal_or_collab ON %I FOR ALL '
      'USING ( is_internal() OR user_role_for(client_id) IN (''collaborator'') ) '
      'WITH CHECK ( is_internal() OR user_role_for(client_id) IN (''collaborator'') )',
      t, t);
  END LOOP;
END $$;

-- image_ad_swipes: shared internal IP — internal-only by default
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='image_ad_swipes') THEN
    DROP POLICY IF EXISTS image_ad_swipes_internal_only ON image_ad_swipes;
    CREATE POLICY image_ad_swipes_internal_only ON image_ad_swipes
      FOR ALL USING (is_internal()) WITH CHECK (is_internal());
  END IF;
END $$;

-- Done. RLS is NOT enabled yet — see auth-enable-rls.sql.
