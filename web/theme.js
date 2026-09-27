'use strict';
// Cosmetic, device-local preferences only. Never sent to Lua/server or state.json.
(() => {
  const key = 'mstr_weather.menuTheme.v1';
  const presets = {
    champagne: { accent: '#d2b782', background: '#141619', surface: '#1e2126' },
    jade: { accent: '#85d8b6', background: '#111b1a', surface: '#1c2b28' },
    arctic: { accent: '#8abff0', background: '#111923', surface: '#1c2a39' },
    amethyst: { accent: '#bea0ed', background: '#1a1521', surface: '#292131' }
  };
  const fields = ['accent', 'background', 'surface'];
  const root = document.getElementById('app');
  const status = document.getElementById('theme-status');
  const hex = value => typeof value === 'string' && /^#[0-9a-f]{6}$/i.test(value);
  const valid = value => value && typeof value === 'object' && fields.every(field => hex(value[field]));
  const rgb = value => [1, 3, 5].map(start => parseInt(value.slice(start, start + 2), 16));
  const toHex = channels => '#' + channels.map(n => Math.round(n).toString(16).padStart(2, '0')).join('');
  const mix = (a, b, fraction) => toHex(rgb(a).map((n, i) => n * (1 - fraction) + rgb(b)[i] * fraction));
  const luminance = value => rgb(value).map(n => {
    const channel = n / 255;
    return channel <= .04045 ? channel / 12.92 : ((channel + .055) / 1.055) ** 2.4;
  }).reduce((sum, n, i) => sum + n * [.2126, .7152, .0722][i], 0);
  const contrast = (a, b) => (Math.max(luminance(a), luminance(b)) + .05) / (Math.min(luminance(a), luminance(b)) + .05);
  const foreground = color => contrast('#ffffff', color) >= contrast('#000000', color) ? '#ffffff' : '#000000';
  let theme = { ...presets.champagne };
  let loadMessage = 'Champagne · standaardthema';
  try {
    const raw = localStorage.getItem(key);
    if (raw !== null) {
      const stored = JSON.parse(raw);
      if (stored && stored.version === 1 && valid(stored.colors)) {
        theme = Object.fromEntries(fields.map(field => [field, stored.colors[field].toLowerCase()]));
        loadMessage = 'Jouw opgeslagen kleuren';
      } else loadMessage = 'Opgeslagen thema ongeldig · standaard hersteld';
    }
  } catch { loadMessage = 'Standaardthema geladen · lokale opslag niet leesbaar'; }

  function apply() {
    const set = (name, value) => root.style.setProperty('--' + name, value);
    set('accent', theme.accent);
    set('accent-rgb', rgb(theme.accent).join(', '));
    set('accent-ink', contrast(theme.accent, theme.background) >= 4.5 ? theme.accent : foreground(theme.background));
    set('accent-text', foreground(theme.accent));
    set('bg', theme.background);
    set('surface', theme.surface);
    const sidebar = mix(theme.background, '#000000', .22);
    set('sidebar', sidebar);
    for (const [prefix, background] of [['', theme.background], ['surface-', theme.surface], ['sidebar-', sidebar]]) {
      const text = foreground(background);
      set(prefix + 'text', text);
      const muted = mix(background, text, .7);
      set(prefix + 'muted', contrast(muted, background) >= 4.5 ? muted : text);
      set(prefix + 'line', mix(background, text, .18));
    }
    document.querySelectorAll('[data-color]').forEach(input => { input.value = theme[input.dataset.color]; });
    document.querySelectorAll('[data-hex]').forEach(input => {
      input.value = theme[input.dataset.hex];
      input.removeAttribute('aria-invalid');
    });
    document.querySelectorAll('[data-theme]').forEach(button => {
      const preset = presets[button.dataset.theme];
      button.setAttribute('aria-pressed', String(fields.every(field => theme[field] === preset[field])));
    });
  }

  function save() {
    try {
      localStorage.setItem(key, JSON.stringify({ version: 1, colors: theme }));
      status.textContent = 'Opgeslagen op dit apparaat';
    } catch { status.textContent = 'Kleuren toegepast · opslaan niet mogelijk, alleen deze sessie'; }
  }

  document.querySelectorAll('[data-theme]').forEach(button => button.addEventListener('click', () => {
    theme = { ...presets[button.dataset.theme] };
    apply(); save();
  }));
  document.querySelectorAll('[data-color]').forEach(input => {
    input.addEventListener('input', () => {
      if (!hex(input.value)) return;
      theme[input.dataset.color] = input.value.toLowerCase();
      apply();
      status.textContent = 'Voorbeeld · sluit de kleurkiezer om op te slaan';
    });
    input.addEventListener('change', () => {
      if (!hex(input.value)) return;
      theme[input.dataset.color] = input.value.toLowerCase();
      apply(); save();
    });
  });
  document.querySelectorAll('[data-hex]').forEach(input => {
    const change = () => {
      const value = input.value.trim();
      if (!hex(value)) {
        input.setAttribute('aria-invalid', 'true');
        status.textContent = 'Gebruik een hexcode met zes tekens, bijvoorbeeld #D2B782';
        return;
      }
      theme[input.dataset.hex] = value.toLowerCase();
      apply(); save();
    };
    input.addEventListener('change', change);
    input.addEventListener('keydown', event => { if (event.key === 'Enter') change(); });
  });
  document.getElementById('theme-reset').addEventListener('click', () => {
    theme = { ...presets.champagne };
    apply(); save();
  });
  apply();
  status.textContent = loadMessage;
})();
