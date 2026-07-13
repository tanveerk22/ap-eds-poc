// blocks/product-details/product-details.js
//
// This is an EDS "block". In EDS, a page is a document; the document contains
// blocks (tables/sections); each block has a folder here with a .js + .css.
// EDS calls the default-exported decorate(block) once for each instance found
// on the page. That is the entire block contract.
//
// ── THE TWO-PLANE MODEL (the whole point of the POC) ─────────────────────────
//  PLANE 1 — SSR (server-side rendered by Product Bus):
//    core product content + JSON-LD are ALREADY in the HTML before any JS runs.
//    Crawlers/LLMs see this on the first pass. No client rendering required.
//  PLANE 2 — DYNAMIC (hydrated client-side):
//    live price, availability, serial/warranty come from the Brand Experience
//    API at runtime and are filled in on top of the SSR markup.
//
// In production, decorate() receives a block that Product Bus already filled
// with SSR markup, and we only run PLANE 2. For local dev / the demo (no PB),
// we render PLANE 1 ourselves from the product JSON so you can see both.

const CURRENCY_SYMBOLS = {
  EUR: '€', USD: '$', CHF: 'CHF', GBP: '£',
};

function money(value, currency) {
  if (!value) return '';
  const symbol = CURRENCY_SYMBOLS[currency] || currency || '';
  return `${symbol}� ${value}`;
}

/**
 * Read the product JSON-LD that Product Bus embedded in the page.
 * Used as a fallback data source when the block markup is empty.
 */
export function readEmbeddedProduct() {
  const ld = document.querySelector('script[type="application/ld+json"]');
  if (!ld) return null;
  try {
    return JSON.parse(ld.textContent);
  } catch {
    return null;
  }
}

/**
 * PLANE 1 — render the static, crawlable product view.
 * Exported so the local demo can render it from JSON (Product Bus does this
 * server-side in production, so this function would not run there).
 */
export function renderStatic(container, product) {
  const img = (product.images && product.images[0]) || {};
  const gallery = img.url
    ? `<img src="${img.url}" alt="${img.label || product.name}" loading="eager"/>`
    : '<div class="pdp-placeholder">Image served from DAM</div>';

  container.innerHTML = `
    <div class="pdp-gallery">${gallery}</div>
    <div class="pdp-info">
      <p class="pdp-reference">${product.sku}</p>
      <h1 class="pdp-name">${product.name}</h1>
      <p class="pdp-description">${product.description || ''}</p>
      <dl class="pdp-specs">
        ${(product.attributes || [])
    .map((a) => `<div class="pdp-spec"><dt>${a.label}</dt><dd>${a.value}</dd></div>`)
    .join('')}
      </dl>
      <div class="pdp-dynamic" data-sku="${product.sku}" data-currency="${product.currency || ''}">
        <span class="pdp-price" data-hydrate="price">…</span>
        <span class="pdp-availability" data-hydrate="availability"></span>
      </div>
    </div>`;
}

/**
 * PLANE 2 — hydrate the dynamic fields from the Brand Experience API.
 * @param {Element} container the block element
 * @param {object}  opts
 * @param {string}  opts.endpoint Brand Experience API base (APIM) in production
 * @param {function} opts.fetcher optional (sku)=>Promise<liveData>, used by the demo
 */
export async function hydrate(container, { endpoint, fetcher } = {}) {
  const node = container.querySelector('.pdp-dynamic');
  if (!node) return;
  const { sku, currency } = node.dataset;

  const load = fetcher
    ? () => fetcher(sku)
    : async () => {
      const base = endpoint || '/api/brand-experience/products';
      const res = await fetch(`${base}/${sku}`);
      return res.json();
    };

  try {
    const live = await load();
    const priceEl = node.querySelector('[data-hydrate="price"]');
    const availEl = node.querySelector('[data-hydrate="availability"]');
    if (priceEl) priceEl.textContent = money(live.price, live.currency || currency) || 'Auf Anfrage';
    if (availEl) {
      availEl.textContent = live.inStock ? 'Verfügbar' : 'Auf Anfrage';
      availEl.classList.toggle('in-stock', !!live.inStock);
    }
    node.classList.add('hydrated');
  } catch {
    // If hydration fails the SSR content still stands — that is the resilience
    // benefit of the two-plane model. We just mark it for styling/telemetry.
    node.classList.add('hydrate-failed');
  }
}

export default async function decorate(block) {
  // If Product Bus already rendered the SSR markup (production), skip PLANE 1.
  // Otherwise build it from the embedded JSON-LD (local dev without PB).
  if (!block.querySelector('.pdp-info')) {
    const product = readEmbeddedProduct();
    if (product) renderStatic(block, product);
  }
  await hydrate(block);
}
