# Fase 8 — beveiligings- en performance-audit

Baseline: main `60aa45ceb34e283db4164a350e8592330a2fb6db`.
Fase 6 en 7 zijn door Mart ingame goedgekeurd op 27 september 2026.
Status: code-audit en automatische controles voltooid; ingame hercontrole en
echte performance-metingen van deze versie staan open. Fase 9 is niet gestart.

## Bevindingen en gerichte fixes

| Bevinding | Gevolg | Herstel |
|---|---|---|
| Weather/time-clientevents misten afzendercontrole | Lokale events konden geldige payloads toepassen zonder serverafzender; dit wijzigde alleen de betrokken client | Beide eventhandlers vereisen serverbron 65535, naast payloadvalidatie |
| Commands onbegrensd; NUI had eigen limiet | Een bevoegde gebruiker kon broadcasts/logs/saves versnellen en tussen ingangen wisselen | Eén gedeelde 500 ms-poort voor commands en NUI-acties; debug heeft een eigen poort; opruimen bij disconnect |
| Ieder afgewezen NUI-burstverzoek stuurde antwoord | Een afgewezen burst veroorzaakte alsnog veel uitgaande events | Ook rate-feedback maximaal eenmaal per 500 ms; excessieve verzoeken worden stil genegeerd |
| Uitgecommentarieerde commands kregen defaults terug | Commands waren actief terwijl de huidige config ze kennelijk wilde uitschakelen | Expliciet `false` wordt behouden en registreert geen command; drie bestaande regels naar false omgezet |
| State-save vertrouwde alleen op succescode | Een stil beschadigde write kon als goede state worden onthouden en later een goede backup vervangen | Backup en primary worden na schrijven teruggelezen; last-good verandert alleen bij gelijk resultaat |
| Admin-backup vertrouwde alleen op succescode | Bij een onjuist succesantwoord kon primary met een onbruikbare backup worden vervangen | Backup teruglezen vóór wijzigen primary; bestaande primarycontrole/fail-closed blijft |
| Statebestand had geen decodegroottelimiet | Een onbedoeld zeer groot lokaal bestand kon veel decodewerk veroorzaken | Maximaal 256 KiB, net als beheeropslag |

Weatherstrings hebben nu ook een lengtegrens vóór uppercase/lookup. Bestaande
serverautoriteit, engines en state-service zijn behouden. Eigen brandingpad
`images/myLogo.png` uit main is behouden. Geen nieuwe dependency of export.

De afzendercontrole volgt de officiële
[Cfx eventbeveiligingsdocumentatie](https://docs.fivem.net/docs/developers/server-security/).
Dit is geen anti-cheatgarantie: een aangepaste client kan zijn eigen lokale
code/beelden wijzigen. Andere spelers en globale state blijven servergestuurd.

## Gecontroleerde ingangen

| Ingang | Rechten en validatie | Begrenzing/levensduur |
|---|---|---|
| server requestSync | Iedere speler mag lezen; positief integer source; geen mutatie door clientpayload | 1 s per speler; alleen antwoord aan aanvrager; cleanup bij drop |
| server uiSnapshot | Opnieuw view-recht; integer request-ID/source; geen gebruikerslijst/logs in gewone snapshot | 1 s per speler |
| server uiAction weather/time/freeze/scale/dynamic/blackout | Actiegebonden rechten; whitelist, eindige getallen/grenzen, strikte booleans | Gedeelde 500 ms-poort; bestaande engines |
| server uiAction panel/settings/user/logs | Uitsluitend externe hoofdadmin-ACE; ook services controleren dit; exacte setting/rechtenvelden, identifier, revisie en logcursor | Dezelfde poort; begrensde opslag/antwoorden |
| optionele servercommands | Rechten gelijk aan NUI; parsing/validatie; geen console-mutaties | Dezelfde poort; disabled=false blijft uit |
| client weatherSync/timeSync | Serverafzender plus bestaande payloadvalidatie | Tijdankers en één actuele weathertransitie |
| client uiSnapshot/uiAction | Serverafzender, passend request-ID, geopende sessie/pending callback | Timeout, sluiting, late-antwoordencontrole |
| client statebags | Alleen global keys, boolvalidatie; schrijven uitsluitend in server/state.lua | Eventgestuurd, geen permanente blackout/settings-loop |
| NUI callbacks/message/DOM | NUI is geen autoriteit; server controleert iedere actie; tekstweergave voor namen/logs | Eén lopende browseractie; close/revoke wist beheergegevens |

Geen netwerkexports of tweede weather/time-implementatie gevonden. Geen lokale
runtime-requireconstructies. Manifestvolgorde en bestandspaden gecontroleerd.
Alleen constante SVG-markup gaat naar innerHTML; namen/logdata naar textContent.
Logo's zijn lokale toegestane paden. Geen externe API, database of framework.

## Opslag, autoriteit en concurrency

- Expliciete gebruikersregels beperken legacy ACE; meerdere identifiers worden
  samen beperkend toegepast. Hoofdadminrechten komen uitsluitend van ACE.
- Bestaande strikte booleans behouden false. NaN/oneindig, ongeldige weertypes,
  tijdgrenzen, vreemde rechtenvelden en foutieve revisies worden geweigerd.
- Beheersaves zijn synchroon met revisiecontrole. Oude formulieren kunnen geen
  nieuwere wijziging overschrijven. Corrupte beheeropslag verleent geen oude
  grants via automatische backuprestore.
- Gewone persistence herstelt backup/defaults; bewaart het geaccepteerde
  weerdoel en de live klok. Eén debounceworker, maximaal drie retries per burst.
  Rechtenopslag blijft onafhankelijk van weer/tijd-persistence.
- Logging: 10–1000 entries, maximaal 50 per serverantwoord; begrensde waarden,
  nieuwe kopieën bij lezen, alleen hoofdadmins. Geen permanente logthread.
- Bestaande regressies dekken gelijktijdige transitions, instant-onderbreking,
  timer-wrap, dynamic-toggle, late join en stale NUI-antwoorden.
- Teruglezen is geen atomische filesystemtransactie. Hard crash/stroomuitval
  tijdens writes blijft een ingame/hersteltest en reden voor externe backups.

## Metingen in de gesimuleerde runtime

`tests/phase8.lua` gebruikt de echte Lua-modules met nagebootste Cfx-timers,
events, natives en schijfopslag. Dit zijn telmetingen, geen resmon/CPU-metingen.

| Scenario | Waargenomen |
|---|---|
| 20.001 gemengde mutatiepogingen zonder klokvoortgang | 1 geaccepteerde actie; 1 rate-antwoord; volgende actie toegestaan vanaf 500 ms |
| Idle server, dynamic uit, 60 s | 1 tijdcorrectie-event, 0 writes, 1 blijvende serverthread |
| Eén smooth transitie met persistence | Tijdelijk 3 serverthreads: correctie, transitie, save; daarna terug naar 1 |
| Menu open, 60 s met geldige antwoorden | 30 nieuwe snapshotrequests |
| Menu gesloten, volgende 60 s | 0 snapshotrequests; pollingthread verdwenen |
| Stabiele client, 60 s, tick 250 ms | 240 klok-nativecalls, 0 weer-hertoepassingen, 0 resyncrequests |

Bestaande dynamic-tests tonen één actieve scheduler en stoppen bij uitzetten.
Weathertransities gebruiken tijdelijk een clienttick van 100 ms. Blackout en
settings gebruiken statebag-events. Geen per-seconde GlobalState-klok.
Geen micro-optimalisaties toegepast zonder aantoonbaar probleem.

## Ingame hercontrole en meetplan (open)

Maak backups van config, state/admin.json en .bak buiten de resource. Installeer
de hele testbranch; behoud je eigen brandingbestand en runtime-data.

1. Controleer dat /mstrmenu werkt en de drie commands met false niet geregistreerd
   zijn. Indien gewenst tijdelijk een commandnaam instellen en resource herstarten
   voor de commandtests; zet daarna je gewenste config terug.
2. Test met gewone speler, gedelegeerde admin en hoofdadmin. Controleer alle
   vinkjes, verboden acties, logtoegang en intrekken tijdens een open menu.
3. Voer kort na elkaar NUI- en commandacties uit. Snelle herhalingen mogen geen
   dubbele mutaties veroorzaken. Wacht minstens 0,5 s tussen normale acties.
4. Test weather/time-sync met twee spelers, directe/smooth wijziging, late join,
   dynamic aan/uit, blackout en resourceherstart. Nieuwe afzenderchecks mogen
   echte serverupdates niet blokkeren.
5. Test save/herstart en persistence uit/aan. Controleer serverconsole. Alleen
   op een wegwerpkopie: schrijfbeperkingen/corrupte bestanden en backupherstel.
6. Meet per scenario 60 seconden met dezelfde twee clients: menu dicht en stabiel
   weer, menu open, actieve transitie, tijd bevroren/lopend, dynamic aan/uit,
   logpagina met veel regels en herhaald openen/sluiten. Noteer resmon gemiddelde/
   piek, eventuele profileruitschieters, F8/serverfouten en of geheugen stabiliseert.

| Ingame scenario | Gemiddelde/piek | Fouten of groei | Uitslag |
|---|---|---|---|
| Idle/stabiel weer | nog meten | nog controleren | open |
| Menu open/dicht | nog meten | nog controleren | open |
| Actieve transitie | nog meten | nog controleren | open |
| Tijd loopt/bevroren | nog meten | nog controleren | open |
| Dynamic aan/uit | nog meten | nog controleren | open |
| Logs, taalwissel, menu heropenen | nog meten | nog controleren | open |

Eerdere resmon-waarneming van Mart (zichtbaar 0) is geen meting van deze versie.
De rate-limiter begrenst applicatiewerk en antwoorden; hij voorkomt niet alle
netwerk/deserialisatielast van kwaadwillend verkeer. Fase 8 blijft voor ingame
goedkeuring open. Niet automatisch doorgaan naar Fase 9.
