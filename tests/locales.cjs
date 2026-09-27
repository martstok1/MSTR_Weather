'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
class Element {
  constructor(tag = 'DIV', text) { this.nodeType = 1; this.tagName = tag; this.attrs = {}; this.childNodes = text === undefined ? [] : [{ nodeType: 3, nodeValue: text }]; }
  hasAttribute(key) { return key in this.attrs; }
  getAttribute(key) { return this.attrs[key]; }
  setAttribute(key, value) { this.attrs[key] = value; }
}
const root = new Element('HTML');
const label = new Element('BUTTON', 'Time');
const name = new Element('OPTION', '<img src=x> (fivem:12) · opgeslagen'); name.value = 'fivem:12';
const input = new Element('INPUT'); input.value = '19';
const status = new Element('P', 'Door de server bevestigd.');
const weather = new Element('OPTION', 'CLEAR'); weather.value = 'CLEAR';
root.childNodes.push(label, name, input, status, weather);
let mutated;
const c = { window: {}, document: { documentElement: root }, MutationObserver: class { constructor(fn) { mutated = fn; } observe() {} } };
vm.createContext(c); vm.runInContext(fs.readFileSync('web/locales.js', 'utf8'), c);
const locale = c.window.MSTRLocale;
assert.equal(label.childNodes[0].nodeValue, 'Tijd');
locale.set('en'); assert.equal(label.childNodes[0].nodeValue, 'Time');
assert.equal(status.childNodes[0].nodeValue, 'Confirmed by the server.');
assert.equal(name.childNodes[0].nodeValue, '<img src=x> (fivem:12) · saved');
assert.equal(weather.childNodes[0].nodeValue, 'Clear'); assert.equal(weather.value, 'CLEAR');
assert.equal(input.value, '19'); assert.equal(name.value, 'fivem:12');
locale.set('nl'); assert.equal(label.childNodes[0].nodeValue, 'Tijd');
locale.set('en');
status.childNodes[0].nodeValue = 'Geen toestemming voor deze actie.';
mutated([{ type: 'characterData', target: status.childNodes[0] }]);
assert.equal(status.childNodes[0].nodeValue, 'You do not have permission for this action.');
mutated([{ type: 'characterData', target: status.childNodes[0] }]);
assert.equal(status.childNodes[0].nodeValue, 'You do not have permission for this action.');
locale.set('nl'); assert.equal(status.childNodes[0].nodeValue, 'Geen toestemming voor deze actie.');
locale.set('invalid'); assert.equal(locale.language, 'nl');
for (const language of ['nl', 'en']) {
  locale.set(language);
  assert.match(locale.t('Naar RAIN · nog 12 s'), language === 'nl' ? /Naar Regen/ : /To Rain/);
  assert.match(locale.t('Actueel weer: HALLOWEEN'), language === 'nl' ? /Actueel weer/ : /Current weather/);
  for (const [key, pair] of locale.catalog) {
    assert.equal(typeof pair.nl, 'string'); assert.equal(typeof pair.en, 'string');
    assert.equal(locale.t(key), pair[language]);
  }
}
// Every static label must have an explicit catalog entry (except language-neutral literals).
const html = fs.readFileSync('web/index.html', 'utf8');
const neutral = new Set(['◈', '01', '02', '03', '04', '05', '06', 'Esc', '—', 'Champagne', 'Jade']);
const decode = s => s.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>');
for (const match of html.matchAll(/>([^<>]+)</g)) {
  const text = decode(match[1].trim());
  if (text) assert.ok(neutral.has(text) || locale.catalog.has(text), 'Untranslated static text: ' + text);
}
for (const match of html.matchAll(/aria-label="([^"]+)"/g)) assert.ok(locale.catalog.has(decode(match[1])), 'Untranslated accessible label: ' + match[1]);
assert.ok(!html.includes('Actieve serverconfiguratie'));
assert.ok(html.indexOf('setting-locale') > html.indexOf('id="admin"'));
console.log('PASS complete static NL/EN catalog, dynamic text, repeated language switches, preserved drafts/identifiers/names and headadmin-only language selector');
