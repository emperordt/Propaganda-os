# Onboarding Agent — User Message Template

Substitute `{placeholders}` with the values from the n8n webhook payload.

---

```
CLIENT URL:
{url}

CONTEXT DUMP (from the user):
{context_dump}

OFFER BRIEF (from the user):
{offer_brief}

POTENTIAL ICPs to research (one record per row, in this exact order):
{for each potential_icp}
- {name} ({tier}): {note}
{end for}

CLIENT NAME (for reference): {client_name}
CLIENT CODE (for reference): {client_code}

---

INSTRUCTIONS:
1. Use web_search to deeply research each potential ICP. Quote real market language.
2. Generate one fully-structured ICP record per potential ICP, preserving the order and tier.
3. Generate one brand_profile record from the URL + context dump.
4. Output the JSON object exactly matching the schema in your system prompt. No prose, no markdown.
```

## Optional pre-step (recommended): URL pre-scrape

For better accuracy, n8n should fetch the URL with a simple HTTP node first, strip the HTML to plain text (truncate at 30K chars), and inject the scraped content into the user message:

```
SCRAPED CONTENT (first 30K chars of {url}):
{scraped_content}
```

This gives the agent the actual brand voice + offer copy as primary context, without burning web_search calls on the home URL.
