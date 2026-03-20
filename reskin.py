import os, re, glob

# Files to edit
files = sorted(
    glob.glob('/Users/dt/dt_creative_system/1[2-9]*.html') +
    glob.glob('/Users/dt/dt_creative_system/2[0-2]*.html')
)

# Verify we have exactly the right files
expected = [
    '12-brand-profiles.html', '13-image-ad-generator.html', '14-image-ad-review.html',
    '15-funnel-calculator.html', '16-copy-scorer.html', '17-angle-generator.html',
    '18-lp-swipes.html', '19-lp-generator.html', '20-lp-deploy.html',
    '21-lp-editor.html', '22-lp-history.html'
]
actual = [os.path.basename(f) for f in files]
assert actual == expected, f"File mismatch: {actual}"

# ---- REPLACEMENT DEFINITIONS ----

OLD_FONTS_LINK = "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&family=Space+Grotesk:wght@400;500;600;700&display=swap"
NEW_FONTS_LINK = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600;700&display=swap"

PRELOAD_LINES = '    <link rel="preload" href="https://cdn.prod.website-files.com/68ebcfae353873d3845aaa3f/68ebd7016f791a85d9b66018_Geist-Medium.woff2" as="font" type="font/woff2" crossorigin="anonymous">\n    <link rel="preload" href="https://cdn.prod.website-files.com/68ebcfae353873d3845aaa3f/68ebd9b6adb71eac8c5883db_GeistMono-Regular.woff2" as="font" type="font/woff2" crossorigin="anonymous">'

CSS_VAR_REPLACEMENTS = [
    ('--bg-primary: #0a0a0b',       '--bg-primary: #0f0f0f'),
    ('--bg-secondary: #111113',     '--bg-secondary: #141414'),
    ('--bg-tertiary: #1a1a1d',      '--bg-tertiary: #1e1e1e'),
    ('--border-hover: #3a3a3d',     '--border-hover: #444240'),
    ('--border: #2a2a2d',           '--border: #302f2c'),
    ('--text-primary: #fafafa',     '--text-primary: #f5f5f5'),
    ('--text-secondary: #a0a0a5',   '--text-secondary: #888680'),
    ('--text-muted: #606065',       '--text-muted: #555550'),
    ('--accent-dim: #00ff8820',     '--accent-dim: #f5f5f515'),
    ('--accent-hover: #00ffaa',     '--accent-hover: #ffffff'),
    ('--accent: #00ff88',           '--accent: #f5f5f5'),
    ('--warning-dim: #ffaa0020',    '--warning-dim: #f8d47a20'),
    ('--warning: #ffaa00',          '--warning: #f8d47a'),
    ('--purple-dim: #a855f720',     '--purple-dim: #88868020'),
    ('--purple: #a855f7',           '--purple: #888680'),
    ('--blue-dim: #3b82f620',       '--blue-dim: #88868020'),
    ('--blue: #3b82f6',             '--blue: #888680'),
    ('--orange-dim: #f9731620',     '--orange-dim: #fd510620'),
    ('--orange: #f97316',           '--orange: #fd5106'),
]

FONT_REPLACEMENTS = [
    ("'Space Grotesk', sans-serif",    "'Geist', Arial, sans-serif"),
    ("'JetBrains Mono', monospace",    "'Geist Mono', monospace"),
]

BRAND_OLD = 'CONTENT_ENGINE//v1'
BRAND_NEW = 'PROPAGANDA//OS'

changes_log = []

for filepath in files:
    fname = os.path.basename(filepath)
    with open(filepath, 'r') as f:
        original = f.read()

    content = original
    file_changes = []

    # --- 1. Font imports ---
    if OLD_FONTS_LINK in content:
        content = content.replace(OLD_FONTS_LINK, NEW_FONTS_LINK)
        file_changes.append('fonts link replaced')

    if 'Geist-Medium.woff2' not in content:
        preconnect_pattern = '    <link rel="preconnect" href="https://fonts.googleapis.com">'
        if preconnect_pattern in content:
            content = content.replace(
                preconnect_pattern,
                PRELOAD_LINES + '\n' + preconnect_pattern
            )
            file_changes.append('font preloads added')

    # --- 2. CSS Variables ---
    for old_var, new_var in CSS_VAR_REPLACEMENTS:
        if old_var in content:
            content = content.replace(old_var, new_var)
            file_changes.append(f'var {old_var.split(":")[0].strip()} updated')

    # --- 3. Font families ---
    for old_font, new_font in FONT_REPLACEMENTS:
        if old_font in content:
            count = content.count(old_font)
            content = content.replace(old_font, new_font)
            file_changes.append(f'font family replaced ({count}x): {old_font}')

    # --- 4. Sidebar brand text ---
    if BRAND_OLD in content:
        content = content.replace(BRAND_OLD, BRAND_NEW)
        file_changes.append('brand text replaced')

    # --- 5. btn-primary color: #000 -> #0f0f0f (only where preceded by background: var(--accent)) ---
    pattern = r'(background:\s*var\(--accent\);\s*\n\s*)color:\s*#000;'
    replacement = r'\1color: #0f0f0f;'
    new_content, count = re.subn(pattern, replacement, content)
    if count > 0:
        content = new_content
        file_changes.append(f'btn-primary color #000 -> #0f0f0f ({count}x)')

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        changes_log.append(f'{fname}: {", ".join(file_changes)}')
    else:
        changes_log.append(f'{fname}: NO CHANGES')

print("=== CHANGES APPLIED ===")
for entry in changes_log:
    print(entry)

# === VERIFICATION ===
print("\n=== VERIFICATION ===")
errors = []
for filepath in files:
    fname = os.path.basename(filepath)
    with open(filepath, 'r') as f:
        content = f.read()

    sl = content.count('sidebar-link')
    sc = content.count('<script')

    # Check that old values are gone
    if 'JetBrains Mono' in content:
        errors.append(f'{fname}: still contains JetBrains Mono')
    if 'Space Grotesk' in content:
        errors.append(f'{fname}: still contains Space Grotesk')
    if BRAND_OLD in content:
        errors.append(f'{fname}: still contains old brand text')
    if OLD_FONTS_LINK in content:
        errors.append(f'{fname}: still contains old fonts link')
    if '#0a0a0b' in content:
        errors.append(f'{fname}: still contains old bg-primary #0a0a0b')
    if '#00ff88' in content:
        errors.append(f'{fname}: still contains old accent #00ff88')

    # Check new values are present
    if 'PROPAGANDA//OS' not in content:
        errors.append(f'{fname}: missing new brand text')
    if "'Geist', Arial, sans-serif" not in content:
        errors.append(f'{fname}: missing Geist font family')
    if 'Geist-Medium.woff2' not in content:
        errors.append(f'{fname}: missing font preload')
    if '--accent: #f5f5f5' not in content:
        errors.append(f'{fname}: missing new accent color')

    # Check sidebar-link count is preserved
    if sl != 25:
        errors.append(f'{fname}: sidebar-link count changed to {sl} (expected 25)')
    if sc != 1:
        errors.append(f'{fname}: script tag count changed to {sc} (expected 1)')

    print(f'{fname}: {sl} sidebar-links, {sc} script tags - OK')

if errors:
    print("\n!!! ERRORS FOUND !!!")
    for e in errors:
        print(f'  - {e}')
else:
    print("\nAll verifications passed!")
