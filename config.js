// ============================================
// PROPAGANDA OS — SHARED CONFIG
// One source of truth for all pages.
// Mirrors .env values that need to live in the browser.
// Change keys/URLs here, every page picks them up.
// ============================================

window.PROPAGANDA = {
    // Supabase
    SUPABASE_URL: 'https://wqclspynbdghfsosqygg.supabase.co',
    SUPABASE_ANON_KEY: 'sb_publishable_TnW2BTNaZvow6Gm8DbxU-w_5YyQN3Av',

    // n8n base + webhook endpoints
    N8N_BASE: 'https://n8n.dtthomas.cloud/webhook',
    N8N: {
        // Existing
        SWIPE: 'https://n8n.dtthomas.cloud/webhook/swipe',
        GENERATE: 'https://n8n.dtthomas.cloud/webhook/generate',
        REGENERATE: 'https://n8n.dtthomas.cloud/webhook/regenerate',
        FINALIZE: 'https://n8n.dtthomas.cloud/webhook/finalize',
        IMAGE_AD_SWIPE: 'https://n8n.dtthomas.cloud/webhook/image-ad-swipe',
        IMAGE_AD_COPY: 'https://n8n.dtthomas.cloud/webhook/image-ad-copy',
        IMAGE_AD_RENDER: 'https://n8n.dtthomas.cloud/webhook/image-ad-render',
        VERCEL_PROJECT_CREATE: 'https://n8n.dtthomas.cloud/webhook/vercel-project-create',
        // Propaganda OS
        CLIENT_ONBOARD: 'https://n8n.dtthomas.cloud/webhook/client-onboard',
        BRAND_SCRAPE: 'https://n8n.dtthomas.cloud/webhook/brand-scrape',
        // Onboarding agent (Opus 4.7 + web_search) — drafts brand_profiles + N icps from URL + context + offer brief + potential ICPs.
        // Returns: { brand_profile: {...}, icps: [{...}, ...] }
        // POST shape: { client_id, url, context_dump, offer_brief, potential_icps: [{name, tier, note}, ...] }
        CLIENT_ONBOARD_AGENT: 'https://n8n.dtthomas.cloud/webhook/client-onboard-agent',
        // Creative brief layer — flows not yet built; pages tolerate empty strings
        BRIEF_GENERATE: '',           // POST {client_id, brand_id, offer_id, icp_id, lead_type, awareness_level, angle, big_idea} → returns brief_json
        CREATIVE_SLACK_NOTIFY: ''     // POST {event:'approved'|'winner', creative_id, client_id, name, image_url}
    },

    // Storage paths
    STORAGE: {
        BUCKET: 'assets',
        BRAND_LOGOS: 'brand-logos',
        AD_IMAGES: 'ad-images',
        SWIPES: 'swipes'
    }
};

// Convenience headers for Supabase REST calls
window.PROPAGANDA.HEADERS = {
    'apikey': window.PROPAGANDA.SUPABASE_ANON_KEY,
    'Authorization': 'Bearer ' + window.PROPAGANDA.SUPABASE_ANON_KEY,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
};
window.PROPAGANDA.HEADERS_READ = {
    'apikey': window.PROPAGANDA.SUPABASE_ANON_KEY,
    'Authorization': 'Bearer ' + window.PROPAGANDA.SUPABASE_ANON_KEY
};

// Per-client storage path helper. Use this anywhere we store/read ad files
// so paths stay scoped: ad-images/{client_code}/{batch_name}/{file}
window.PROPAGANDA.path = function(clientCode, batchName, fileName) {
    const parts = [this.STORAGE.AD_IMAGES, clientCode, batchName, fileName].filter(Boolean);
    return parts.join('/');
};

// ============================================
// SHARED SIDEBAR — single source of truth for nav across all 26 pages.
// Pages just need <aside class="sidebar" id="sidebar"></aside>; this auto-renders on DOMContentLoaded.
// ============================================
window.PROPAGANDA.SIDEBAR_NAV = [
    { label: 'Operations', items: [
        { href: '23-client-hub.html',         label: 'Client Hub' },
        { href: '24-onboarding.html',         label: 'Onboarding' },
        { href: '26-creative-board.html',     label: 'Creative Pipeline' },
        { href: '27-tests.html',              label: 'Tests' },
        { href: '12-brand-profiles.html',     label: 'Brand Profiles' },
        { href: '13-image-ad-generator.html', label: 'Image Ad Generator' }
        // 25-creative-brief.html is intentionally NOT here — it's a deep-link-only
        // editor reached from the Creative Pipeline drawer ("Open Full Editor").
    ]},
    { label: 'Image Ads', items: [
        { href: '14-image-ad-review.html',    label: 'Review' }
    ]},
    { label: 'Video Ads', items: [
        { href: '06-ad-swipes.html',          label: 'Swipe Library' },
        { href: '07-ad-generator.html',       label: 'Generator' }
    ]},
    { label: 'Twitter', items: [
        { href: '08-twitter-generator.html',  label: 'Generate' },
        { href: '11-twitter-swipes.html',     label: 'Swipes' },
        { href: '09-twitter-scraper.html',    label: 'Scraper' },
        { href: '10-hook-bank.html',          label: 'Hook Bank' }
    ]},
    { label: 'YouTube', items: [
        { href: '01-generation-hub.html',     label: 'Generate' },
        { href: '02-swipe-file.html',         label: 'Swipe File' },
        { href: '03-face-library.html',       label: 'Face Library' },
        { href: '04-output-review.html',      label: 'Output Review' },
        { href: '05-history.html',            label: 'History' }
    ]},
    { label: 'Landing Pages', items: [
        { href: '18-lp-swipes.html',          label: 'Swipe Library' },
        { href: '19-lp-generator.html',       label: 'Generator' },
        { href: '21-lp-editor.html',          label: 'Editor' },
        { href: '20-lp-deploy.html',          label: 'Deploy' },
        { href: '22-lp-history.html',         label: 'History' }
    ]},
    { label: 'Tools', items: [
        { href: '15-funnel-calculator.html',  label: 'Funnel Math' },
        { href: '16-copy-scorer.html',        label: 'Copy Scorer' },
        { href: '17-angle-generator.html',    label: 'Angle Generator' }
    ]}
];

window.PROPAGANDA.renderSidebar = function(targetSelector) {
    const target = document.querySelector(targetSelector || '#sidebar');
    if (!target) return;
    const here = (location.pathname.split('/').pop() || 'index.html').toLowerCase();
    const escapeHtml = s => String(s).replace(/[&<>"']/g, ch => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[ch]));
    const sections = this.SIDEBAR_NAV.map(sec => {
        const links = sec.items.map(it => {
            const active = it.href.toLowerCase() === here ? ' active' : '';
            return `<a href="${escapeHtml(it.href)}" class="sidebar-link${active}">${escapeHtml(it.label)}</a>`;
        }).join('');
        return `<div class="sidebar-section"><div class="sidebar-section-label">${escapeHtml(sec.label)}</div>${links}</div>`;
    }).join('');
    target.innerHTML = `<div class="sidebar-brand">PROPAGANDA//OS</div>${sections}`;
};

// Auto-render on every page that loads config.js
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => window.PROPAGANDA.renderSidebar());
} else {
    window.PROPAGANDA.renderSidebar();
}
