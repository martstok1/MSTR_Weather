'use strict';
// Focused DOM mocks: request lifetime, revocation, draft preservation and safe SVGs.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
class Element {
  constructor(dataset = {}) { this.dataset = dataset; this.hidden = false; this.value = ''; this.events = {}; this.children = []; }
  addEventListener(name, fn) { this.events[name] = fn; }
  querySelector(selector) { return this.children[0] ||= new Element(); }
  replaceChildren(...children) { this.children = children; }
  add(child) { this.children.push(child); }
  reportValidity() { return true; }
  click() { this.events.click?.(); }
  setAttribute(name, value) { this[name] = value; }
}
const ids = new Map();
const el = id => { if (!ids.has(id)) ids.set(id, new Element()); return ids.get(id); };
const rights = ['view', 'weather', 'time', 'dynamic', 'blackout'].map(right => new Element({ right }));
const gates = [...rights.map(e => new Element({ permission: e.dataset.right })), new Element({ permission: 'manage' })];
const buttons = [new Element()];
const dashboard = new Element();
dashboard.events.click = () => { el('admin').hidden = true; };
let resolveRequest, request, calls = 0;
const context = {
  document: {
    getElementById: el,
    querySelectorAll: s => ({ '[data-right]': rights, '[data-permission]': gates, '[data-mutation]': buttons, '[data-action]': [] })[s] || [],
    querySelector: () => dashboard
  },
  window: {}, Option: function(text, value) { this.text = text; this.value = value; },
  GetParentResourceName: () => 'MSTR_Weather',
  fetch: (_url, options) => { calls++; request = JSON.parse(options.body); return new Promise(resolve => { resolveRequest = result => resolve({ json: async () => result }); }); }
};
vm.createContext(context);
vm.runInContext(fs.readFileSync('web/controls.js', 'utf8'), context);
vm.runInContext(fs.readFileSync('web/icons.js', 'utf8'), context);
const controls = context.window.MSTRControls;
const snapshot = { permissions: { view: true, weather: true, manage: true }, weatherTypes: ['CLEAR', 'RAIN'], state: { weather: 'CLEAR', time: { hour: 12, minute: 0 }, timeScale: 2 }, settings: { minScale: 0, maxScale: 10, instantAllowed: true } };
context.window.MSTRReceiveSnapshot = s => controls.update(s);
const tick = () => new Promise(resolve => setImmediate(resolve));
(async () => {
  controls.update(snapshot);
  assert.equal(gates.at(-1).hidden, false);
  el('time-hour').value = 19;
  controls.update(snapshot);
  assert.equal(el('time-hour').value, 19, 'polling must preserve drafts');
  controls.page('admin');
  assert.equal(request.action, 'panel');
  controls.page('admin'); assert.equal(calls, 1, 'only one pending request');
  controls.close(); el('app').hidden = true;
  resolveRequest({ ok: true, panel: {} }); await tick();
  assert.equal(el('admin-content').hidden, true, 'late reply cannot restore closed admin panel');
  el('app').hidden = false; controls.update(snapshot);
  controls.page('admin');
  resolveRequest({ ok: true, panel: { revision: 7, users: [{ identifier: 'fivem:2', name: '<img onerror=alert(1)>', rights: { view: true } }], online: [], settings: {}, minInterval: 1, maxInterval: 60 } });
  await tick();
  assert.equal(el('admin-content').hidden, false);
  assert.match(el('user-select').children[1].text, /^<img/);
  assert.equal(el('user-select').innerHTML, undefined, 'names stay text options');
  el('admin').hidden = false;
  controls.update({ ...snapshot, permissions: { view: true } });
  assert.equal(el('admin-content').hidden, true);
  assert.equal(el('admin').hidden, true);
  assert.equal(el('user-select').children.length, 1, 'revocation clears identities');
  el('weather-form').events.submit({ preventDefault() {} });
  resolveRequest({ ok: false, reason: 'forbidden' }); await tick();
  assert.match(el('action-status').textContent, /Geen toestemming/);
  assert.equal(buttons[0].disabled, false);
  for (const weather of ['CLEAR','EXTRASUNNY','CLOUDS','OVERCAST','RAIN','THUNDER','CLEARING','NEUTRAL','SMOG','FOGGY','SNOW','SNOWLIGHT','BLIZZARD','XMAS','HALLOWEEN']) {
    context.window.MSTRIcons({ weather, dynamicWeather: true, blackout: false });
    assert.match(el('weather-icon').innerHTML, /^<svg/);
    assert.doesNotMatch(el('weather-icon').innerHTML, /undefined/);
  }
  context.window.MSTRIcons({ weather: '<img onerror=alert(1)>', dynamicWeather: false, blackout: true });
  assert.doesNotMatch(el('weather-icon').innerHTML, /onerror/);
  assert.equal(el('blackout-icon').dataset.icon, 'bulbOff');
  assert.equal(el('dynamic-icon').dataset.icon, 'pause');
  console.log('PASS controls: drafts, pending/late responses, revocation, safe names, errors and all weather/status SVGs');
})().catch(error => { console.error(error); process.exitCode = 1; });
