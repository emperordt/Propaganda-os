# Skill: Direct Response Landing Page Designer (Onboarding Agent — Phase C)

## When to use
After research + synthesis are complete, you have:
- `brand_profile` (colors, tone, voice, fonts)
- `icps[]` with pain/desire/awareness blocks
- `offer_context` with pain_points, desires, unique_mechanism, proof_points, objections, price_point
- 5 test `headlines[]`
- `obstacles[]`

You will generate **3 HTML files** for one-shot onboarding:
1. **Landing page** (`index.html`) — main offer page, scrollable long-form
2. **Booking page** (`book.html`) — calendar embed page with social proof + objection handling
3. **Thank you page** (`confirmed.html`) — post-booking with next steps + expectation setting

Reference style: `try.callix.io/adstrial3`, `/adsbooking`, `/adsconfirmed`.

## Quality bars
- **Direct response copywriting** (Schwartz / Sugarman / Masterson principles). Every section earns its scroll.
- **SVG-heavy minimal design**. No third-party images. Solid color blocks, simple icons, wave dividers, badges.
- **Dark or light mode driven by `brand_profile.brand_colors`**. Use first color as primary, second as accent.
- **Mobile-first**, responsive, fast (no JS frameworks, plain HTML+CSS+inline SVG).
- **No external dependencies** other than Google Fonts. Self-contained, single-file deploy.
- **Conversion-focused above the fold**: hook + sub + visual + CTA in first viewport.

---

## Landing page structure (`index.html`)

```
HERO
  ├─ Pre-headline pill (optional, badge style — "For B2B SaaS founders doing $50k-$1M MRR")
  ├─ H1 = winning headline from headlines[] (pick the Promise or Problem-Solution one)
  ├─ Sub-headline (1-2 sentences amplifying the H1)
  ├─ Primary CTA button (verb-first: "Book Your Strategy Call")
  ├─ Trust strip (logos, "Used by X+ companies", or stat — pulled from VOC if real, else placeholder)
  └─ Hero visual (SVG composition — abstract, on-brand, no people)

PROBLEM AGITATION ("The reality you're living in")
  ├─ Pull 3 pain bullets from offer_context.pain_points OR ICP fears
  ├─ Each bullet: short headline + 1-sentence amplification using VOC language
  └─ Closes with a stark statement of the cost of inaction

MECHANISM REVEAL ("Why the old way is broken — and what works instead")
  ├─ Name the old way (be specific — "hiring more SDRs", "manual cold outreach")
  ├─ Name why it fails (use obstacles[])
  ├─ Reveal the unique mechanism (from offer_context.unique_mechanism)
  └─ Brief diagram or 3-step bullets (SVG steps)

SOCIAL PROOF
  ├─ 2-3 testimonial cards (use customer_voice quotes that are positive sentiment)
  ├─ Each card: quote + name + role + result (if available)
  └─ Below: stat strip ("X+ revenue generated", "Y avg lift", etc. — from offer_context.proof_points)

OFFER STACK (Hormozi-style value equation)
  ├─ "Here's everything you get when you join"
  ├─ 4-6 value items, each with: title, description, "($X value)" badge
  ├─ Total value calc: "Total Value: $Y"
  ├─ Your price (big, bold): "Today: $Z"
  └─ Crossed-out higher anchor

URGENCY / RISK REVERSAL
  ├─ Scarcity (only N spots) OR urgency (price increases X date) — pick one based on offer
  ├─ Guarantee (specific, falsifiable — "We deliver X by Y date or refund")
  └─ Risk-reversal copy

FAQ (objection handling)
  ├─ 5-7 FAQs pulled from offer_context.objections (which were sourced from VOC)
  └─ Each Q is in customer voice, A is direct + reassuring

FINAL CTA
  ├─ Mirror of hero CTA with stronger close ("Last chance — book a call")
  ├─ Optional: scarcity reminder
  └─ Single button, big, primary brand color
```

## Booking page structure (`book.html`)

```
COMPACT HEADER
  ├─ Logo (text-based using brand colors)
  └─ Trust marker ("Trusted by X")

OFFER REMINDER (left column on desktop, top on mobile)
  ├─ "You're about to book..." + offer name
  ├─ 3-5 bullets of what they'll get on the call
  └─ Mini social proof (1 testimonial)

CALENDAR EMBED PLACEHOLDER (right column / below on mobile)
  ├─ Empty div with id="cal-embed" — user pastes their Cal.com / Calendly script later
  └─ Helper text: "Pick a time that works"

OBJECTION HANDLING (below the calendar)
  ├─ "Why this call is different" — 3 bullets
  ├─ "What happens after you book" — 3-step sequence
  └─ Disqualifiers ("This isn't for you if X")
```

## Thank-you page structure (`confirmed.html`)

```
HERO
  ├─ Big "You're In" / "Call Confirmed" headline
  ├─ Confirmation: "We'll see you {date} at {time}" — use {{date}}/{{time}} placeholders
  └─ Add to calendar button (mailto: link + Google Calendar URL)

WHAT TO EXPECT
  ├─ "Before our call" — 3 prep items
  ├─ "On our call" — what we'll cover
  └─ "If you can't make it" — reschedule link

EXTRA RESOURCES (optional)
  ├─ Link to client's case study or report
  └─ "While you wait — read this" (1-2 links)

FINAL THANK YOU
  └─ Founder photo placeholder + signature note
```

---

## SVG component library (reuse across pages)

You have these patterns to use. Don't reinvent.

```html
<!-- Wave divider (use between sections) -->
<svg viewBox="0 0 1440 120" class="wave-divider"><path d="M0,40 C480,120 960,0 1440,80 L1440,120 L0,120 Z" fill="{accent}"/></svg>

<!-- Check icon (offer stack, FAQ) -->
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="{accent}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>

<!-- Star (testimonials, ratings) -->
<svg viewBox="0 0 24 24" width="16" height="16" fill="{accent}"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>

<!-- Arrow (CTAs, lists) -->
<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>

<!-- Hero abstract (use as background SVG, parameterize colors) -->
<svg viewBox="0 0 800 600" class="hero-bg" preserveAspectRatio="xMidYMid slice">
  <defs><linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="{primary}" stop-opacity="0.1"/><stop offset="100%" stop-color="{accent}" stop-opacity="0.05"/></linearGradient></defs>
  <rect width="800" height="600" fill="url(#g1)"/>
  <circle cx="700" cy="100" r="180" fill="{accent}" opacity="0.06"/>
  <circle cx="100" cy="500" r="240" fill="{primary}" opacity="0.08"/>
</svg>
```

## Copywriting principles you MUST follow

1. **Curiosity > exposition**. Make them want to keep reading.
2. **Bullets > paragraphs**. Use short, punchy bullets with clear payoffs.
3. **Specific > vague**. "30 calls/week" > "more calls". "$47" > "affordable". Names + numbers everywhere.
4. **Loss-frame > gain-frame** in pain sections. "Stop losing 4 hours a day" > "Save time".
5. **Customer voice**. Re-use VOC quotes verbatim where possible.
6. **One CTA per section**. No competing actions.
7. **Headlines are commands or curiosity gaps**. Not statements.
8. **End every long section with a CTA**. Anchor decisions to action.

## Output

Three files, each a complete standalone HTML file (`<!DOCTYPE html>` to `</html>`):
- `index.html`
- `book.html`
- `confirmed.html`

Each MUST:
- Set `<title>` using offer name + client name
- Include `<meta name="viewport" ...>` and OG tags
- Embed all CSS in `<style>` (no external CSS files)
- Embed all SVGs inline (no external image files)
- Use brand colors from `brand_profile.brand_colors`
- Reference brand font via Google Fonts CSS import in `<head>`
- Be ≤ 80KB per file (target — strip whitespace, don't over-comment)

Return JSON:
```json
{ "index_html": "...", "book_html": "...", "confirmed_html": "..." }
```

No prose. Just the three HTML strings inside the JSON object.
