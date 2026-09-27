# MSTR_Weather

MSTR_Weather is een standalone FiveM weather- and time-management resource.

Current development status:

- Phase 1 — Foundation
- Phase 2 — Weather Engine
- Phase 3 — Time Engine
- Phase 4 — Dynamic Weather
- Phase 5 — Blackout + Persistence

Status: Fase 8 — code-audit en gerichte fixes gereed voor ingame hercontrole.
Fase 1–5, Fase 6A, persoonlijke thema's en synchronisatie met een tweede speler
zijn door Mart goedgekeurd. Resmon bleef tijdens die tests zichtbaar op 0.
Start met `/mstrmenu` (of `mstrmenu` in F8). Vereist toegang via ACE of Beheer.
Dashboard, Weather, Time en Settings tonen servergegevens om de twee seconden,
uitsluitend terwijl het menu openstaat. De klok is een servermomentopname.
Sluit met Escape, de sluitknop of nogmaals het command.

Volg [Instructions/FASE_6B_TESTPLAN.md](Instructions/FASE_6B_TESTPLAN.md).
Fase 6 inclusief bediening, talen en iconen en Fase 7 zijn door Mart ingame
goedgekeurd op 27 september 2026. Die goedkeuring geldt voor de vorige versies;
de gerichte Fase 8-fixes moeten nog ingame worden gecontroleerd.

Zie [het auditrapport en meetplan](Instructions/FASE_8_AUDIT.md). De drie
beheercommands staan op `false`, overeenkomstig de uitgecommentarieerde regels
op main. `false` schakelt registratie nu daadwerkelijk uit. Zet een commandnaam
terug om dat command weer te activeren. Commands en NUI-acties delen een limiet
van één verzoek per speler per 500 ms; een te snel command wordt genegeerd.
Rechtencontrole blijft altijd van toepassing. Menu openen en sync blijven werken.

## Fase 7: branding en logging

Branding komt uitsluitend uit `Config.Branding`: `Name`, `Logo` en `ShowName`.
Gebruik lokale `images/default.svg`, een PNG of een WEBP. Een ongeldig of
ontbrekend logo gebruikt automatisch de standaardfallback. De naam wordt veilig
afgekapt en kan verborgen worden zonder de layout te breken.

Hoofdadmins hebben een Logs-tab. Deze toont server-side vastgelegde ADMIN- en
SYSTEM-acties met timestamp, bron, speler/identifier, actie en oude/nieuwe
waarde. De geschiedenis staat alleen in het geheugen van de resourcesessie en
heeft een begrensde ring (`Config.Logging.MaxEntries`, 10–1000). Alleen de
hoofdadmin-ACE kan logs lezen; iedere aanvraag wordt opnieuw gecontroleerd.
Zie [Instructions/FASE_7_TESTPLAN.md](Instructions/FASE_7_TESTPLAN.md).

## Hoofdadmin en gedelegeerde rechten

Voeg in je geladen `permissions.cfg` uitsluitend voor je eigen account toe:

```cfg
add_ace identifier.fivem:JOUW_FIVEM_ID mstr.weather.superadmin allow
```

Vervang `JOUW_FIVEM_ID` door het numerieke deel van je serveridentifier
`fivem:123456`. Geef deze ACE niet aan een algemene admingroep. Controleer ook
bestaande brede ACE's/inheritance: die kunnen dezelfde toestemming geven.
De resource kan alleen de effectieve ACE controleren, niet wie jij bent.
Voor uitleg: [Cfx identifiers](https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/GetPlayerIdentifiers/).

Alleen deze ACE opent **Beheer**: zes weer/tijd-instellingen, servertaal en per persoon vinkjes
voor menu bekijken, weer, tijd, dynamic weather en blackout. Hoofdadminrechten
zijn nooit via het menu toe te kennen. Commands controleren dezelfde rechten.
Gebruik in het menu `fivem:123456` of een lowercase `license:` met 40 hextekens.
Online spelers verschijnen in de keuzelijst; offline spelers kunnen handmatig.
Menu bekijken is vereist voor alle overige rechten. Alles uitvinken trekt
gewone toegang in, ook bij een bestaande `mstr.weather.admin`-ACE. Meerdere
opgeslagen identifiers van dezelfde speler worden samen beperkend toegepast.
Een hoofdadmin behoudt via ACE alle rechten ongeacht de vinkjes.

De bestaande `mstr.weather.admin` blijft gewone bediening geven, zonder Beheer,
zolang er geen expliciete gebruikersregel voor die speler is opgeslagen.
Rechten worden op de server bij iedere actie gecontroleerd; zichtbaarheid wordt
binnen circa twee seconden bijgewerkt zolang het menu openstaat.

Instellingen en rechten staan afzonderlijk in `data/admin.json`, met een vorige
versie in `.bak`, ook als weer/tijd-persistence uitstaat. Opgeslagen instellingen
hebben bij starten voorrang op de zes overeenkomstige defaults in `config.lua`.
Een gewijzigde overgangsduur geldt vanaf de volgende overgang; een gewijzigd
dynamic interval start een nieuwe countdown. Persistence inschakelen bewaart de
live toestand, zonder oude state te laden. Uitschakelen verwijdert geen bestand.

Beschadigde beheeropslag (of een ontbrekende primary met bestaande backup)
blokkeert gewone toegang en beheerschrijfacties. De hoofdadmin kan nog kijken.
Er is geen automatische backuprestore: dat zou ingetrokken rechten kunnen
herstellen. Stop de resource, controleer de bestanden en herstel bewust een
geldige versie; controleer daarbij oude grants. Bewaar backups buiten de resource.
Verwijder beheeropslag niet zomaar: zonder beide bestanden gelden weer defaults
en legacy ACE's. Maximaal 256 gebruikersregels; saves gebruiken versienummers
om overschrijven vanuit een verouderd beheerformulier te weigeren.

## Persoonlijke menukleuren

Onder **Instellingen → Jouw uitstraling** kies je Champagne (standaard), Jade,
Arctic of Amethyst. Accent, achtergrond en panelen zijn ook vrij instelbaar met
een kleurkiezer of `#RRGGBB`-hexcode. Hexcodes bevestig je met Enter of door het
veld te verlaten. De tekstkleur past zich aan op lichte/donkere achtergronden.
**Standaard herstellen** zet Champagne terug.

Thema's worden lokaal in NUI-browseropslag bewaard, per apparaat/resource-origin;
ze veranderen niets voor andere admins en niets in `config.lua` of `state.json`.
Een gewiste cache, andere computer of gewijzigde resource-origin kan de voorkeur
resetten. Als opslag niet lukt blijft het thema deze sessie bruikbaar met melding.
Dit is een expliciet gevraagde cosmetische uitbreiding binnen de Fase 6-tests;
de Fase 6B-bediening behoudt deze voorkeuren. Fase 7 is inmiddels goedgekeurd.

Test: alle presets, eigen lichte/donkere kleuren, foute hexcode, reset,
sluiten/heropenen en reconnect. Controleer ook join zonder menu (transparant),
Escape/focus, de kleurkiezer in FiveM, Settings-scroll op 1280×720 en live updates.
Automatische themalogicatest: `node tests/theme.cjs`. Visuele CEF-validatie blijft
ingame nodig; de browserdownload in de ontwikkelomgeving is mislukt.

## Eerdere core-tests

### Fase 6B — taal en visuele afwerking

**Beheer → Servertaal** kiest Nederlands of Engels voor alle spelers. De taal
wordt server-side gevalideerd en samen met de andere beheerinstellingen in
`data/admin.json` opgeslagen. `Config.General.Locale` is alleen de startdefault
(`nl`/`en`). Bestaande beheerbestanden zonder taalveld nemen die default over;
de bestaande rechten blijven behouden. Opslaan vereist de hoofdadmin-ACE.

Open menu's volgen de opgeslagen taal binnen circa twee seconden; bij opnieuw
openen geldt direct de servertaal. Navigatie, labels, weernamen, foutmeldingen,
themafeedback en commandfeedback zijn vertaald. Persoonsnamen, identifiers,
commando's en technische argumenten zoals `smooth`, `instant` en `true|false`
blijven ongewijzigd. Technische serverdiagnostiek is geen menutekst.
De persoonlijke kleurvoorkeur blijft apart en heeft geen eigen taalkeuze.

Het configuratieoverzicht is verwijderd uit Instellingen. Beheer toont de
instellingen alleen aan hoofdadmins; gewone snapshots bevatten uitsluitend
de grenzen die de bediening nodig heeft (tijdsnelheid en direct wijzigen).

Het tijdpaneel toont dagdelen op basis van de gesynchroniseerde spelklok:
05:00–07:00 zonsopkomst, 07:00–19:00 dag, 19:00–21:00 zonsondergang en
21:00–05:00 nacht. Dit zijn vaste UI-tijdvakken, geen astronomische berekening.
De illustraties onderscheiden smog/mist, één/drie wolken en één/twee/drie
sneeuwvlokken. Opklaringen heeft een zon achter de wolk; Halloween een volle
maan met vleermuis.

Halloween gebruikt dezelfde bestaande weather-native als de andere weertypes.
De automatische neerslag van dit weertype wordt nu vrijgegeven in plaats van
op nul geforceerd. De automatische test bewijst native-aanroep en cleanup,
niet het uiteindelijke GTA-effect. Test Halloween buiten, met dynamisch weer
uit, zowel direct als geleidelijk; vergelijk dag en nacht. Als het effect nog
ontbreekt, noteer gamebuild, tijd, andere weerresources en F8/servermeldingen.
Nativebron: [Cfx weather types](https://github.com/citizenfx/natives/blob/master/MISC/SetWeatherTypeNow.md).

Vervolg met [het afwerkingstestplan](Instructions/FASE_6B_AFWERKING_TESTPLAN.md).
Deze uitbreiding en Fase 7 zijn inmiddels ingame goedgekeurd.

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
lua5.4 tests/phase6b.lua
lua5.4 tests/phase6c.lua
lua5.4 tests/phase7.lua
lua5.4 tests/phase8.lua
node tests/theme.cjs
node tests/controls.cjs
node tests/locales.cjs
```

De tweede opdracht draait de 16 core-tests plus 4 NUI-security/lifecycle-tests.
Fase 6B voegt 10 checks voor rechten, beheeropslag en actieafhandeling toe.
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
