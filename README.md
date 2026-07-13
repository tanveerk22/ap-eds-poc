# AP → EDS + DA + Product Bus POC

A minimal proof-of-concept for migrating Audemars Piguet's server-rendered AEM
Sites PDPs to **Edge Delivery Services (EDS)** authored in **Document Authoring
(DA)**, with **Product Bus** solving the pre-render / SEO gap for product pages.

> **Scope:** PDPs via Product Bus. All other pages (home, collection/PLP,
> editorial) are static DA pages for now. Category/PLP pre-render is a known
> Product Bus gap and is intentionally out of scope for this POC.

> **Base:** This repo is [adobe/aem-boilerplate](https://github.com/adobe/aem-boilerplate)
> with our Product Bus PDP block + tooling overlaid, so it doubles as a reusable
> **project boilerplate**. Boilerplate conventions live in `AGENTS.md`.
> Dev deps: `npm install`. Lint (Airbnb ESLint + Stylelint): `npm run lint`.

---

## 1. Core concepts (read this first)

### What EDS actually is
EDS holds **no content**. It's a delivery runtime. Every page is authored in a
**content source** and EDS pulls + serves it as fast, SSR HTML. The content
source for this POC is **DA** (`da.live`) — a document authoring tool that plays
the role Google Drive/SharePoint play in classic EDS projects.

The code (this repo) and the content (DA) are **separate**:

```
   CODE  (GitHub repo)  ──┐
                          ├──►  EDS delivery  ──►  Client (via Cloudflare)
   CONTENT (DA docs)    ──┘
```

### How a page is built
- A page = a **document**. A document contains **blocks** (tables become blocks).
- Each block has a folder in `blocks/<name>/` with a `.js` and `.css`.
- EDS runs `scripts/scripts.js` on every page, which decorates the DOM and runs
  each block's default-exported `decorate(block)` function.

### The two planes (the crux of the POC)
| Plane | What | Who renders it | Who sees it |
|---|---|---|---|
| **SSR** | product name, reference, description, specs, JSON-LD, meta | **Product Bus** (server-side) | crawlers/LLMs on first pass + humans instantly |
| **Dynamic** | live price, availability, serial, warranty | `product-details` block, client-side | humans after JS runs |

`Product Bus PDP HTML = standard EDS SSR + product view as JSON-LD` — then our
block hydrates the few dynamic bits from the **Brand Experience API**.

### How Product Bus fits
```
PIM ──► connector (you build) ──► Product Bus API ──► SSR PDP + JSON-LD ──► EDS ──► Client
                                  (api.adobecommerce.live)                    ▲
Client ──(runtime, dynamic fields)──► Brand Experience API ────────────────────┘
```
Product Bus keys each product by its **URL/path** (not SKU), so we pass the
existing AP vanity URL at ingest to preserve SEO. See `helix-query.yaml` for the
SKU→path index that lets collection tiles route to the right PDP.

---

## 2. See it working NOW (no accounts needed)

The demo reuses the **real block code** against the real Product Bus payload.

```bash
cd ap-eds-poc
python3 -m http.server 8000
# open http://localhost:8000/poc/demo/pdp-demo.html
```

You'll see the static product content render instantly (SSR plane), then the
price/availability fade in after ~1.2 s (dynamic plane). **View-Source** shows
the `<head>` meta + JSON-LD a crawler reads — the whole point of pre-render.

**Or run the real EDS runtime** (once you've done the DA/GitHub steps below):
```bash
npm install
npx -y @adobe/aem-cli up          # serves the actual project at http://localhost:3000
```
`aem up` serves your local code against previewed DA content. Product Bus PDPs
appear once products are pushed (Step 4) and the PB routing is connected.

---

## 3. Files in this repo

| File | Role |
|---|---|
| `fstab.yaml` | mounts DA as the content source |
| `head.html` | global `<head>` injected on every page |
| `helix-query.yaml` | builds `/query-index.json` (SKU→path routing) |
| `scripts/scripts.js` | page entry point + PDP auto-block |
| `styles/styles.css` | base styles |
| `blocks/product-details/*` | the PDP block (SSR decorate + hydrate) |
| `poc/products/*.json` | Product Bus payload(s) |
| `poc/push.sh` | PUT/POST/verify against the Product Bus API |
| `poc/demo/pdp-demo.html` | runnable local demo of the two-plane model |

---

## 4. Going live (the 3 things only you can do)

### Step 1 — Get a Product Bus `sitekey`
Request a bearer token for a test org/site from the Adobe **AEM/EDS team**
(Teams/Slack). This is the long pole — start here.

### Step 2 — Create the DA content source
1. Sign in at https://da.live and create an **org** + a **site** named `ap-eds-poc`.
2. Author a couple of static pages (home + one collection page).
3. Put your org name into `fstab.yaml` (`<YOUR_DA_ORG>`).

### Step 3 — Wire up the EDS project on GitHub
1. Clone `https://github.com/adobe/aem-boilerplate` into a new GitHub repo
   (this provides `scripts/aem.js` + the runtime this POC references).
2. Copy this repo's `fstab.yaml`, `helix-query.yaml`, `blocks/product-details/`,
   and the PDP auto-block in `scripts/scripts.js` into it.
3. Install the **AEM Code Sync** GitHub app on the repo.
4. Your site is live at `https://main--<repo>--<org>.aem.page`.

### Step 4 — Push products & verify
```bash
export SITEKEY=... ORG=<git-org> SITE=ap-eds-poc STORE=com VIEW=de
cd poc && ./push.sh single 26545XT.OO.1240XT.01
./push.sh verify 26545XT.OO.1240XT.01
```

---

## 5. What this POC must prove (go/no-go checklist)

- [ ] A Product Bus PDP renders full content + JSON-LD **with JS disabled**.
- [ ] The PDP is served at the **exact existing vanity URL** (deep path + `.html`).
      *(Live PB sites use clean no-extension URLs — this is the #1 thing to verify.)*
- [ ] `/query-index.json` exposes **SKU→path** so collection tiles can route.
- [ ] Dynamic fields hydrate from a (mock) Brand Experience API on top of SSR.
- [ ] Google Rich Results test passes on a rendered PDP.
- [ ] **Cloudflare** (AP's front CDN) can serve PB PDPs — validate the PB routing
      layer interaction (open question even internally).

## 6. Known blockers carried forward
- **PLP/collection pages** are not pre-renderable by Product Bus → static DA pages
  for now (this POC's scope decision).
- **No Adobe Commerce** → no PES shortcut; the PIM→PB connector is fully net-new.
- **Licensing** path for standalone (non-Adobe-Commerce) Product Bus is unresolved.
- **No PB publish events** → confirm ingestion by reading the product JSON back.
