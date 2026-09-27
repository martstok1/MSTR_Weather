'use strict';
(() => {
  const logo = document.getElementById('brand-logo'), fallback = document.getElementById('brand-fallback'), name = document.getElementById('brand-name');
  let selected = null;
  const defaultPath = '../images/default.svg';
  window.MSTRBranding = { apply(value) {
    if (!value || typeof value !== 'object') return;
    const serverName = typeof value.name === 'string' && value.name.trim() ? value.name.trim().slice(0, 160) : 'MSTR Weather';
    if (name.textContent !== serverName) name.textContent = serverName;
    name.hidden = value.showName === false;
    const valid = value.logo === 'images/default.svg' || (typeof value.logo === 'string' && /^images\/[\w-]+\.(?:png|webp)$/.test(value.logo));
    const path = valid ? '../' + value.logo : defaultPath;
    if (selected === path) return;
    selected = path;
    let usingDefault = path === defaultPath;
    logo.onerror = () => {
      if (!usingDefault) { usingDefault = true; logo.src = defaultPath; }
      else { logo.hidden = true; fallback.hidden = false; }
    };
    logo.hidden = false; fallback.hidden = true; logo.src = path;
  }};
})();
