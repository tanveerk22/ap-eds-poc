# POC Completion Runbook

The exact sequence to take this POC from "scaffold" to "proven". Owners:
**[ME]** = already built in this repo · **[YOU]** = self-serve · **[ADOBE]** = depends on the Adobe PB/EDS team.

## Goal
Prove that **EDS + DA + Product Bus** delivers a **server-rendered, SEO-valid PDP**
at AP's existing vanity URL, with dynamic fields hydrated on top — for the AP
migration, with product data from PIM and no Adobe Commerce.

---

## Phase 0 — Local proof (no accounts) ✅ [ME] — done
- [x] EDS+DA boilerplate repo, lint-clean
- [x] `product-details` block (SSR-decorate + hydrate, two-plane model)
- [x] Product Bus payload (`poc/products/…json`), `push.sh`, `helix-query.yaml`
- [x] Standalone demo (`poc/demo/pdp-demo.html`) + local drafts (`drafts/`)
- [x] EMA migration playbook, verification harness (`poc/verify.sh`)

**Run it now:**
```bash
# a) zero-setup simulation
python3 -m http.server 8000    # → http://localhost:8000/poc/demo/pdp-demo.html

# b) real EDS runtime, local content
npm install
npx -y @adobe/aem-cli up --html-folder drafts --no-open
# → http://localhost:3000/  and  /com/de/watch-collection/royal-oak/26545XT.OO.1240XT.01
```

## Phase 1 — Put it online [YOU]
- [ ] Push repo to **personal GitHub** (`gh repo create … --push`)
- [ ] Install **AEM Code Sync** app on the repo (https://github.com/apps/aem-code-sync)
- [ ] Confirm site at `https://main--ap-eds-poc--<owner>.aem.page`
> Later move to the customer's **GitLab-on-Azure via BYOG** (Cloud Manager). Re-provision the sitekey then (it's scoped to org/site).

## Phase 2 — Content source [YOU]
- [ ] Create **DA** org + site at https://da.live
- [ ] Set `<YOUR_DA_ORG>` in `fstab.yaml`, commit, push
- [ ] Author a home + one `watch-collection` page (or generate via EMA later)

## Phase 3 — Product Bus [ADOBE → YOU]
- [ ] Request a **`sitekey`** (test account) for `<owner>/ap-eds-poc`, views `com`/`de` (+ locales) — **longest lead time, start in Phase 1**
- [ ] Confirm with the PB team: **`.html` vanity-path support** and **Cloudflare/front-CDN routing** (the two open risks)
- [ ] Ingest:
```bash
export SITEKEY=… ORG=<owner> SITE=ap-eds-poc STORE=com VIEW=de
cd poc && ./push.sh single 26545XT.OO.1240XT.01 && ./push.sh verify 26545XT.OO.1240XT.01
```

## Phase 4 — Verify (go/no-go) [YOU]
- [ ] Run the harness against the live PDP:
```bash
cd poc && ./verify.sh https://main--ap-eds-poc--<owner>.aem.page \
  /com/de/watch-collection/royal-oak/26545XT.OO.1240XT.01 26545XT.OO.1240XT.01 "royal oak"
```
- [ ] Google Rich Results test on the PDP
- [ ] Lighthouse SEO (target 100)

---

## Go / No-Go criteria (the POC is "proven" when all are true)
1. ✅ PDP renders full product content **with JS disabled** (view-source / `verify.sh`).
2. ✅ `application/ld+json`, `<title>`, meta description, OpenGraph present server-side.
3. ✅ PDP served at the **exact existing vanity URL** (deep path, `.html` if required).
4. ✅ `/query-index.json` exposes **SKU→path** (collection tiles can route).
5. ✅ Dynamic fields hydrate on top of SSR (Brand Experience API, real or mock).
6. ✅ Front CDN (Cloudflare) serves the PB PDP correctly (if tested in this phase).

If 1–4 pass, the core thesis holds. 5 proves the two-plane model. 6 is the
production-CDN de-risk.

## Known blockers carried forward (report with the POC result)
- **PLP/collection pre-render** not supported by PB → static DA pages (scoped out).
- **PIM→Product Bus connector** is net-new (no PES without Adobe Commerce).
- **Licensing** for standalone (non-AC) Product Bus — open commercial question.
- **Cloudflare + PB routing** and **`.html` vanity paths** — confirm with PB team.
