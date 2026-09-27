// Node-only behavioral tests. No runtime dependency and no claim about CEF rendering.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const code = fs.readFileSync('web/theme.js', 'utf8');
function boot(raw = null, blocked = false) {
  const css = {}, ids = {}, groups = {};
  function element(dataset = {}) {
    return { dataset, attrs: {}, handlers: {}, value: '', textContent: '',
      style: { setProperty: (k, v) => { css[k] = v; } },
      addEventListener(k, f) { this.handlers[k] = f; },
      setAttribute(k, v) { this.attrs[k] = v; }, removeAttribute(k) { delete this.attrs[k]; } };
  }
  for (const id of ['app', 'theme-status', 'theme-reset']) ids[id] = element();
  for (const kind of ['color', 'hex']) groups[`[data-${kind}]`] = ['accent', 'background', 'surface'].map(k => element({ [kind]: k }));
  groups['[data-theme]'] = ['champagne', 'jade', 'arctic', 'amethyst'].map(theme => element({ theme }));
  let saved = raw, writes = 0;
  vm.runInNewContext(code, {
    document: { getElementById: id => ids[id], querySelectorAll: selector => groups[selector] },
    localStorage: { getItem() { if (blocked) throw Error('blocked'); return saved; },
      setItem(k, v) { if (blocked) throw Error('blocked'); saved = v; writes++; } }
  });
  return { css, ids, groups, saved: () => saved, writes: () => writes,
    preset(name) { groups['[data-theme]'].find(e => e.dataset.theme === name).handlers.click(); },
    color(field, value) { const input = groups['[data-color]'].find(e => e.dataset.color === field); input.value = value; input.handlers.change(); },
    hex(field, value) { const input = groups['[data-hex]'].find(e => e.dataset.hex === field); input.value = value; input.handlers.change(); return input; } };
}
const r = boot();
assert.equal(r.css['--accent'], '#d2b782'); assert.equal(r.writes(), 0);
for (const [name, accent] of Object.entries({ champagne:'#d2b782', jade:'#85d8b6', arctic:'#8abff0', amethyst:'#bea0ed' })) {
  r.preset(name); assert.equal(r.css['--accent'], accent);
  assert.equal(boot(r.saved()).css['--accent'], accent);
}
const before = r.saved();
assert.equal(r.hex('accent', 'red').attrs['aria-invalid'], 'true'); assert.equal(r.saved(), before);
r.hex('accent', '#AABBCC'); assert.equal(r.css['--accent'], '#aabbcc');
r.color('background', '#ffffff'); assert.equal(r.css['--text'], '#000000');
r.color('surface', '#000000'); assert.equal(r.css['--surface-text'], '#ffffff');
r.color('background', '#000000'); assert.equal(r.css['--text'], '#ffffff');
r.color('surface', '#ffffff'); assert.equal(r.css['--surface-text'], '#000000');
for (const raw of ['bad json', 'null', '{}', '{"version":99}', '{"version":1,"colors":{"accent":"url(x)"}}']) {
  assert.equal(boot(raw).css['--accent'], '#d2b782');
}
const unavailable = boot(null, true); unavailable.preset('jade');
assert.equal(unavailable.css['--accent'], '#85d8b6');
assert.match(unavailable.ids['theme-status'].textContent, /opslaan niet mogelijk/);
r.ids['theme-reset'].handlers.click(); assert.equal(boot(r.saved()).css['--accent'], '#d2b782');
const html = fs.readFileSync('web/index.html', 'utf8');
assert.match(html, /id="app" hidden/);
for (const id of ['theme-status', 'theme-reset']) assert.ok(html.includes(`id="${id}"`));
const css = fs.readFileSync('web/style.css', 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
assert.ok(!/color-scheme\s*:|backdrop-filter\s*:/.test(css));
assert.ok(css.includes('html, body { background: transparent !important;'));
const manifest = fs.readFileSync('fxmanifest.lua', 'utf8');
for (const [, path] of manifest.matchAll(/'([^']+\.(?:lua|html|css|js))'/g)) assert.ok(fs.existsSync(path), path);
console.log('PASS presets, custom colors, validation, reload, reset, unavailable/corrupt storage, light/dark text, transparent startup and manifest assets');
