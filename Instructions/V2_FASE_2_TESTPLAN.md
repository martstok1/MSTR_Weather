> **Historisch document:** deze commando's gelden uitsluitend voor de oorspronkelijke
> Fase 2-commit. In 2.0.0-rc.1 is de bediening geïntegreerd in het V1-menu en zijn
> de tijdelijke commando's verwijderd. Gebruik [V2_GEBRUIK.md](V2_GEBRUIK.md).

# V2 Fase 2 — cyclusopslag en globale uitvoering

Versie: 2.0.0-dev.2. Implementatie gereed voor ingame validatie; geen definitieve release.
Fase 3 (Weercycli-tab), gebieden en temperatuur zijn nog niet geïmplementeerd.

## Wat is toegevoegd

- `server/cycles.lua`: hoofdadminservice, aparte opslag met revisie en één actieve
  cyclusworker. Zonder actieve cyclus is er geen cyclusworker.
- Het bestaande weather-syncbericht en de bestaande clientblend ondersteunen nu
  spelseconden en een clockRate. Geen tweede weather-native-implementatie.
- Bij freeze/scale=0 stopt de clientblendworker op de ontvangen fractie. Tijd- en
  snelheidswijzigingen sturen direct een nieuwe fractie/rate vanuit de server.
- Een scheduler controleert maximaal iedere seconde de cyclus; vlak bij een grens
  kan dit tot eenmaal per 50 ms. Alleen bij blok-/overgangsgrenzen wordt gebroadcast,
  plus activering, tijdcorrecties en expliciete tijd-/freeze-/scale-wijzigingen.
- Late joins ontvangen een actuele berekening, niet een oude beginfractie.
- Activatie stopt gewogen weer en maakt oude overgangsworkers ongeldig.
- Actieve cycli blokkeren gewone weer-/dynamic-acties met een NL/EN-melding.
  Tijd, blackout en bestaande rechten blijven werken.

## Tijdelijke bediening

Gebruik ingame `/mstrcycle` of `mstrcycle` in F8. Een compatibele chatresource is
nodig voor zichtbare antwoorden. Alleen de effectieve hoofdadmin-ACE geeft toegang;
serverconsole en gewone admins kunnen het command niet gebruiken.
Alle acties (ook list) delen de bestaande 500ms-verzoeklimiet.

| Command | Doel |
| --- | --- |
| `/mstrcycle list` | ID's, actieve cyclus en huidige revisie tonen |
| `/mstrcycle import demo 0` | Definitie uit `data/cycle_import.json` onder ID demo opslaan; verwacht revisie 0 |
| `/mstrcycle activate demo 1` | Demo activeren; verwacht revisie 1 |
| `/mstrcycle stop confirm 2` | Cyclus expliciet stoppen; verwacht revisie 2 |
| `/mstrcycle delete demo 3` | Inactieve demo verwijderen; verwacht revisie 3 |

Elke geslaagde mutatie verhoogt de revisie met 1. Vervang de voorbeeldrevisie door
de waarde uit list. ID's zijn 1–40 tekens: kleine letters, cijfers, `_` of `-`.
Import met een bestaande ID vervangt die cyclus. Bij een actieve cyclus wordt de
nieuwe definitie na geslaagd opslaan meteen toegepast. Verwijderen van de actieve
cyclus wordt geweigerd: eerst expliciet stoppen.

Fase 2-afspraak: stoppen vereist `confirm` en laat het doelweer van het huidige
blok als statisch weer staan. Daarna kan de bestaande bediening weer worden
gebruikt. De bevestigingsdialoog voor direct overschakelen volgt in Fase 3.
Import/activatie zijn bewuste hoofdadminacties; er is nog geen menu-preview.

## Voorbeeldbestand

Maak zelf `data/cycle_import.json` in je serverresource met onderstaande inhoud.
Dit is een tijdelijke importbron; het wordt nooit automatisch geactiveerd en
wordt niet in Git opgeslagen. Het command leest uitsluitend dit vaste pad.

```json
{
  "version": 1,
  "name": "Testdag",
  "startMinute": 0,
  "blocks": [
    { "weather": "CLEAR", "percent": 50, "transitionGameSeconds": 120 },
    { "weather": "RAIN", "percent": 50, "transitionGameSeconds": 120 }
  ]
}
```

00:00–12:00 helder, 12:00–00:00 regen. Elk blok begint met twee spelminuten
overgang vanaf het vorige blok. Bij tijdsnelheid 2 duurt dit één echte minuut.
Start je om 12:01, dan ontvang je direct 50% overgang. Bij handmatige tijdsprongen
kan het beeld direct naar de passende fractie springen; dit is bedoeld gedrag.

## Opslag en herstel

`data/cycles.json` bewaart `{version, revision, active, cycles}`; maximaal 32 cycli,
24 blokken per cyclus, 256 KiB en maximaal 8 JSON-niveaus vóór decoderen.
Opslag staat los van de aan/uit-instelling voor omgevingspersistence.
`data/cycles.json.bak` bevat de vorige geldige configuratie, vanaf een volgende
save wanneer een primary bestaat. Backup en primary worden teruggelezen ter controle.
Pas na succesvolle primary-write verandert de live configuratie en verschijnt
de geslaagde beheeractie in het log. Updates zijn synchroon en revisiegecontroleerd.

Ongeldige primary of ontbrekende primary met bestaande backup blokkeert
cyclusbewerkingen. Geen automatische backuprestore: die zou een bewust gestopte
cyclus opnieuw kunnen activeren. V1 start dan met zijn gewone environment-state;
de serverconsole meldt het probleem. De hoofdadmin kan de vergrendeling via list zien.

Bij schrijfproblemen blijft de oude live cyclus werken. Het beschadigde bestand
kan op schijf achterblijven: stop de resource en herstel bewust een geldige versie
uit je externe backup of `.bak`. Controleer daarbij `active` en de revisie.
Een crash tijdens een write is geen atomair bestandssysteemtransactie.

Voor terugkeer naar v1: stop normaal, maak backups buiten de resource, zet v1-code
terug en behoud state/admin-bestanden. V1 negeert cycles.json. Bewaar/verwijder het
cyclusbestand bewust voordat je later weer v2 gebruikt: daarin kan nog active staan.
Zonder beide cyclusbestanden start v2 met v1-gedrag en revisie 0.

Omgevingsopslag blijft de spelklok en statische/gewogen v1-toestand bewaren. Als
die uitstaat, gelden daarvoor na herstart de configdefaults; een opgeslagen actieve
cyclus wordt dan op die startklok hervat. Offline tijd wordt niet opgeteld.
Bij stoppen blijft active=false duurzaam opgeslagen; statisch/gewogen gedrag na
herstart volgt vervolgens weer de normale v1-persistence/defaults.

`Config.Persistence.File` mag niet naar cycles.json of cycle_import.json wijzen.
De huidige gitignore sluit deze runtime-JSON-bestanden al uit.

## Ingame acceptatie

1. Backup config en data. Start eerst zonder cyclusbestanden: menu, weer, dynamisch
   weer, tijd, blackout en opslag moeten zoals v1 werken. Controleer console/F8.
2. Importeer het voorbeeld als hoofdadmin. Controleer dat het weer niet verandert.
   Een gewone admin/speler mag niet list/import/activate/stop/delete gebruiken.
3. Activeer met de actuele revisie. Dynamisch weer gaat uit. Gewoon weer wijzigen
   of dynamisch weer inschakelen wordt geweigerd met uitleg.
4. Zet via het bestaande menu de tijd op 11:59 en laat 12:00 passeren. Controleer
   de geleidelijke overgang. Test ook 23:59 → 00:00.
5. Zet op 12:01, freeze aan: overgang moet op ongeveer 50% blijven. Wacht, hervat.
   Test scale 0, 0.5, 2 en 4, ook midden in een overgang.
6. Zet handmatig vooruit/achteruit (12:01, 06:00, 00:01). Geen inhaalreeks of
   oude overgang die later het weer terugzet. Controleer ook regen/sneeuw-cleanup.
7. Reconnect midden in een overgang en tijdens freeze. Met tweede speler indien
   beschikbaar: vergelijk hetzelfde weer en fractie. Niet beschikbaar = open TODO.
8. Start tweemaal snel achter elkaar een andere/importeerbare cyclus, wacht langer
   dan de oude overgang: geen strijd tussen workers. Stop met confirm en controleer
   dat normale handmatige/gewogen bediening terugwerkt.
9. Herstart resource en server met actieve cyclus; deze hervat op de opgeslagen
   spelklok. Test ook persistence uit met de verwachte configstarttijd.
10. Test verkeerde revisie, totaal 99%, fout weertype, negatief/te lang overgangsblok,
    actieve cyclus verwijderen en commandspam. Geen ongeautoriseerde mutaties.
11. Alleen op een wegwerpkopie: maak cyclusprimary ongeldig of simuleer onbeschrijfbare
    opslag. Controleer foutmelding, geen onterecht succes, herstel met resource gestopt.
12. Controleer NL en EN, gewone menu-instellingen, blackout en persoonlijke thema's.
    Meet resmon met/zonder cyclus, tijdens overgang/freeze en met menu open/gesloten.

## Automatisch gecontroleerd

Run vanuit de resource-root met Lua 5.4:

```sh
lua5.4 tests/v2_phase1.lua
lua5.4 tests/v2_phase2.lua
```

Fase 1: 9 modeltests. Fase 2: 14 integratietests voor echte engines/services met
nagebootste Cfx-timers, events, JSON en opslag. Ze controleren autorisatie, throttle,
revisies, grenzen, eigenaarschap, freeze/scale/tijdsprongen, reconnectpayloads,
uitgeschakelde workers, restart en corrupte writes. De token-JSONcodec test geen
echte Cfx-JSONparser of schijffouten. Visuele GTA-effecten, echte netwerklatency,
resmon en multiplayer moeten ingame worden gecontroleerd.

STOP na Fase 2. Fase 3 pas na goedkeuring.
