# MSTR_Weather

MSTR_Weather is een standalone FiveM weather- and time-management resource.

Current development status:

- Phase 1 — Foundation
- Phase 2 — Weather Engine
- Phase 3 — Time Engine
- Phase 4 — Dynamic Weather
- Phase 5 — Blackout + Persistence

Status: Fase 6A — read-only NUI geïmplementeerd; wacht op ingame validatie.
Start met `/mstrmenu` (of `mstrmenu` in F8). Vereist de bestaande admin-ACE.
Dashboard, Weather, Time en Settings tonen servergegevens om de twee seconden,
uitsluitend terwijl het menu openstaat. De klok is een servermomentopname.
Sluit met Escape, de sluitknop of nogmaals het command.

Volg [Instructions/FASE_6A_TESTPLAN.md](Instructions/FASE_6A_TESTPLAN.md).
Volgens de werkinstructie testen we eerst read-only voordat de controls worden
gebouwd. Logs en configureerbare branding horen bij Fase 7; geen lege Logs-tab.
Eerdere ingame testresultaten zijn niet automatisch als geslaagd aangemerkt.

## Persoonlijke menukleuren

Onder **Settings → Jouw uitstraling** kies je Champagne (standaard), Jade,
Arctic of Amethyst. Accent, achtergrond en panelen zijn ook vrij instelbaar met
een kleurkiezer of `#RRGGBB`-hexcode. Hexcodes bevestig je met Enter of door het
veld te verlaten. De tekstkleur past zich aan op lichte/donkere achtergronden.
**Standaard herstellen** zet Champagne terug.

Thema's worden lokaal in NUI-browseropslag bewaard, per apparaat/resource-origin;
ze veranderen niets voor andere admins en niets in `config.lua` of `state.json`.
Een gewiste cache, andere computer of gewijzigde resource-origin kan de voorkeur
resetten. Als opslag niet lukt blijft het thema deze sessie bruikbaar met melding.
Dit is een expliciet gevraagde cosmetische uitbreiding binnen de Fase 6-tests;
de weather/time-controls en Fase 7 branding/logging zijn nog niet gebouwd.

Test: alle presets, eigen lichte/donkere kleuren, foute hexcode, reset,
sluiten/heropenen en reconnect. Controleer ook join zonder menu (transparant),
Escape/focus, de kleurkiezer in FiveM, Settings-scroll op 1280×720 en live updates.
Automatische themalogicatest: `node tests/theme.cjs`. Visuele CEF-validatie blijft
ingame nodig; de browserdownload in de ontwikkelomgeving is mislukt.

## Eerdere core-tests

Volg [Instructions/FASE_1_5_TESTPLAN.md](Instructions/FASE_1_5_TESTPLAN.md).
Stop de resource en maak vóór de update een backup van je lokale
`data/state.json` en, indien aanwezig, `data/state.json.bak` buiten de resource.
Runtime-state staat voortaan niet meer in Git. Een schone installatie gebruikt
de defaults uit `config.lua`; bestaande geldige state kan worden teruggezet.

## Gedrag van de verbeteringen

- Late joins ontvangen de voortgang van een bestaande weertransitie.
- Een tweede smooth wijziging tijdens een actieve overgang wordt geweigerd;
  een expliciete instant wijziging onderbreekt de overgang.
- Ontbrekende weather-graph-entries gebruiken een veilige, vaste vervolgstap.
- Uitschakelen van Dynamic Weather beëindigt de scheduler-thread.
- `MSTR.State.GetSnapshot().time` bevat de live serverklok inclusief seconden.
- Persistence bewaart tijdens een overgang het geaccepteerde doelweer. Na een
  herstart wordt dat doel direct toegepast; de oude overgang wordt niet hervat.
- Saves worden gebundeld, houden een backup bij en proberen bij fouten maximaal
  drie keer. Een normale resource-stop bewaart de actuele toestand.
- Regen, grondsneeuw, sporen en tijdelijke overrides worden expliciet beheerd.

De runtime gebruikt geen database/framework of lokale `require()`-modules.
De huidige commandfeedback gebruikt de standaard `chat:addMessage`-interface.
Voor zichtbare feedback is een compatibele chatresource nodig.

## Automatische regressiecontrole

Vanuit de repository-root, met Lua 5.4:

```sh
lua5.4 tests/phase1_5.lua
lua5.4 tests/phase6.lua
```

De tweede opdracht draait de 16 core-tests plus 4 NUI-security/lifecycle-tests.
De tests gebruiken nagebootste Cfx-functies, timers, JSON en schijfopslag.
Ze controleren de logica, niet echte GTA-rendering, netwerkvertraging of writes.
De testbestanden worden niet door `fxmanifest.lua` geladen.

## Native-referenties

De NUI gebruikt lokale manifest-assets, `SendNUIMessage`, `SetNuiFocus` en
callbacks met altijd een antwoord, volgens de officiële Cfx-documentatie:
[Fullscreen NUI](https://docs.fivem.net/docs/scripting-manual/nui-development/full-screen-nui/)
en [NUI callbacks](https://docs.fivem.net/docs/scripting-manual/nui-development/nui-callbacks/).

De client gebruikt de gedocumenteerde mengfactor van
[SetWeatherTypeTransition](https://github.com/citizenfx/natives/blob/master/MISC/SetWeatherTypeTransition.md),
de aparte grondsneeuwinstelling
[ForceSnowPass](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/ForceSnowPass.md)
en automatische regenintensiteit/cleanup via
[SetRainLevel](https://github.com/citizenfx/natives/blob/master/MISC/SetRainLevel.md).
De aangeleverde EasyTime-code is alleen als functionele referentie bekeken;
er is geen EasyTime-code of dependency toegevoegd.

## Author

Martstok
