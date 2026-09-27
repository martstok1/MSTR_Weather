'use strict';
const app = document.getElementById('app');
const connection = document.getElementById('connection');
let receivedAt = 0;
let statusTimer = null;
const yesNo = value => value === true ? 'Aan' : 'Uit';
const pad = value => String(value).padStart(2, '0');

async function callback(name) {
  const response = await fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: '{}'
  });
  return response.json();
}

function hide() {
  window.MSTRControls.close();
  app.hidden = true;
  clearInterval(statusTimer);
  statusTimer = null;
}

async function close() {
  try { await callback('close'); hide(); }
  catch { connection.textContent = 'Sluiten mislukt. Probeer Esc opnieuw of gebruik F8: mstrmenu.'; }
}

document.getElementById('close').addEventListener('click', close);
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && !app.hidden) { event.preventDefault(); close(); }
});
document.querySelectorAll('[data-page]').forEach(button => {
  button.addEventListener('click', () => {
    document.querySelectorAll('[data-page]').forEach(item => item.removeAttribute('aria-current'));
    button.setAttribute('aria-current', 'page');
    document.querySelectorAll('.page').forEach(page => { page.hidden = page.id !== button.dataset.page; });
    document.getElementById('page-title').textContent = button.dataset.page.charAt(0).toUpperCase() + button.dataset.page.slice(1);
    window.MSTRControls.page(button.dataset.page);
  });
});

window.MSTRReceiveSnapshot = p => {
  if (p && p.allowed === false) { hide(); return; }
  if (!p || p.allowed !== true || !p.state || !p.state.time || !p.state.weatherTransition || !p.settings) return;
  const s = p.state, c = p.settings;
  const values = {
    weather: s.weather,
    clock: `${pad(s.time.hour)}:${pad(s.time.minute)}:${pad(s.time.second)}`,
    clockMode: s.timeFrozen ? 'Tijd bevroren' : `Snelheid ${s.timeScale}×`,
    transition: s.weatherTransition.active ? `Naar ${s.weatherTransition.target} · nog ${Math.ceil(p.transitionRemaining || 0)} s` : 'Stabiel · geen actieve overgang',
    dynamic: yesNo(s.dynamicWeather),
    next: s.dynamicWeather && Number.isFinite(p.nextDynamicSeconds) ? `Over ${Math.ceil(p.nextDynamicSeconds)} s` : 'Geen countdown',
    blackout: yesNo(s.blackout), frozen: yesNo(s.timeFrozen), scale: `${s.timeScale}×`,
    scaleRange: `${c.minScale}× – ${c.maxScale}×`, duration: `${c.transitionSeconds} seconden`,
    instant: yesNo(c.instantAllowed), snow: yesNo(c.snowTrails), interval: `${c.dynamicIntervalMinutes} minuten`,
    vehicles: yesNo(c.affectVehicles), persistence: yesNo(c.persistenceEnabled)
  };
  document.querySelectorAll('[data-value]').forEach(element => { element.textContent = values[element.dataset.value] ?? '—'; });
  const wasHidden = app.hidden;
  app.hidden = false;
  window.MSTRControls.update(p);
  window.MSTRIcons(s);
  receivedAt = Date.now();
  connection.textContent = '● Verbonden · serverupdate ontvangen';
  if (!statusTimer) statusTimer = setInterval(() => {
    if (Date.now() - receivedAt > 5000) connection.textContent = 'Wachten op server · gegevens mogelijk verouderd';
  }, 1000);
  if (wasHidden) {
    document.querySelector('[data-page="dashboard"]').click();
    document.getElementById('close').focus();
  }
};

window.addEventListener('message', event => {
  const message = event.data;
  if (!message || typeof message !== 'object') return;
  if (message.action === 'close') { hide(); return; }
  if (message.action === 'snapshot') window.MSTRReceiveSnapshot(message.payload);
});

// The page can become ready after Lua has loaded; retry this handshake only.
async function ready() {
  try { await callback('ready'); }
  catch { setTimeout(ready, 1000); }
}
ready();
