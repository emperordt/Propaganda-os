-- Landing Page System Migration
-- Run this in Supabase SQL Editor

-- ============================================
-- LANDING PAGE SWIPES
-- ============================================
CREATE TABLE landing_page_swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    screenshot_url TEXT,
    page_type TEXT NOT NULL, -- advertorial, vsl, optin, checkout
    niche TEXT,
    section_structure JSONB DEFAULT '[]', -- [{type, description, word_count, purpose}]
    copy_blocks JSONB DEFAULT '[]', -- [{section, headline, body, cta}]
    design_patterns JSONB DEFAULT '{}', -- {layout, spacing, imagery_style, social_proof_placement}
    color_scheme JSONB DEFAULT '{}', -- {primary, secondary, accent, background, text}
    typography JSONB DEFAULT '{}', -- {headline_font, body_font, sizes, weights}
    cta_placements JSONB DEFAULT '[]', -- [{location, text, style, urgency_level}]
    recreation_prompt TEXT, -- Full prompt to recreate this page style
    masterson_mapping JSONB DEFAULT '{}', -- {awareness_level, emotional_flow, proof_stacking}
    source_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_lp_swipes_page_type ON landing_page_swipes(page_type);
CREATE INDEX idx_lp_swipes_niche ON landing_page_swipes(niche);
CREATE INDEX idx_lp_swipes_created ON landing_page_swipes(created_at DESC);

-- ============================================
-- LANDING PAGE GENERATIONS
-- ============================================
CREATE TABLE landing_page_generations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID REFERENCES brand_profiles(id) ON DELETE SET NULL,
    offer_id UUID REFERENCES offer_contexts(id) ON DELETE SET NULL,
    swipe_id UUID REFERENCES landing_page_swipes(id) ON DELETE SET NULL,
    page_type TEXT NOT NULL,
    html_content TEXT, -- Full self-contained HTML
    section_data JSONB DEFAULT '[]', -- Per-section breakdown for editing
    generation_config JSONB DEFAULT '{}', -- {awareness_level, tone, extra_instructions}
    status TEXT DEFAULT 'draft', -- draft, editing, ready, deployed
    title TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_lp_gen_brand ON landing_page_generations(brand_id);
CREATE INDEX idx_lp_gen_offer ON landing_page_generations(offer_id);
CREATE INDEX idx_lp_gen_swipe ON landing_page_generations(swipe_id);
CREATE INDEX idx_lp_gen_status ON landing_page_generations(status);
CREATE INDEX idx_lp_gen_created ON landing_page_generations(created_at DESC);

CREATE TRIGGER update_lp_generations_updated_at
    BEFORE UPDATE ON landing_page_generations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VERCEL PROJECTS
-- ============================================
CREATE TABLE vercel_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID REFERENCES brand_profiles(id) ON DELETE SET NULL,
    vercel_project_id TEXT, -- From Vercel API
    project_name TEXT NOT NULL,
    default_domain TEXT, -- {project}.vercel.app
    custom_domains TEXT[] DEFAULT '{}',
    tracking_pixels JSONB DEFAULT '{}', -- {fb_pixel_id, hyros_script, gtm_id, custom_head, custom_body}
    vercel_token TEXT, -- Encrypted/stored token for deployments
    team_id TEXT, -- Vercel team ID if applicable
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_vercel_projects_brand ON vercel_projects(brand_id);
CREATE INDEX idx_vercel_projects_name ON vercel_projects(project_name);

CREATE TRIGGER update_vercel_projects_updated_at
    BEFORE UPDATE ON vercel_projects
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- DEPLOYED PAGES
-- ============================================
CREATE TABLE deployed_pages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    generation_id UUID REFERENCES landing_page_generations(id) ON DELETE SET NULL,
    vercel_project_id UUID REFERENCES vercel_projects(id) ON DELETE CASCADE,
    route TEXT NOT NULL, -- /page-a, /offer-spring-2024
    html_content TEXT, -- Snapshot with tracking pixels injected
    variant_label TEXT, -- "Control", "Variant A", "Urgency CTA"
    variant_group TEXT, -- Group name for A/B test sets
    deployment_url TEXT, -- Full URL after deploy
    deployment_id TEXT, -- Vercel deployment ID
    is_live BOOLEAN DEFAULT TRUE,
    deployed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_deployed_pages_project ON deployed_pages(vercel_project_id);
CREATE INDEX idx_deployed_pages_generation ON deployed_pages(generation_id);
CREATE INDEX idx_deployed_pages_route ON deployed_pages(route);
CREATE INDEX idx_deployed_pages_live ON deployed_pages(is_live);
CREATE INDEX idx_deployed_pages_created ON deployed_pages(created_at DESC);

-- ============================================
-- RLS POLICIES (allow all for single-user system)
-- ============================================
ALTER TABLE landing_page_swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE landing_page_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE vercel_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE deployed_pages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all" ON landing_page_swipes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON landing_page_generations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON vercel_projects FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON deployed_pages FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- STORAGE BUCKET for LP screenshots
-- ============================================
-- Run in Supabase Dashboard → Storage → New Bucket (or use existing 'assets' bucket)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('lp-swipes', 'lp-swipes', true);
