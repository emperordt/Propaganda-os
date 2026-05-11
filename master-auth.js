// ============================================
// PROPAGANDA OS — MASTER AUTH
// Password-gated master access. No magic links, no JWT, no Supabase Auth.
//
// Flow:
//   1. User visits any master page → if no session, redirect to login.html
//   2. login.html: type password → SHA256 hash check → set localStorage session
//   3. Subsequent loads: session in localStorage → allow
//   4. Session expires after 30 days → re-login
//
// Collaborator URLs (?t=<token>) bypass this entirely (handled per-page).
// ============================================

(function() {
    window.PROPAGANDA = window.PROPAGANDA || {};

    // SHA256 of master password ("Propinc1233$$%%").
    // To rotate: pick a new password, compute sha256, replace below.
    const MASTER_HASH    = '1e16e11e805f5423cfe63a3559d5622f334cc5c12b3ef89847beab2c2867cfad';
    const SESSION_KEY    = 'propaganda_master_session';
    const SESSION_DAYS   = 30;
    const LOGIN_PAGE     = 'login.html';

    async function sha256(text) {
        const bytes = new TextEncoder().encode(text);
        const buf = await crypto.subtle.digest('SHA-256', bytes);
        return Array.from(new Uint8Array(buf))
            .map(b => b.toString(16).padStart(2, '0'))
            .join('');
    }

    function getSession() {
        try {
            const raw = localStorage.getItem(SESSION_KEY);
            if (!raw) return null;
            const s = JSON.parse(raw);
            if (s.expires_at && Date.now() > s.expires_at) {
                localStorage.removeItem(SESSION_KEY);
                return null;
            }
            return s;
        } catch (e) { return null; }
    }

    function setSession() {
        const s = {
            token:      (crypto.randomUUID && crypto.randomUUID()) || String(Math.random()).slice(2),
            created_at: Date.now(),
            expires_at: Date.now() + SESSION_DAYS * 86400000
        };
        localStorage.setItem(SESSION_KEY, JSON.stringify(s));
        return s;
    }

    async function login(password) {
        const hash = await sha256(password);
        if (hash !== MASTER_HASH) return false;
        setSession();
        return true;
    }

    function signOut() {
        localStorage.removeItem(SESSION_KEY);
        location.href = LOGIN_PAGE;
    }

    async function requireMaster(opts) {
        opts = opts || {};
        if (getSession()) return true;
        const next = encodeURIComponent(location.pathname + location.search);
        location.replace(`${LOGIN_PAGE}?next=${next}`);
        return false;
    }

    window.PROPAGANDA.masterAuth = {
        login,
        signOut,
        requireMaster,
        isAuthenticated: () => !!getSession(),
        session: getSession
    };

    // ============================================
    // Auto-gate: any page that includes master-auth.js (besides login + index)
    // is redirected to login unless either a master session OR a ?t= token is present.
    // 26/27 do their own token handling AFTER this fires (they set window.__SKIP_AUTOGATE
    // before including master-auth.js to bypass).
    // ============================================
    if (!window.__SKIP_AUTOGATE) {
        const page = (location.pathname.split('/').pop() || '').toLowerCase();
        const skip = ['login.html', 'index.html', ''];
        if (!skip.includes(page)) {
            const hasToken = new URLSearchParams(location.search).get('t');
            if (!hasToken && !getSession()) {
                const next = encodeURIComponent(location.pathname + location.search);
                location.replace(`${LOGIN_PAGE}?next=${next}`);
            }
        }
    }
})();
