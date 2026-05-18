# Skill: Market Research (Onboarding Agent — Phase A)

## When to use
First phase of an onboarding run. You have a client URL, a context dump, and optionally an offer brief. You need to deeply research the market BEFORE any copy or design happens.

## Output contract
Return a single JSON object with these keys:

```jsonc
{
  "icp": [
    {
      "name": "Course Creators Doing $25k-$100k/mo",
      "tier": "Tier 1",
      "description": "...",
      "core_identity": "...",
      "emotional_lever": "...",
      "their_phrases": "...",                   // verbatim language they use
      "fears": ["..."],                          // their actual fears
      "desires": ["..."],                        // outcomes they want
      "awareness_analysis": {                    // per Schwartz level
        "unaware": "...",
        "problem_aware": "...",
        "solution_aware": "...",
        "product_aware": "...",
        "most_aware": "..."
      }
    }
  ],
  "brand_profile": {
    "name": "...",
    "tone": "Direct, no-fluff, slightly provocative",
    "voice_guidelines": "...",
    "avoid_words": ["leverage","unlock","game-changer"],
    "brand_colors": ["#0a0a0a","#ff5500","#ffffff"],
    "design_principles": "Minimal, brutalist, mono fonts, dark mode"
  },
  "competitors": [
    {
      "name": "Callix",
      "site_url": "https://callix.io",
      "fb_ad_library_url": "https://www.facebook.com/ads/library/?...",
      "google_ad_library_url": "https://adstransparency.google.com/?...",
      "positioning_summary": "...",
      "offer_summary": "...",
      "pricing_notes": "..."
    }
  ],
  "customer_voice": [
    {
      "quote": "I'm tired of paying for tools that don't actually deliver leads.",
      "source_url": "https://reddit.com/r/sales/comments/...",
      "source_label": "Reddit /r/sales",
      "sentiment": "negative",
      "mapped_to": "pain"
    }
  ],
  "pain_points": ["Inconsistent lead flow","Calls don't book","..."],
  "desires":     ["Predictable revenue","Calendar packed with qualified leads","..."],
  "obstacles": [
    {
      "obstacle": "Manual prospecting eats 4 hours a day",
      "severity": 5,
      "category": "time",
      "potential_solution": "Done-for-you AI prospecting",
      "maps_to_offer_lever": "Growth Engine setup"
    }
  ],
  "headlines": [
    {
      "headline": "How we book 30 qualified calls a week for B2B SaaS founders — without paying a team",
      "angle": "Calendar Outcome",
      "lead_type": "Promise",
      "awareness_level": "Problem Aware",
      "reasoning": "PA prospects know they need more calls but not the mechanism"
    }
  ]
}
```

## Process

1. **Scrape the client's site** (use `scrape_url` tool). Pull: hero copy, mechanism descriptions, social proof, FAQ, pricing if shown.
2. **Identify 3-5 direct competitors** (use `web_search`). For each: scrape their homepage + one offer page.
3. **For each competitor, build an FB Ad Library URL**:
   `https://www.facebook.com/ads/library/?active_status=all&ad_type=all&country=US&q={competitor_name}&search_type=keyword_unordered`
4. **For each competitor, build a Google Ads Transparency URL**:
   `https://adstransparency.google.com/?domain={competitor_domain}`
5. **Mine voice-of-customer**: search Reddit, Trustpilot, G2, Capterra, TrustRadius, Quora for `"{client niche} pain" OR "{competitor name} frustration"`. Collect 8-15 verbatim quotes WITH source URLs.
6. **Build ICPs** with awareness_analysis blocks per Schwartz level.
7. **Map pain_points and desires** from VOC quotes + ICP fears/dreams. Aim for 5-8 of each.
8. **Generate obstacles**: think Hormozi "what stops them from getting their dream outcome?" — list 5-10 with severity 1-5 and category.
9. **Generate 5 test headlines** — vary lead type (Story, Problem-Solution, Big Secret, Promise, Proclamation, Offer) and awareness level. Each headline should be sharp, scroll-stopping, and grounded in actual VOC language.

## Quality bars
- Customer voice quotes must be **real** with verifiable source URLs. Never make up quotes.
- Pain/desire arrays must come from VOC + ICP analysis, not from generic templates.
- Competitor analysis must include actual screenshots/findings, not vibes.
- Headlines must use verbatim phrases from VOC when possible.

## Tools available
- `web_search(query)` — Anthropic native web search
- `scrape_url(url)` — fetches and returns text content
- `save_competitor`, `save_voc`, `save_obstacle`, `save_headline` — write directly to Supabase as you find things

## Done condition
You're done when you have: ≥3 competitors, ≥8 VOC quotes with sources, ≥5 ICPs with awareness blocks, ≥5 pain points, ≥5 desires, ≥5 obstacles, ≥5 headlines. Then return the JSON.
