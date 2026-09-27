'use strict';
(() => {
  const el = id => document.getElementById(id);
  let capabilities = {}, panel = null, busy = false, initialized = false, generation = 0;
  let selectedUsers = new Map();
  const messages = {
    forbidden: 'Geen toestemming voor deze actie.', invalid: 'Ongeldige invoer.',
    transitioning: 'Er loopt al een overgang. Wacht of kies expliciet Direct.',
    instant_disabled: 'Direct weer wijzigen is uitgeschakeld door de hoofdadmin.',
    conflict: 'Een andere beheerder heeft wijzigingen opgeslagen. Klik Opnieuw laden en controleer je invoer.',
    storage: 'Opslag niet beschikbaar. Controleer de serverconsole; wijzigingen zijn niet bevestigd.',
    limit: 'Maximum van 256 opgeslagen gebruikers bereikt.', rate: 'Wacht even voordat je opnieuw klikt.',
    timeout: 'Geen antwoord. De actie kan verwerkt zijn; controleer de actuele toestand vóór opnieuw proberen.',
    closed: 'Menu gesloten.', busy: 'Er wordt al een verzoek verwerkt.'
  };
  function lockButtons() {
    document.querySelectorAll('[data-mutation]').forEach(button => { button.disabled = busy; });
    if (!panel || panel.locked) {
      el('server-settings-form').querySelector('button[type="submit"]').disabled = true;
      el('user-form').querySelector('button[type="submit"]').disabled = true;
    }
  }
  function fillUser() {
    const user = selectedUsers.get(el('user-select').value);
    el('user-identifier').value = user ? user.identifier : '';
    el('user-name').value = user ? user.name : '';
    document.querySelectorAll('[data-right]').forEach(input => { input.checked = user?.rights?.[input.dataset.right] === true; });
  }
  function renderPanel(value) {
    panel = value;
    el('admin-content').hidden = false;
    el('admin-storage-status').textContent = value.locked ? 'Beheeropslag is geblokkeerd. Herstel admin.json en herstart de resource.' : 'Gegevens geladen. Opslaan geldt direct en blijft behouden na een herstart.';
    const s = value.settings;
    el('setting-locale').value = s.locale;
    el('setting-duration').value = s.transitionSeconds;
    el('setting-interval').value = s.dynamicIntervalMinutes;
    el('setting-interval').min = value.minInterval;
    el('setting-interval').max = value.maxInterval;
    el('setting-instant').checked = s.instantAllowed;
    el('setting-snow').checked = s.snowTrails;
    el('setting-vehicles').checked = s.affectVehicles;
    el('setting-persistence').checked = s.persistenceEnabled;
    const select = el('user-select'), previous = select.value;
    select.replaceChildren(new Option('Nieuwe persoon / identifier invoeren', ''));
    selectedUsers = new Map();
    for (const person of value.online) selectedUsers.set(person.identifier, { ...person, online: true });
    for (const user of value.users) selectedUsers.set(user.identifier, { ...selectedUsers.get(user.identifier), ...user });
    for (const user of selectedUsers.values()) {
      const suffix = user.superadmin ? ' · hoofdadmin via ACE' : user.online ? ' · online' : ' · opgeslagen';
      select.add(new Option(user.name + ' (' + user.identifier + ')' + suffix, user.identifier));
    }
    select.value = selectedUsers.has(previous) ? previous : '';
    fillUser();
  }
  async function send(action, payload = {}) {
    if (busy) return;
    busy = true; lockButtons();
    const current = generation;
    el('action-status').textContent = 'Verzoek wordt gecontroleerd…';
    try {
      const response = await fetch('https://' + GetParentResourceName() + '/action', {
        method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ action, payload })
      });
      const result = await response.json();
      if (generation !== current || el('app').hidden) return;
      if (result.snapshot) window.MSTRReceiveSnapshot(result.snapshot);
      if (generation !== current || el('app').hidden) return;
      if (result.panel && capabilities.manage) renderPanel(result.panel);
      el('action-status').textContent = result.ok ? (action === 'panel' ? 'Beheer geladen.' : 'Door de server bevestigd.') : (messages[result.reason] || 'Actie niet uitgevoerd.');
    } catch {
      if (generation === current) el('action-status').textContent = messages.timeout;
    } finally {
      if (generation === current) { busy = false; lockButtons(); }
    }
  }
  const bindForm = (id, action, payload) => {
    el(id).noValidate = true;
    el(id).addEventListener('submit', event => {
      event.preventDefault();
      if (el(id).checkValidity()) send(action, payload());
      else el('action-status').textContent = messages.invalid;
    });
  };
  bindForm('weather-form', 'weather', () => ({ weather: el('weather-choice').value, instant: el('weather-mode').value === 'instant' }));
  bindForm('time-form', 'time', () => ({ hour: Number(el('time-hour').value), minute: Number(el('time-minute').value) }));
  bindForm('scale-form', 'scale', () => ({ value: Number(el('time-scale').value) }));
  document.querySelectorAll('[data-action]').forEach(button => button.addEventListener('click', () => {
    send(button.dataset.action, { value: button.dataset.enabled === 'true' });
  }));
  bindForm('server-settings-form', 'settings', () => ({ revision: panel?.revision, settings: {
    locale: el('setting-locale').value,
    transitionSeconds: Number(el('setting-duration').value), dynamicIntervalMinutes: Number(el('setting-interval').value),
    instantAllowed: el('setting-instant').checked, snowTrails: el('setting-snow').checked,
    affectVehicles: el('setting-vehicles').checked, persistenceEnabled: el('setting-persistence').checked
  } }));
  bindForm('user-form', 'user', () => ({ revision: panel?.revision,
    identifier: el('user-identifier').value.trim(), name: el('user-name').value.trim(),
    rights: Object.fromEntries([...document.querySelectorAll('[data-right]')].map(input => [input.dataset.right, input.checked]))
  }));
  el('user-select').addEventListener('change', fillUser);
  el('admin-refresh').addEventListener('click', () => send('panel'));
  window.MSTRControls = {
    update(snapshot) {
      capabilities = snapshot.permissions || {};
      document.querySelectorAll('[data-permission]').forEach(element => { element.hidden = !capabilities[element.dataset.permission]; });
      if (!capabilities.manage) {
        panel = null; selectedUsers.clear(); el('admin-content').hidden = true;
        el('user-select').replaceChildren(new Option('Nieuwe persoon / identifier invoeren', ''));
        fillUser();
        if (!el('admin').hidden) document.querySelector('[data-page="dashboard"]').click();
      }
      if (!initialized) {
        el('weather-choice').replaceChildren(...(snapshot.weatherTypes || []).map(type => new Option(type, type)));
        el('weather-choice').value = snapshot.state.weather;
        el('time-hour').value = snapshot.state.time.hour;
        el('time-minute').value = snapshot.state.time.minute;
        el('time-scale').value = snapshot.state.timeScale;
        initialized = true;
      }
      el('time-scale').min = snapshot.settings.minScale;
      el('time-scale').max = snapshot.settings.maxScale;
      el('weather-mode').querySelector('[value="instant"]').disabled = !snapshot.settings.instantAllowed;
      if (!snapshot.settings.instantAllowed) el('weather-mode').value = 'smooth';
      lockButtons();
    },
    page(name) { if (name === 'admin' && capabilities.manage && !panel) send('panel'); },
    close() {
      generation++; busy = false; initialized = false; capabilities = {}; panel = null;
      selectedUsers.clear(); el('admin-content').hidden = true;
      el('user-select').replaceChildren(new Option('Nieuwe persoon / identifier invoeren', ''));
      fillUser(); el('action-status').textContent = '';
      document.querySelectorAll('[data-permission]').forEach(element => { element.hidden = true; });
    }
  };
})();
