'use strict';
// Source-text catalog, shared server-selected language. Never stored per device.
// Keep original text nodes so switching languages never rebuilds forms or loses drafts.
(() => {
  const entries = [
    ['Environment console', 'Omgevingsbeheer', 'Environment console'],
    ['ENVIRONMENT CONSOLE', 'OMGEVINGSBEHEER', 'ENVIRONMENT CONSOLE'],
    ['ADMIN CONSOLE', 'BEHEERPANEEL', 'ADMIN CONSOLE'],
    ['Environment', 'Omgeving', 'Environment'],
    ['Weather & time', 'Weer & tijd', 'Weather & time'],
    ['Dashboard', 'Overzicht', 'Dashboard'], ['Weather', 'Weer', 'Weather'],
    ['Time', 'Tijd', 'Time'], ['Settings', 'Instellingen', 'Settings'],
    ['Admin', 'Beheer', 'Administration'], ['Beheer', 'Beheer', 'Administration'],
    ['LIVE ENVIRONMENT', 'ACTUELE OMGEVING', 'LIVE ENVIRONMENT'],
    ['WEATHER & TIME CONTROL', 'WEER- EN TIJDBEHEER', 'WEATHER & TIME CONTROL'],
    ['Dynamic weather', 'Dynamisch weer', 'Dynamic weather'],
    ['Blackout', 'Stroomuitval', 'Blackout'], ['Multiplier', 'Factor', 'Multiplier'],
    ['Nederlands', 'Nederlands', 'Dutch'], ['Engels', 'Engels', 'English'],
    ['Servertaal', 'Servertaal', 'Server language'],
    ['Deze taal geldt voor iedereen, ook na een herstart.', 'Deze taal geldt voor iedereen, ook na een herstart.', 'This language applies to everyone, including after a restart.'],
    ['Pagina’s', 'Pagina’s', 'Pages'], ['Live synchronisatie', 'Live synchronisatie', 'Live synchronization'],
    ['Menu sluiten', 'Menu sluiten', 'Close menu'], ['Sluiten', 'Sluiten', 'Close'],
    ['LIVE OVERZICHT', 'LIVE OVERZICHT', 'LIVE OVERVIEW'],
    ['Beschikbare bediening hangt af van jouw rechten. Kleuren aanpassen kan via Settings.', 'Beschikbare bediening hangt af van jouw rechten. Kleuren aanpassen kan via Instellingen.', 'Available controls depend on your permissions. Change colors in Settings.'],
    ['ACTUEEL WEER', 'ACTUEEL WEER', 'CURRENT WEATHER'], ['Weer', 'Weer', 'Weather'],
    ['Servertijd', 'Servertijd', 'Server time'], ['Globale verlichting', 'Globale verlichting', 'World lighting'],
    ['Weer & overgangen', 'Weer & overgangen', 'Weather & transitions'],
    ['Huidig weer', 'Huidig weer', 'Current weather'], ['Overgang', 'Overgang', 'Transition'],
    ['Automatische cyclus', 'Automatische cyclus', 'Automatic cycle'], ['Volgende beslissing', 'Volgende beslissing', 'Next decision'],
    ['Weer instellen', 'Weer instellen', 'Set weather'], ['Weertype', 'Weertype', 'Weather type'],
    ['Geleidelijk', 'Geleidelijk', 'Gradual'], ['Direct', 'Direct', 'Instant'],
    ['Toepassen', 'Toepassen', 'Apply'], ['Inschakelen', 'Inschakelen', 'Enable'], ['Uitschakelen', 'Uitschakelen', 'Disable'],
    ['ACTUELE SERVERKLOK', 'ACTUELE SERVERKLOK', 'CURRENT SERVER CLOCK'],
    ['Momentopname, elke twee seconden bijgewerkt.', 'Momentopname, elke twee seconden bijgewerkt.', 'Snapshot, updated every two seconds.'],
    ['Bevroren', 'Bevroren', 'Frozen'], ['Tijdsnelheid', 'Tijdsnelheid', 'Time speed'],
    ['Toegestaan bereik', 'Toegestaan bereik', 'Allowed range'], ['Tijd instellen', 'Tijd instellen', 'Set time'],
    ['Uur', 'Uur', 'Hour'], ['Minuut', 'Minuut', 'Minute'], ['Klok', 'Klok', 'Clock'],
    ['Bevriezen', 'Bevriezen', 'Freeze'], ['Hervatten', 'Hervatten', 'Resume'],
    ['MAAK HET PERSOONLIJK', 'MAAK HET PERSOONLIJK', 'MAKE IT YOURS'], ['Jouw uitstraling', 'Jouw uitstraling', 'Your appearance'],
    ['Alleen jouw menu', 'Alleen jouw menu', 'Only your menu'],
    ['Kies een stijl of stel je eigen kleuren samen. Je voorkeur wordt op dit apparaat bewaard.', 'Kies een stijl of stel je eigen kleuren samen. Je voorkeur wordt op dit apparaat bewaard.', 'Choose a style or create your own colors. Your preference is saved on this device.'],
    ['Themapresets', 'Themavoorinstellingen', 'Theme presets'], ['Warm & verfijnd', 'Warm & verfijnd', 'Warm & refined'],
    ['Rustig & natuurlijk', 'Rustig & natuurlijk', 'Calm & natural'], ['Koel & helder', 'Koel & helder', 'Cool & bright'],
    ['Diep & expressief', 'Diep & expressief', 'Deep & expressive'],
    ['Arctic', 'Arctisch', 'Arctic'], ['Amethyst', 'Amethist', 'Amethyst'],
    ['Accentkleur', 'Accentkleur', 'Accent color'], ['Achtergrond', 'Achtergrond', 'Background'], ['Panelen', 'Panelen', 'Panels'],
    ['Accentkleur kiezen', 'Accentkleur kiezen', 'Choose accent color'], ['Accentkleur hexcode', 'Accentkleur hexcode', 'Accent color hex code'],
    ['Achtergrondkleur kiezen', 'Achtergrondkleur kiezen', 'Choose background color'], ['Achtergrond hexcode', 'Achtergrond hexcode', 'Background hex code'],
    ['Paneelkleur kiezen', 'Paneelkleur kiezen', 'Choose panel color'], ['Panelen hexcode', 'Panelen hexcode', 'Panel hex code'],
    ['Persoonlijk thema', 'Persoonlijk thema', 'Personal theme'], ['Standaard herstellen', 'Standaard herstellen', 'Restore defaults'],
    ['Hoofdadminbeheer', 'Hoofdadminbeheer', 'Head administrator'], ['Logs', 'Logs', 'Logs'], ['AUDIT TRAIL', 'LOGBOEK', 'AUDIT TRAIL'], ['Hoofdadminacties en systeemwijzigingen uit deze resourcesessie.', 'Hoofdadminacties en systeemwijzigingen uit deze resourcesessie.', 'Administrator actions and system changes from this resource session.'], ['Oudere logs laden', 'Oudere logs laden', 'Load older logs'], ['Opnieuw laden', 'Opnieuw laden', 'Reload'],
    ['Alleen MSTR_Weather-rechten. Hoofdadminrechten worden uitsluitend buiten het menu via ACE toegekend.', 'Alleen MSTR_Weather-rechten. Hoofdadminrechten worden uitsluitend buiten het menu via ACE toegekend.', 'MSTR_Weather permissions only. Head administrator access is assigned outside this menu through ACE.'],
    ['Serverinstellingen', 'Serverinstellingen', 'Server settings'], ['Overgangsduur (seconden)', 'Overgangsduur (seconden)', 'Transition duration (seconds)'],
    ['Dynamic interval (minuten)', 'Dynamisch interval (minuten)', 'Dynamic interval (minutes)'],
    ['Instant weer toegestaan', 'Directe weerwijziging toegestaan', 'Instant weather changes allowed'],
    ['Sneeuwsporen', 'Sneeuwsporen', 'Snow tracks'], ['Blackout beïnvloedt voertuigen', 'Stroomuitval beïnvloedt voertuigen', 'Blackout affects vehicles'],
    ['Weer en tijd bewaren', 'Weer en tijd bewaren', 'Save weather and time'],
    ['Nieuwe overgangsduur geldt voor volgende overgangen. Een nieuw interval begint opnieuw te tellen. Uitschakelen van bewaren verwijdert geen bestaande opslag.', 'Nieuwe overgangsduur geldt voor volgende overgangen. Een nieuw interval begint opnieuw te tellen. Uitschakelen van bewaren verwijdert geen bestaande opslag.', 'The new duration applies to future transitions. A new interval restarts the countdown. Disabling saving does not delete existing data.'],
    ['Serverinstellingen opslaan', 'Serverinstellingen opslaan', 'Save server settings'], ['Gebruikers & rechten', 'Gebruikers & rechten', 'Users & permissions'],
    ['Opgeslagen of online persoon', 'Opgeslagen of online persoon', 'Saved or online person'],
    ['Nieuwe persoon / identifier invoeren', 'Nieuwe persoon / identifier invoeren', 'New person / enter identifier'],
    ['Naam', 'Naam', 'Name'], ['Vaste identifier', 'Vaste identifier', 'Permanent identifier'],
    ['Menu bekijken', 'Menu bekijken', 'View menu'], ['Weer wijzigen', 'Weer wijzigen', 'Change weather'], ['Tijd wijzigen', 'Tijd wijzigen', 'Change time'],
    ['Menu bekijken is vereist voor alle overige rechten. Alles uitvinken trekt toegang in, ook bij de oude admin-ACE. Hoofdadmin-ACE blijft leidend.', 'Menu bekijken is vereist voor alle overige rechten. Alles uitvinken trekt toegang in, ook bij de oude admin-ACE. Hoofdadmin-ACE blijft leidend.', 'View menu is required for all other permissions. Uncheck everything to revoke access, including legacy admin ACE access. Head administrator ACE takes precedence.'],
    ['Rechten opslaan', 'Rechten opslaan', 'Save permissions'], ['Wachten op server', 'Wachten op server', 'Waiting for server'],
    ['Geen toestemming voor deze actie.', 'Geen toestemming voor deze actie.', 'You do not have permission for this action.'],
    ['Ongeldige invoer.', 'Ongeldige invoer.', 'Invalid input.'],
    ['Er loopt al een overgang. Wacht of kies expliciet Direct.', 'Er loopt al een overgang. Wacht of kies expliciet Direct.', 'A transition is already active. Wait or explicitly choose Instant.'],
    ['Direct weer wijzigen is uitgeschakeld door de hoofdadmin.', 'Direct weer wijzigen is uitgeschakeld door de hoofdadmin.', 'Instant weather changes are disabled by the head administrator.'],
    ['Een andere beheerder heeft wijzigingen opgeslagen. Klik Opnieuw laden en controleer je invoer.', 'Een andere beheerder heeft wijzigingen opgeslagen. Klik Opnieuw laden en controleer je invoer.', 'Another administrator saved changes. Click Reload and check your input.'],
    ['Opslag niet beschikbaar. Controleer de serverconsole; wijzigingen zijn niet bevestigd.', 'Opslag niet beschikbaar. Controleer de serverconsole; wijzigingen zijn niet bevestigd.', 'Storage unavailable. Check the server console; changes are not confirmed.'],
    ['Maximum van 256 opgeslagen gebruikers bereikt.', 'Maximum van 256 opgeslagen gebruikers bereikt.', 'The limit of 256 saved users has been reached.'],
    ['Wacht even voordat je opnieuw klikt.', 'Wacht even voordat je opnieuw klikt.', 'Wait a moment before clicking again.'],
    ['Geen antwoord. De actie kan verwerkt zijn; controleer de actuele toestand vóór opnieuw proberen.', 'Geen antwoord. De actie kan verwerkt zijn; controleer de actuele toestand vóór opnieuw proberen.', 'No reply. The action may have completed; check the current state before trying again.'],
    ['Menu gesloten.', 'Menu gesloten.', 'Menu closed.'], ['Er wordt al een verzoek verwerkt.', 'Er wordt al een verzoek verwerkt.', 'A request is already being processed.'],
    ['Beheeropslag is geblokkeerd. Herstel admin.json en herstart de resource.', 'Beheeropslag is geblokkeerd. Herstel admin.json en herstart de resource.', 'Administration storage is locked. Repair admin.json and restart the resource.'],
    ['Gegevens geladen. Opslaan geldt direct en blijft behouden na een herstart.', 'Gegevens geladen. Opslaan geldt direct en blijft behouden na een herstart.', 'Data loaded. Saved changes apply immediately and survive a restart.'],
    ['Verzoek wordt gecontroleerd…', 'Verzoek wordt gecontroleerd…', 'Checking request…'], ['Beheer geladen.', 'Beheer geladen.', 'Administration loaded.'],
    ['Door de server bevestigd.', 'Door de server bevestigd.', 'Confirmed by the server.'], ['Actie niet uitgevoerd.', 'Actie niet uitgevoerd.', 'Action not performed.'],
    ['Champagne · standaardthema', 'Champagne · standaardthema', 'Champagne · default theme'],
    ['Jouw opgeslagen kleuren', 'Jouw opgeslagen kleuren', 'Your saved colors'],
    ['Opgeslagen thema ongeldig · standaard hersteld', 'Opgeslagen thema ongeldig · standaard hersteld', 'Invalid saved theme · defaults restored'],
    ['Standaardthema geladen · lokale opslag niet leesbaar', 'Standaardthema geladen · lokale opslag niet leesbaar', 'Default theme loaded · local storage unreadable'],
    ['Opgeslagen op dit apparaat', 'Opgeslagen op dit apparaat', 'Saved on this device'],
    ['Kleuren toegepast · opslaan niet mogelijk, alleen deze sessie', 'Kleuren toegepast · opslaan niet mogelijk, alleen deze sessie', 'Colors applied · saving unavailable, this session only'],
    ['Voorbeeld · sluit de kleurkiezer om op te slaan', 'Voorbeeld · sluit de kleurkiezer om op te slaan', 'Preview · close the color picker to save'],
    ['Gebruik een hexcode met zes tekens, bijvoorbeeld #D2B782', 'Gebruik een hexcode met zes tekens, bijvoorbeeld #D2B782', 'Use a six-digit hex code, for example #D2B782'],
    ['Sluiten mislukt. Probeer Esc opnieuw of gebruik F8: mstrmenu.', 'Sluiten mislukt. Probeer Esc opnieuw of gebruik F8: mstrmenu.', 'Could not close. Try Esc again or use F8: mstrmenu.'],
    ['Aan', 'Aan', 'On'], ['Uit', 'Uit', 'Off'], ['Tijd bevroren', 'Tijd bevroren', 'Time frozen'],
    ['Stabiel · geen actieve overgang', 'Stabiel · geen actieve overgang', 'Stable · no active transition'],
    ['Geen countdown', 'Geen aftelling', 'No countdown'],
    ['● Verbonden · serverupdate ontvangen', '● Verbonden · serverupdate ontvangen', '● Connected · server update received'],
    ['Wachten op server · gegevens mogelijk verouderd', 'Wachten op server · gegevens mogelijk verouderd', 'Waiting for server · data may be outdated'],
    ['Zonsopkomst · 05:00–07:00', 'Zonsopkomst · 05:00–07:00', 'Sunrise · 05:00–07:00'],
    ['Overdag · 07:00–19:00', 'Overdag · 07:00–19:00', 'Daytime · 07:00–19:00'],
    ['Zonsondergang · 19:00–21:00', 'Zonsondergang · 19:00–21:00', 'Sunset · 19:00–21:00'],
    ['Nacht · 21:00–05:00', 'Nacht · 21:00–05:00', 'Night · 21:00–05:00'],
    ['EXTRASUNNY', 'Zonnig', 'Extra sunny'], ['CLEAR', 'Helder', 'Clear'], ['CLOUDS', 'Wolken', 'Clouds'],
    ['OVERCAST', 'Zwaarbewolkt', 'Overcast'], ['SMOG', 'Smog', 'Smog'], ['FOGGY', 'Mist', 'Foggy'],
    ['RAIN', 'Regen', 'Rain'], ['THUNDER', 'Onweer', 'Thunder'], ['CLEARING', 'Opklaringen', 'Clearing'],
    ['NEUTRAL', 'Neutraal', 'Neutral'], ['SNOWLIGHT', 'Lichte sneeuw', 'Light snow'], ['SNOW', 'Sneeuw', 'Snow'],
    ['BLIZZARD', 'Sneeuwstorm', 'Blizzard'], ['XMAS', 'Kerstsneeuw', 'Christmas snow'], ['HALLOWEEN', 'Halloween', 'Halloween']
  ];
  const catalog = new Map(entries.map(([key, nl, en]) => [key, { nl, en }]));
  let language = 'nl';
  function t(source) {
    const key = source.trim();
    let value = catalog.get(key)?.[language];
    if (value === undefined) {
      let m;
      if ((m = key.match(/^Snelheid (.+)×$/))) value = (language === 'en' ? 'Speed ' : 'Snelheid ') + m[1] + '×';
      else if ((m = key.match(/^Naar (\w+) · nog (\d+) s$/))) value = language === 'en' ? `To ${t(m[1])} · ${m[2]} s left` : `Naar ${t(m[1])} · nog ${m[2]} s`;
      else if ((m = key.match(/^Over (\d+) s$/))) value = (language === 'en' ? 'In ' : 'Over ') + m[1] + ' s';
      else if ((m = key.match(/^Actueel weer: (.+)$/))) value = (language === 'en' ? 'Current weather: ' : 'Actueel weer: ') + t(m[1]);
      else if ((m = key.match(/^(.* \((?:fivem:\d+|license:[0-9a-f]+)\)) · (hoofdadmin via ACE|online|opgeslagen)$/))) {
        value = m[1] + ' · ' + (language === 'en' ? { 'hoofdadmin via ACE': 'head admin via ACE', online: 'online', opgeslagen: 'saved' }[m[2]] : m[2]);
      }
    }
    return value === undefined ? source : source.replace(key, () => value);
  }
  const originals = new WeakMap();
  function translate(node, key, read, write) {
    const current = read();
    let slots = originals.get(node);
    if (!slots) { slots = new Map(); originals.set(node, slots); }
    let slot = slots.get(key);
    if (!slot || current !== slot.last) slot = { source: current };
    slot.last = t(slot.source); slots.set(key, slot);
    if (current !== slot.last) write(slot.last);
  }
  function visit(node) {
    if (node.parentElement?.closest('[data-no-localize]')) return;
    if (node.nodeType === 3) { translate(node, 'text', () => node.nodeValue, v => { node.nodeValue = v; }); return; }
    if (node.nodeType !== 1 || ['SCRIPT', 'STYLE', 'SVG'].includes(node.tagName) || node.hasAttribute('data-no-localize')) return;
    for (const attr of ['aria-label', 'title']) if (node.hasAttribute(attr)) translate(node, attr, () => node.getAttribute(attr), v => node.setAttribute(attr, v));
    for (const child of node.childNodes) visit(child);
  }
  function refresh() { visit(document.documentElement); }
  window.MSTRLocale = {
    t, catalog,
    get language() { return language; },
    set(value) { if (value !== 'nl' && value !== 'en') return; language = value; document.documentElement.lang = value; refresh(); },
    refresh
  };
  // Translate changed text only; input values and native weather identifiers never change.
  new MutationObserver(records => {
    for (const record of records) {
      if (record.type === 'characterData') visit(record.target);
      else if (record.type === 'attributes') visit(record.target);
      else for (const node of record.addedNodes) visit(node);
    }
  }).observe(document.documentElement, { subtree: true, childList: true, characterData: true, attributes: true, attributeFilter: ['aria-label', 'title'] });
  window.MSTRLocale.set('nl');
})();
