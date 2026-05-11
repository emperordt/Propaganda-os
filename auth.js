// ============================================
// PROPAGANDA OS — AUTH
// Wraps Supabase Auth (magic link) and exposes:
//   PROPAGANDA.auth.requireAuth({allowRoles})  → call early on every gated page
//   PROPAGANDA.auth.session()                  → returns supabase session or null
//   PROPAGANDA.auth.user()                     → auth.users row (sync)
//   PROPAGANDA.auth.profile()                  → {role, client_ids[]} from client_users
//   PROPAGANDA.auth.signInWithMagicLink(email)
//   PROPAGANDA.auth.signOut()
//
// The JWT is also injected into PROPAGANDA.HEADERS in place so existing
// pages that captured `const HEADERS = PROPAGANDA.HEADERS` keep working.
// ============================================

(function() {
    if (!window.PROPAGANDA) {
        console.error('[auth] PROPAGANDA config not loaded');
        return;
    }
    if (!window.supabase || !window.supabase.createClient) {
        console.error('[auth] supabase-js not loaded — include the UMD script before auth.js');
        return;
    }

    const DEBUG = true;
    const log = (...a) => DEBUG && console.log('[auth]', ...a);

    log('init starting. URL:', location.href);
    log('hash:', location.hash, 'search:', location.search);

    const sb = window.supabase.createClient(
        window.PROPAGANDA.SUPABASE_URL,
        window.PROPAGANDA.SUPABASE_ANON_KEY,
        {
            auth: {
                persistSession: true,
                autoRefreshToken: true,
                detectSessionInUrl: false,   // we parse the URL hash ourselves to avoid hanging
                flowType: 'implicit'
            }
        }
    );
    log('supabase client created');

    // Manually parse magic-link tokens from URL hash and seed the session.
    // This runs BEFORE any getSession() call so the session is hydrated synchronously.
    async function consumeUrlHash() {
        if (!location.hash || !location.hash.includes('access_token=')) return false;
        const p = new URLSearchParams(location.hash.slice(1));
        const access_token  = p.get('access_token');
        const refresh_token = p.get('refresh_token');
        if (!access_token || !refresh_token) return false;
        log('consuming URL hash → setSession');
        const { data, error } = await sb.auth.setSession({ access_token, refresh_token });
        if (error) { log('setSession error:', error); return false; }
        log('setSession ok, user:', data?.session?.user?.email);
        // Clear hash so reloads don't re-process
        history.replaceState(null, '', location.pathname + location.search);
        return true;
    }

    let _session = null;
    let _profile = null; // {role, client_ids, display_name}

    function applyAuthHeader() {
        const jwt = _session?.access_token;
        const token = jwt || window.PROPAGANDA.SUPABASE_ANON_KEY;
        // Mutate the shared header objects in place so pages that snapshotted them earlier see the change
        window.PROPAGANDA.HEADERS.Authorization = 'Bearer ' + token;
        window.PROPAGANDA.HEADERS_READ.Authorization = 'Bearer ' + token;
    }

    async function loadProfile() {
        // Don't wipe existing profile if session is briefly missing (token refresh, tab focus, etc.)
        if (!_session?.user?.id) return;
        const { data, error } = await sb
            .from('client_users')
            .select('role, client_id, display_name')
            .eq('user_id', _session.user.id);
        if (error) {
            console.warn('[auth] profile load error', error);
            return; // keep previous profile rather than zeroing it
        }
        const internalRow = (data || []).find(r => r.role === 'internal' && r.client_id === null);
        _profile = {
            role: internalRow ? 'internal' : (data?.[0]?.role || null),
            client_ids: (data || []).map(r => r.client_id).filter(Boolean),
            display_name: internalRow?.display_name || data?.[0]?.display_name || null,
            raw: data || []
        };
    }

    async function refreshSession() {
        const { data: { session }, error } = await sb.auth.getSession();
        if (error) log('getSession error:', error);
        _session = session;
        log('refreshSession → session?', !!session, 'user:', session?.user?.email);
        applyAuthHeader();
        await loadProfile();
        log('refreshSession done. profile role:', _profile?.role);
    }

    sb.auth.onAuthStateChange(async (event, session) => {
        log('onAuthStateChange event:', event, 'session?', !!session);
        _session = session;
        applyAuthHeader();
        await loadProfile();
    });

    const LOGIN_PAGE = 'login.html';

    async function requireAuth(opts) {
        opts = opts || {};
        log('requireAuth called. allowRoles:', opts.allowRoles);
        log('hash:', location.hash || '(none)');

        // 1. If URL has magic-link tokens, consume them first.
        if (location.hash.includes('access_token=')) {
            await consumeUrlHash();
        }

        // 2. Now hydrate from storage / set session.
        await refreshSession();

        if (!_session) {
            log('FINAL: no session, redirecting to login');
            const here = encodeURIComponent(location.pathname + location.search);
            location.replace(`${LOGIN_PAGE}?next=${here}`);
            return false;
        }
        if (!_profile || !_profile.role) {
            log('FINAL: session but no profile/role, rendering pending');
            renderPending();
            return false;
        }
        if (opts.allowRoles && !opts.allowRoles.includes(_profile.role)) {
            log('FINAL: role', _profile.role, 'not in allowRoles', opts.allowRoles);
            renderForbidden(_profile.role, opts.allowRoles);
            return false;
        }
        log('FINAL: auth passed. role:', _profile.role);
        return true;
    }

    function renderPending() {
        document.body.innerHTML = `
        <div style="font-family:'Geist',-apple-system,sans-serif;background:#0a0a0a;color:#fff;height:100vh;display:flex;align-items:center;justify-content:center;text-align:center;padding:40px">
            <div style="max-width:480px">
                <div style="font-size:24px;font-weight:700;margin-bottom:12px">Almost there</div>
                <div style="color:#999;font-size:14px;line-height:1.6">
                    You're signed in as <strong style="color:#fff">${_session.user.email}</strong> but haven't been granted access to any client yet.
                    <br><br>Ask your admin to invite you, then refresh.
                </div>
                <button onclick="PROPAGANDA.auth.signOut().then(()=>location.href='login.html')" style="margin-top:24px;background:#ff5500;color:#fff;border:0;padding:10px 18px;border-radius:6px;cursor:pointer;font-weight:600">Sign out</button>
            </div>
        </div>`;
    }
    function renderForbidden(role, allow) {
        document.body.innerHTML = `
        <div style="font-family:'Geist',-apple-system,sans-serif;background:#0a0a0a;color:#fff;height:100vh;display:flex;align-items:center;justify-content:center;text-align:center;padding:40px">
            <div style="max-width:480px">
                <div style="font-size:24px;font-weight:700;margin-bottom:12px">Not available for your role</div>
                <div style="color:#999;font-size:14px;line-height:1.6">
                    This page is for <strong style="color:#fff">${allow.join(', ')}</strong>. Your role is <strong style="color:#fff">${role}</strong>.
                </div>
                <a href="23-client-hub.html" style="display:inline-block;margin-top:24px;background:#ff5500;color:#fff;text-decoration:none;padding:10px 18px;border-radius:6px;font-weight:600">← Back to Client Hub</a>
            </div>
        </div>`;
    }

    window.PROPAGANDA.auth = {
        client: sb,
        session: () => _session,
        user:    () => _session?.user || null,
        profile: () => _profile,
        role:    () => _profile?.role || null,
        clientIds: () => _profile?.client_ids || [],
        isInternal:     () => _profile?.role === 'internal',
        isCollaborator: () => _profile?.role === 'collaborator',
        isClient:       () => _profile?.role === 'client',
        requireAuth,
        refresh: refreshSession,
        signInWithMagicLink: async (email, redirectTo) => {
            return sb.auth.signInWithOtp({
                email,
                options: { emailRedirectTo: redirectTo || (location.origin + '/23-client-hub.html') }
            });
        },
        signOut: async () => {
            await sb.auth.signOut();
            _session = null; _profile = null;
            applyAuthHeader();
        }
    };

    // Make sure HEADERS has a baseline Authorization (anon) before any signed-in JWT arrives
    applyAuthHeader();
})();
