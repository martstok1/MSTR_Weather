'use strict';
(() => {
  const list = document.getElementById('logs-list'), status = document.getElementById('logs-status'), more = document.getElementById('logs-more');
  list.setAttribute('data-no-localize', '');
  status.setAttribute('data-no-localize', '');
  let nextBefore = null, rows = [], enabled = true, limit = 200, language = null;
  const names = {
    weather: ['Weer', 'Weather'], time: ['Tijd', 'Time'], freeze: ['Bevriezen', 'Freeze'],
    scale: ['Tijdsnelheid', 'Time speed'], dynamic: ['Dynamisch weer', 'Dynamic weather'],
    blackout: ['Stroomuitval', 'Blackout'], settings: ['Instellingen', 'Settings'], user: ['Gebruiker', 'User'],
    startup: ['Resource gestart', 'Resource started'], transition: ['Overgang voltooid', 'Transition completed'],
    command: ['Commando', 'Command'], nui: ['Menu', 'Menu'], engine: ['Systeem', 'System'],
    ADMIN: ['Beheerder', 'Administrator'], SYSTEM: ['Systeem', 'System'],
    target: ['Doelweer', 'Target weather'], mode: ['Overgangstype', 'Transition mode'], duration: ['Duur', 'Duration'],
    instant: ['Direct', 'Instant'], smooth: ['Geleidelijk', 'Gradual'], unchanged: ['Ongewijzigd', 'Unchanged'],
    hour: ['Uur', 'Hour'], minute: ['Minuut', 'Minute'], second: ['Seconde', 'Second'],
    name: ['Naam', 'Name'], identifier: ['Identifier', 'Identifier'], rights: ['Rechten', 'Permissions'],
    view: ['Menu bekijken', 'View menu'], locale: ['Taal', 'Language'], nl: ['Nederlands', 'Dutch'], en: ['Engels', 'English'],
    transitionSeconds: ['Overgangsduur', 'Transition duration'], instantAllowed: ['Direct wijzigen toegestaan', 'Instant changes allowed'],
    snowTrails: ['Sneeuwsporen', 'Snow tracks'], dynamicIntervalMinutes: ['Dynamisch interval', 'Dynamic interval'],
    affectVehicles: ['Voertuigverlichting', 'Vehicle lights'], persistenceEnabled: ['Weer en tijd bewaren', 'Save weather and time'],
    dynamicWeather: ['Dynamisch weer', 'Dynamic weather'], weatherTransition: ['Weerovergang', 'Weather transition'],
    active: ['Actief', 'Active'], timeFrozen: ['Tijd bevroren', 'Time frozen'], timeScale: ['Tijdsnelheid', 'Time speed']
  };
  const en = () => window.MSTRLocale.language === 'en';
  const label = key => names[key]?.[en() ? 1 : 0] || key;
  function value(v, key) {
    if (v == null) return '—';
    if (typeof v === 'boolean') return en() ? (v ? 'On' : 'Off') : (v ? 'Aan' : 'Uit');
    if (typeof v === 'object') return Object.entries(v).map(([k, item]) => label(k) + ': ' + value(item, k)).join('; ');
    if (key === 'name' || key === 'identifier') return String(v);
    return window.MSTRLocale.t(label(String(v)));
  }
  function draw() {
    language = window.MSTRLocale.language;
    list.replaceChildren();
    for (const e of rows) {
      const a = document.createElement('article'); a.className = 'log-entry';
      const h = document.createElement('div'); h.className = 'log-header';
      const title = document.createElement('strong'); title.textContent = label(e.type) + ' · ' + label(e.action);
      const time = document.createElement('time'); time.textContent = new Date(Number(e.timestamp) * 1000).toLocaleString(en() ? 'en-GB' : 'nl-NL');
      h.append(title, time);
      const p = document.createElement('p'); p.textContent = [e.player, e.identifier, label(e.source)].filter(Boolean).join(' · ');
      const c = document.createElement('code'); c.textContent = value(e.oldValue) + ' → ' + value(e.newValue);
      a.append(h, p, c); list.append(a);
    }
    more.hidden = !nextBefore;
    status.textContent = !enabled ? (en() ? 'Logging is disabled.' : 'Logging is uitgeschakeld.') :
      en() ? rows.length + ' entries shown · up to ' + limit + ' retained this session.' : rows.length + ' regels zichtbaar · maximaal ' + limit + ' bewaard deze sessie.';
  }
  function render(page, append) {
    const incoming = Array.isArray(page.entries) ? page.entries : [];
    rows = (append ? rows : []).concat(incoming).filter((e, i, all) => all.findIndex(x => x.id === e.id) === i).slice(0, 1000);
    nextBefore = page.nextBefore || null; enabled = page.enabled !== false; limit = page.limit; draw();
  }
  window.MSTRLogs = {
    render, locale() { if (language !== null && language !== window.MSTRLocale.language) draw(); },
    request: before => window.MSTRControls.send('logs', before ? { before } : {}),
    reset() { nextBefore = null; rows = []; language = null; list.replaceChildren(); status.textContent = ''; more.hidden = true; }
  };
  document.getElementById('logs-refresh').addEventListener('click', () => window.MSTRLogs.request());
  more.addEventListener('click', () => window.MSTRLogs.request(nextBefore));
})();
