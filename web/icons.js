'use strict';
// Original SVGs; only constant markup enters innerHTML.
(() => {
  const cloud = '<path d="M18 40h31a10 10 0 0 0 0-20 15 15 0 0 0-28-4 12 12 0 0 0-3 24Z" fill="currentColor" fill-opacity=".12"/>';
  const sun = '<circle cx="32" cy="28" r="11" class="icon-accent" fill="currentColor" fill-opacity=".14"/><path d="M32 9V4m0 48v-5M13 28H8m48 0h-5M18 14l-4-4m36 36-4-4m0-28 4-4M14 46l4-4" class="icon-accent"/>';
  const flake = x => '<path d="M' + x + ' 46v12m-5-9 10 6m0-6-10 6" class="icon-accent"/>';
  const snow = flake(20) + flake(43);
  const opaqueCloud = cloud.replace('fill="currentColor" fill-opacity=".12"', 'fill="var(--surface)"');
  const horizon = '<path d="M7 42h50m-43 7h36m-29 7h22"/>';
  const parts = {
    sun, cloud,
    clouds: '<g transform="translate(3 0) scale(.62)">' + cloud + '</g><g transform="translate(23 9) scale(.62)">' + opaqueCloud + '</g><g transform="translate(6 24) scale(.67)">' + opaqueCloud + '</g>',
    rain: cloud + '<path d="m22 46-3 7m16-7-3 7m16-7-3 7" class="icon-accent"/>',
    snow: cloud + snow,
    snowlight: cloud + flake(32),
    fog: cloud + '<path d="M10 46h35m-28 7h37m-44 6h27" class="icon-accent"/>',
    smog: '<circle cx="44" cy="18" r="10" class="icon-accent" stroke-opacity=".5"/><path d="M8 29h38m-31 7h42M6 43h36m-24 7h37m-44 7h29"/>',
    partly: '<g transform="translate(20 -1) scale(.72)">' + sun + '</g><g transform="translate(0 14) scale(.9)">' + opaqueCloud + '</g>',
    neutral: '<circle cx="32" cy="28" r="13" class="icon-accent"/><path d="M12 48h40m-32 7h24" stroke-opacity=".5"/>',
    thunder: cloud + '<path d="m35 38-10 13h8l-4 11 15-18h-9l4-6" class="icon-accent" fill="currentColor" fill-opacity=".25"/>',
    blizzard: cloud + flake(13) + flake(32) + flake(51) + '<path d="M3 14h18M1 21h14m-12 8h9"/>',
    halloween: '<circle cx="30" cy="27" r="21" class="icon-accent" fill="currentColor" fill-opacity=".15"/><circle cx="21" cy="18" r="4" stroke-opacity=".3"/><path d="m20 39 10-5 8 6 1-7 4 3 4-3 1 7 8-6 7 5-6 2-2 7-6-1-6 8-6-8-6 1-2-7Z" fill="var(--surface)"/>',
    night: '<path d="M39 8a23 23 0 1 0 16 35A24 24 0 0 1 39 8Z" class="icon-accent" fill="currentColor" fill-opacity=".12"/><path d="M49 9v8m-4-4h8M55 25v6m-3-3h6"/>',
    sunrise: '<path d="M17 40a15 15 0 0 1 30 0M32 19V6m-5 5 5-5 5 5M13 25l-5-5m43 5 5-5" class="icon-accent"/>' + horizon,
    sunset: '<path d="M17 40a15 15 0 0 1 30 0M32 6v13m-5-5 5 5 5-5M13 25l-5-5m43 5 5-5" class="icon-accent"/>' + horizon,
    christmas: cloud + snow + '<path d="m50 6 2 4 5 1-4 3 1 5-4-2-4 2 1-5-4-3 5-1Z" class="icon-accent"/>',
    clock: '<circle cx="32" cy="32" r="22"/><path d="M32 16v17l11 6" class="icon-accent"/>',
    cycle: '<path d="M51 24a21 21 0 0 0-36-7l-5 7m0-12v12h12M13 40a21 21 0 0 0 36 7l5-7m0 12V40H42" class="icon-accent"/>',
    pause: '<path d="M24 23v18m16-18v18"/><circle cx="32" cy="32" r="23" stroke-opacity=".4"/>',
    bulb: '<path d="M23 44v-3a17 17 0 1 1 18 0v3Zm0 6h18m-15 6h12M32 5V1M9 17l-5-3m51 3 5-3M8 35H2m54 0h6"/><path d="M28 41V29m8 12V29m-8 0 4 4 4-4" class="icon-accent"/>',
    bulbOff: '<path d="M23 44v-3a17 17 0 1 1 18 0v3Zm0 6h18m-15 6h12" stroke-opacity=".45"/><path d="m8 8 48 48" class="icon-accent"/>'
  };
  const weather = { EXTRASUNNY: 'sun', CLEAR: 'sun', CLOUDS: 'clouds', OVERCAST: 'cloud', RAIN: 'rain', THUNDER: 'thunder', CLEARING: 'partly', NEUTRAL: 'neutral', SMOG: 'smog', FOGGY: 'fog', SNOW: 'snow', SNOWLIGHT: 'snowlight', BLIZZARD: 'blizzard', XMAS: 'christmas', HALLOWEEN: 'halloween' };
  window.MSTRDaypart = hour => {
    if (hour >= 5 && hour < 7) return { icon: 'sunrise', label: 'Zonsopkomst · 05:00–07:00' };
    if (hour >= 7 && hour < 19) return { icon: 'sun', label: 'Overdag · 07:00–19:00' };
    if (hour >= 19 && hour < 21) return { icon: 'sunset', label: 'Zonsondergang · 19:00–21:00' };
    return { icon: 'night', label: 'Nacht · 21:00–05:00' };
  };
  function draw(id, kind) {
    const element = document.getElementById(id);
    if (element.dataset.icon === kind) return;
    element.dataset.icon = kind;
    element.innerHTML = '<svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + parts[kind] + '</svg>';
  }
  window.MSTRIcons = state => {
    draw('weather-icon', Object.hasOwn(weather, state.weather) ? weather[state.weather] : 'cloud');
    document.getElementById('weather-icon').setAttribute('aria-label', 'Actueel weer: ' + state.weather);
    const daypart = window.MSTRDaypart(state.time?.hour ?? 12);
    draw('time-icon', daypart.icon);
    draw('daypart-icon', daypart.icon);
    draw('dynamic-icon', state.dynamicWeather ? 'cycle' : 'pause');
    draw('blackout-icon', state.blackout ? 'bulbOff' : 'bulb');
  };
})();
