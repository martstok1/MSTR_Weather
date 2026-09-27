# MSTR_Weather

MSTR_Weather is een standalone FiveM weather- and time-management resource.

Current development status:

- Phase 1 — Foundation
- Phase 2 — Weather Engine
- Phase 3 — Time Engine
- Phase 4 — Dynamic Weather
- Phase 5 — Blackout + Persistence

Status: Fase 1-5 verbeteringen geïmplementeerd; wacht op ingame validatie.
Fase 6 (NUI) is nog niet gebouwd en start pas na akkoord op de tests.

## Testen vóór Fase 6

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
```

De 16 tests gebruiken nagebootste Cfx-functies, timers, JSON en schijfopslag.
Ze controleren de logica, niet echte GTA-rendering, netwerkvertraging of writes.
De testbestanden worden niet door `fxmanifest.lua` geladen.

## Native-referenties

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
