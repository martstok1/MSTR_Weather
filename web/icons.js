'use strict';
// Original SVGs; only constant markup enters innerHTML.
(() => {
  const cloud = '<path d="M18 40h31a10 10 0 0 0 0-20 15 15 0 0 0-28-4 12 12 0 0 0-3 24Z" fill="currentColor" fill-opacity=".12"/>';
  const sun = '<circle cx="32" cy="28" r="11" class="icon-accent" fill="currentColor" fill-opacity=".14"/><path d="M32 9V4m0 48v-5M13 28H8m48 0h-5M18 14l-4-4m36 36-4-4m0-28 4-4M14 46l4-4" class="icon-accent"/>';
  const snow = '<path d="M20 47v10m-4-8 8 6m0-6-8 6m25-8v10m-4-8 8 6m0-6-8 6" class="icon-accent"/>';
  const parts = {
    sun, cloud,
    rain: cloud + '<path d="m22 46-3 7m16-7-3 7m16-7-3 7" class="icon-accent"/>',
    snow: cloud + snow,
    fog: cloud + '<path d="M10 46h35m-28 7h37m-44 6h27" class="icon-accent"/>',
    partly: '<g transform="translate(4 -3) scale(.7)">' + sun + '</g>' + cloud,
    thunder: cloud + '<path d="m35 38-10 13h8l-4 11 15-18h-9l4-6" class="icon-accent" fill="currentColor" fill-opacity=".25"/>',
    blizzard: cloud + snow + '<path d="M5 25h10M2 31h10"/>',
    halloween: '<path d="M28 5a17 17 0 0 0 21 23A20 20 0 1 1 28 5Z" class="icon-accent"/>' + '<g transform="translate(8 15) scale(.8)">' + cloud + '</g>',
    christmas: cloud + snow + '<path d="m50 6 2 4 5 1-4 3 1 5-4-2-4 2 1-5-4-3 5-1Z" class="icon-accent"/>',
    clock: '<circle cx="32" cy="32" r="22"/><path d="M32 16v17l11 6" class="icon-accent"/>',
    cycle: '<path d="M51 24a21 21 0 0 0-36-7l-5 7m0-12v12h12M13 40a21 21 0 0 0 36 7l5-7m0 12V40H42" class="icon-accent"/>',
    pause: '<path d="M24 23v18m16-18v18"/><circle cx="32" cy="32" r="23" stroke-opacity=".4"/>',
    bulb: '<path d="M23 44v-3a17 17 0 1 1 18 0v3Zm0 6h18m-15 6h12M32 5V1M9 17l-5-3m51 3 5-3M8 35H2m54 0h6"/><path d="M28 41V29m8 12V29m-8 0 4 4 4-4" class="icon-accent"/>',
    bulbOff: '<path d="M23 44v-3a17 17 0 1 1 18 0v3Zm0 6h18m-15 6h12" stroke-opacity=".45"/><path d="m8 8 48 48" class="icon-accent"/>'
  };
  const weather = { EXTRASUNNY: 'sun', CLEAR: 'sun', CLOUDS: 'cloud', OVERCAST: 'cloud', RAIN: 'rain', THUNDER: 'thunder', CLEARING: 'partly', NEUTRAL: 'partly', SMOG: 'fog', FOGGY: 'fog', SNOW: 'snow', SNOWLIGHT: 'snow', BLIZZARD: 'blizzard', XMAS: 'christmas', HALLOWEEN: 'halloween' };
  function draw(id, kind) {
    const element = document.getElementById(id);
    if (element.dataset.icon === kind) return;
    element.dataset.icon = kind;
    element.innerHTML = '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + parts[kind] + '</svg>';
  }
  window.MSTRIcons = state => {
    draw('weather-icon', weather[state.weather] || 'cloud');
    document.getElementById('weather-icon').setAttribute('aria-label', 'Actueel weer: ' + state.weather);
    draw('time-icon', 'clock');
    draw('dynamic-icon', state.dynamicWeather ? 'cycle' : 'pause');
    draw('blackout-icon', state.blackout ? 'bulbOff' : 'bulb');
  };
})();
