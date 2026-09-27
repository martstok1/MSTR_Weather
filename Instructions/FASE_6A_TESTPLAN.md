# Fase 6A — read-only NUI: ingame validatie

Implementatie gereed, echte FiveM-runtime nog niet gevalideerd.
Deze stap volgt hoofdstuk 20: eerst read-only testen, daarna controls bouwen.
Fase 6 is dus nog niet volledig afgerond. Fase 7 is niet gestart.

## Installatie

1. Gebruik branch `feat/phase6-readonly-nui` (inclusief de eerdere core-fixes).
2. Stop de resource en bewaar je config en runtime-state buiten actieve resources.
3. Kopieer de resource zonder extra geneste map. Bewaar `data/state.json` en `.bak`.
4. Neem eigen configwaarden over. Nieuw: `Config.General.MenuCommand = 'mstrmenu'`.
5. Start de resource. Je bestaande `mstr.weather.admin`-ACE blijft nodig.
   Indien nog niet toegekend: bijvoorbeeld `add_ace group.admin mstr.weather.admin allow`
   in je eigen permissionsconfig, mits je account daadwerkelijk bij die groep hoort.
   Er worden geen externe configuratiebestanden gewijzigd.

## Eén admin

1. Controleer dat bij join/start geen menu of cursor onverwacht verschijnt.
2. Open `/mstrmenu`, of typ `mstrmenu` in F8 en sluit de F8-console.
3. Dashboard toont weer, tijd, dynamic weather en blackout. Vergelijk `/mstrdebug`.
4. Open Weather, Time en Settings. Geen lege pagina’s, geen Logs-tab,
   geen wijzigingsknoppen. Settings toont de werkelijke serverconfig.
5. Sluit met Escape; herhaal met de sluitknop en via het command.
   Muis en toetsenbord moeten steeds teruggaan naar GTA.
6. Open/sluit tienmaal snel. Geen dubbele menu’s, focusproblemen of Lua-errors.
7. Vergelijk de layout op jouw resolutie/UI-schaal, eventueel ook 1280×720.
8. Herstart en stop de resource met geopend menu: geen achterblijvende cursor/overlay.
9. Controleer F8, serverconsole en NUI-console op errors.

## Live updates (liefst twee spelers/admins)

Laat admin A het menu openhouden. Laat admin B bestaande commands uitvoeren:

| Command | Verwacht binnen circa 2 seconden |
|---|---|
| `/mstrweather dynamic false` | Dynamic uit, geen countdown |
| `/mstrweather CLEAR instant` | CLEAR, stabiel |
| `/mstrweather RAIN smooth` | Doel RAIN en resterende overgangsduur; na afloop stabiel RAIN |
| `/mstrtime 23:59` | Tijd verandert en loopt later door middernacht |
| `/mstrtime freeze true` | Tijd blijft staan; bevroren aan |
| `/mstrtime freeze false` | Tijd hervat |
| `/mstrtime scale 0.5` | Snelheid 0.5× |
| `/mstrblackout true`, daarna `false` | Beide waarden verschijnen correct |
| `/mstrweather dynamic true` | Countdown verschijnt |

Met één speler kun je het menu sluiten, een command uitvoeren en heropenen;
dat bewijst geen gelijktijdige updates tussen twee echte clients. Gebruik eventueel
de F8-console voor commands zonder slash terwijl het menu openstaat.
De zichtbare klok is bewust een momentopname per 2 seconden, geen lokale authority.
Herstel je gewenste weer/tijd/scale/blackout/dynamic waarden na de test.

## Permissions, verbinding en performance

- Zonder admin-ACE: menu opent niet; melding in F8; geen focus vastgehouden.
- Trek ACE in bij een open menu: sluit bij de volgende servercheck.
- Netwerk/serverantwoord weg: na circa 5 seconden waarschuwing in het menu,
  na circa 10 seconden sluit de client het menu en geeft focus vrij.
- Gesloten menu: geen NUI-snapshotrequests of NUI-pollingthread meer.
- Open menu: één request per 2 seconden, alleen antwoord naar de aanvrager.
- Meet `resmon 1` gesloten/geopend en vergelijk met de eerdere versie.
- Herhaal relevante weather/time/persistence-tests uit Fase 1–5.

## Automatisch gecontroleerd versus runtime

`lua5.4 tests/phase6.lua`: 16 core-regressies en 4 extra NUI-checks met mocks:
ACE per refresh, throttle, verkeerde ids, disconnect-cleanup, geen writes,
ready handshake, late replies, lokale eventafwijzing, timeout, focus cleanup,
herhaald openen en geen polling na sluiten.
Mocks controleren geen echte CEF-focus, GTA-rendering, netwerkvertraging of resmon.

Geef terug: openen/sluiten, live updates, ACE, restart, resolutie, resmon,
errors (exacte tekst) en welke multiplayerchecks niet zijn uitgevoerd.

STOP: eerst deze testresultaten beoordelen, daarna Fase 6B (controls).
