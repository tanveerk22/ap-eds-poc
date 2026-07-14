# EMA Migration Playbook — Audemars Piguet → EDS + DA

Ready-to-use prompts for the **Experience Modernization Agent (EMA)** to migrate
the AP site **page by page** into this Edge Delivery Services + Document
Authoring project.

- **Reference site (no Figma):** https://www.audemarspiguet.com/en/home
- **Target repo:** this project (based on `adobe/aem-boilerplate`; conventions in `AGENTS.md`)
- **Docs:** EMA overview — https://experienceleague.adobe.com/en/docs/experience-manager-cloud-service/content/ai-in-aem/agents/brand-experience/modernization/overview

---

## ⛔ The one rule: EMA does presentation, not product data

EMA **does not** handle commerce/product data or third-party integrations. So:

- ✅ Ask EMA for: design system, blocks, CSS, layout, static pages, nav/footer,
  and the **visual shell** of the PDP.
- ❌ Do **not** ask EMA to wire Product Bus, product data, pricing, cart,
  CIAM/PIM/Brand Experience API, or the PDP data binding.
- The PDP **data layer** is our hand-built `blocks/product-details/` block. EMA
  produces the *look*; we attach the *data*. They meet at the PDP block — always
  leave a `product-details` slot for us (see §5).

**Set expectations:** EMA targets ~80–90% fidelity, not pixel perfection, and the
AP prod site is heavy-JS, so scraped markup will need cleanup.

---

## How to use this playbook

1. Run the prompts **in order** (§0 → §7). §0 primes context once per session.
2. Migrate **one page at a time** with the reusable template in §6 — verify each
   against its reference URL before moving on.
3. After each page: `npm run lint`, check it at `http://localhost:3000` via
   `npx @adobe/aem-cli up`, and compare side-by-side with the reference URL.

Copy each block below verbatim into EMA (replace `{...}` placeholders).

---

## §0 — Session context primer (run first, once per session)

```
You are migrating the Audemars Piguet website into an existing Edge Delivery
Services + Document Authoring project based on adobe/aem-boilerplate.

Context and rules:
- Reference site (source of truth for design, since there is no Figma):
  https://www.audemarspiguet.com  — start from https://www.audemarspiguet.com/en/home
- Target: reusable EDS blocks (vanilla JS ES6+, no build step, no frameworks)
  and CSS following the boilerplate. Block files: blocks/{name}/{name}.js and
  blocks/{name}/{name}.css. Global styles in styles/styles.css (design tokens in
  :root), styles/fonts.css for fonts.
- CSS: mobile-first, min-width media queries at 600/900/1200px, every selector
  scoped to its block (e.g. `.hero .title`, never `.title`). Follow Stylelint
  standard + Airbnb ESLint (already configured).
- Accessibility: semantic HTML5, proper heading order, alt text, WCAG 2.1 AA.
- Performance: target Lighthouse 100; lazy-load below-the-fold; no heavy deps.
- Preserve the existing URL structure exactly (SEO-critical for a luxury brand).
- DO NOT implement commerce, product data, pricing, cart, or any third-party
  data integration — those are handled separately by a Product Bus data layer.
Acknowledge these rules before we begin.
```

---

## §1 — Extract the design system (run once)

```
Scrape https://www.audemarspiguet.com/en/home and a few representative pages
(a watch-collection landing page and a product page) and extract the AP design
system. Produce:
1. Design tokens for styles/styles.css :root — color palette, typography scale
   (font families, weights, sizes for h1–h6 and body at mobile + desktop),
   spacing scale, and breakpoints.
2. Font setup for styles/fonts.css (identify the typefaces; use Adobe Fonts /
   @font-face; include fallbacks with size-adjust like the boilerplate).
3. A short design-system.md summarizing tokens and usage.
Match the restrained, editorial luxury aesthetic (generous whitespace, refined
type, muted palette). Do not build pages yet — tokens and fonts only.
```

---

## §2 — Site catalog / inventory (run once, for planning)

```
Crawl https://www.audemarspiguet.com/en (main sections only, depth 2) and
produce a site catalog: list the distinct page templates and the recurring
components/blocks across them, with a screenshot per template and per component.
For each component, propose a block name and note which pages use it. Output an
interactive HTML report and a markdown block-inventory we can work through.
Do not build anything yet.
```

---

## §3 — Global blocks: header/nav and footer

**Header / navigation**
```
Build the site header + primary navigation as a `header` block, matching
https://www.audemarspiguet.com/en/home. Include the logo, top-level nav
(Watches, Universe, Manufacture, Services, etc.), and any utility links
(language/region, search, account) as markup only — no auth/search logic.
Make it responsive (mobile menu at <900px) and accessible (keyboard nav, ARIA).
Author the nav content as a DA document so it is editable. Scope all CSS to
`.header`. Do not wire CIAM/login.
```

**Footer**
```
Build the site footer as a `footer` block matching the AP prod footer: link
columns, legal row, social icons, language/region selector (markup only).
Author footer content as a DA document. Responsive + accessible. Scope CSS to
`.footer`.
```

---

## §4 — Static page types (page by page)

**Home**
```
Migrate https://www.audemarspiguet.com/en/home into an EDS page.
Identify each section (hero, featured collections, storytelling, editorial
grid, etc.) and implement each as a reusable block (blocks/{name}/). Author the
page content as a DA document that composes these blocks. Reuse the design
tokens from §1 and the header/footer from §3. Match layout, spacing and imagery
treatment to the reference. Static content only — no product data.
```

**Watch collection landing (PLP shell — STATIC in this POC)**
```
Migrate the watch-collection landing page, e.g.
https://www.audemarspiguet.com/en/watch-collection/royal-oak into an EDS page.
Build the editorial/hero sections as blocks, and build a `product-grid` block
that renders a grid of product tiles (image, model name, reference, link).
IMPORTANT: author the tiles as STATIC content in a DA document for now (a fixed
snapshot list) — do NOT fetch products from any API or commerce service. Each
tile links to its product page using the existing URL pattern
/{market}/{lang}/watch-collection/{family}/{reference}. Scope CSS to
`.product-grid`. Responsive + accessible.
```

**Editorial / story page**
```
Migrate {EDITORIAL_URL} (e.g. a Universe/Heritage story page) into an EDS page.
Break it into reusable blocks (full-bleed media, text+image, quote, gallery,
etc.). Author as a DA document. Reuse existing blocks where the pattern already
exists — extend, don't duplicate. Static content only.
```

**Utility pages (boutiques, contact, services, legal)**
```
Migrate {UTILITY_URL} into an EDS page as static content + reusable blocks.
For any form or store-locator/map, produce the MARKUP and layout only — leave a
clearly-commented placeholder where the third-party integration will attach.
Do not implement the integration.
```

---

## §5 — PDP: visual shell ONLY (hand off data to Product Bus)

```
Build the PRESENTATION shell for a product detail page, matching
https://www.audemarspiguet.com/com/de/watch-collection/royal-oak/26545XT.OO.1240XT.01.html
Requirements:
- Produce the layout, typography and CSS for the PDP (gallery, product title,
  reference, description, specification list, and a slot for price/availability).
- Deliver it as CSS/markup that decorates a block called `product-details`.
- DO NOT fetch or bind any product data, price, availability, or JSON-LD, and do
  NOT call any API. A separate, already-built `product-details` block owns all
  data binding and hydration; your job is ONLY the visual design/CSS it will use.
- Match the class names this block expects: container `.product-details`, with
  `.pdp-gallery`, `.pdp-reference`, `.pdp-name`, `.pdp-description`, `.pdp-specs`
  (a <dl> of `.pdp-spec` > <dt>/<dd>), and `.pdp-dynamic` holding
  `.pdp-price` and `.pdp-availability`.
Output only the CSS (and any structural notes) — do not overwrite the block's JS.
```
> After EMA returns the CSS, merge it into `blocks/product-details/product-details.css`
> (keep our `product-details.js` data layer untouched).

---

## §6 — Reusable per-page template (use for every remaining page)

```
Migrate the page at {PAGE_URL} into this EDS + DA project.

1. Fetch and analyze {PAGE_URL}; list its sections top to bottom.
2. For each section, REUSE an existing block if one already fits; otherwise
   create a new blocks/{name}/ (js + scoped css). Prefer extending over new.
3. Author the page as a DA document at the path {TARGET_PATH} that composes the
   blocks in order. Preserve the existing URL/slug exactly.
4. Use the §1 design tokens and the §3 header/footer. Match the reference layout,
   spacing and imagery.
5. Static/presentational content ONLY — no product data, commerce, auth, or
   third-party API calls. Where such a feature appears, leave a commented slot.
6. Ensure mobile-first responsive (600/900/1200), WCAG 2.1 AA, and run clean
   against ESLint/Stylelint. Report which blocks you reused vs. created.

Then show me the page at localhost:3000{TARGET_PATH} and a side-by-side note of
any differences from {PAGE_URL} so I can approve or request fixes.
```

---

## §7 — Refinement & QA prompts (after each page)

**Visual match**
```
Compare your migrated {TARGET_PATH} against {PAGE_URL} at mobile (390px) and
desktop (1440px). List concrete differences in spacing, type scale, colors and
layout, and fix them in the block CSS. Do not change content or data behavior.
```

**Responsive**
```
Audit {TARGET_PATH} at 390 / 768 / 1024 / 1440px. Fix overflow, broken grids,
tap-target sizes, and image sizing. Keep changes scoped to the affected blocks.
```

**Accessibility**
```
Run an a11y pass on {TARGET_PATH}: heading order, landmark roles, alt text,
color contrast (WCAG 2.1 AA), focus states and keyboard operability. Fix issues
in-place.
```

**Performance**
```
Optimize {TARGET_PATH} for Lighthouse 100: lazy-load below-the-fold blocks and
images, defer non-critical CSS/JS, ensure images are sized/optimized. Report the
before/after scores.
```

---

## Migration checklist (per page)

- [ ] Section-by-section block plan (reuse before create)
- [ ] DA document authored at the exact existing URL/slug
- [ ] Header/footer + design tokens reused
- [ ] Static only — no commerce/data/auth wired
- [ ] `npm run lint` clean
- [ ] Visual match verified vs. reference (mobile + desktop)
- [ ] a11y + Lighthouse pass
- [ ] (PDP only) CSS merged into `product-details`, JS data layer untouched
