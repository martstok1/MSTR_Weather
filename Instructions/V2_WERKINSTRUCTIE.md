# MSTR_Weather v2 — werkinstructie

Status: ontwikkeling. Fase 1 en 2 geïmplementeerd; Fase 2 wacht op ingame validatie.
Zie [Fase 2-testplan en tijdelijke bediening](V2_FASE_2_TESTPLAN.md).
Bronbaseline: main `7a5975d78eeac1bc6c34c45caa620994b3880c93`.
Deze instructie is AI-agnostisch. De actuele code en expliciete gebruikersopdracht
zijn leidend. Een oude Phase5-zip is geen bron voor herstel van huidige code.

## Doel en scope

Bouw voort op de standalone v1 met:

- Een hoofdadmin-tab Weercycli: blokken toevoegen, bewerken, verwijderen en ordenen.
- Weertype, percentage van de speldag en overgangsduur per blok; totaal exact 100%.
- Meerdere benoemde cycli, starttijd, tijdlijn en voorbeeld van begin/eindtijden.
- Gebieden op een kaart met vast weer, een cyclus of gewogen dynamisch weer.
- Voorbeelden: zonnig Sandy Shores, regenachtiger noorden, wisselend Los Santos.
- Eigen polygonen en rechthoeken tekenen en aanpassen.
- Temperatuur per gebied/weerblok, geleidelijke temperatuurwisselingen,
  configureerbare hittetrilling en subtiele vorstranden.
- Vloeiende overgangen bij zowel tijdwisselingen als gebiedsgrenzen.

Geen gezondheidsschade, dorst, kledinglogica, database, externe API, weersvoorspelling
voor spelers, seizoenen of routing-bucketweer toevoegen. Geen CodeM-code/assets
overnemen; de referentie beschrijft uitsluitend het gewenste soort functionaliteit.

## Werkregels

Lees vóór iedere fase de huidige README, deze instructie en betrokken code.
Werk op een aparte branch. Geen externe cfg of andere resources wijzigen.
Behoud v1-menu, vertalingen, thema's, rechten, logging, blackout en opslag.
Geen tweede weather-native-implementatie of tijdengine; gebruik MSTR namespace.
Interne bestanden laden via manifest, geen lokale require-architectuur.
Geen dependencies toevoegen. Nieuwe natives vooraf met officiële Cfx-documentatie
verifiëren. Geen backdrop-filter in de NUI.

Na iedere fase: self-review, gerichte tests, concrete ingame stappen en STOP.
Ga pas verder na toestemming. Niet-uitgevoerde tests nooit goedkeuren.
Ontwikkeltests mogen op de v2-branch bestaan en horen niet in het runtime-manifest.
Versie blijft een dev-versie tot de eindcontrole en expliciete releasegoedkeuring.

## Tijd- en cycluscontract

Een cyclus volgt de canonieke spelklok, niet systeemtijd of een eigen stopwatch.
Een dag is 86400 spelseconden. Percentage is duur, niet kans.
Ondersteun 0,01% precisie; reken intern met gehele basispunten, totaal 10000.
Een cyclus heeft 1–24 blokken, een naam van maximaal 80 UTF-8 bytes en startMinute
0–1439. Onderliggende cyclusdefinitie heeft schema version=1.

Blokvelden: weather, percent en transitionGameSeconds. Overgang ligt aan het
begin van het blok, telt mee in het percentage en mag niet langer zijn dan het
blok. 0 betekent direct. Begin is inclusief, einde exclusief; middernacht wrapt.
Het vorige blok van blok 1 is het laatste blok van de vorige dag.
De editor vermeldt expliciet spelseconden en toont bij scale>0 ook echte seconden
(spelseconden / scale). Bij freeze/scale=0 toon 'gepauzeerd', geen deling door nul.

Deze keuze maakt freeze en versnellen voorspelbaar. Tijd sprongen vooruit/achteruit
resolven rechtstreeks naar het juiste blok en zijn geen reeks inhaaltransities.
Bij starten/reconnect wordt het huidige blok en zijn voortgang berekend.
Alle cyclische overgangen volgen de spelklok. Gebiedsgrensovergangen gebruiken
een afzonderlijke echte-secondeninstelling, zodat reizen bij bevroren tijd werkt.

## Architectuur en autoriteit

Fase 1: server/cycle_model.lua bevat pure Compile/Resolve-functies. Compile geeft
een opaque handle of nil, foutcode, eventueel blokindex. Resolve neemt die handle
en gameSeconds 0..<86400 en geeft een nieuwe resultaat-tabel. Geen netwerk-API.
Valideer alle definities server-side; NUI-validatie is uitsluitend gebruiksgemak.

Latere fases: een centrale serverkeuze per gebied bepaalt één actieve modus:
static, weighted of cycle. Nooit de bestaande scheduler en cyclus gelijktijdig
voor hetzelfde gebied laten schrijven. Omgevingsdata, revisie en tijdanker komen
van de server. Clients passen alleen de effectieve omgeving toe.
MSTR.TimeEngine blijft de enige klok; MSTR.WeatherEngine blijft het ingangspunt
voor weatherbesluiten; client/weather.lua blijft de centrale native-aansturing.

Gewone handmatige weatherbediening schakelt alleen het bediende doel naar static,
na zichtbare bevestiging wanneer daarmee een cyclus wordt gestopt. Bij regionale
modus is het doel expliciet globaal/fallback of een geselecteerd gebied.
Blackout blijft globaal. De klok blijft overal gelijk.

## Rechten, opslag en grenzen

Cycli, gebiedsdefinities en effecten beheren vereist de bestaande superadmin-ACE.
Geen nieuw hoofdadminrecht via gebruikersvinkjes toekennen. Iedere nieuwe read/write
van beheerdata opnieuw server-side autoriseren, begrenzen en rate-limiten via
bestaande requests-service. Client-ID, source, mode en revisie niet vertrouwen.
Gewone weersynchronisatie bevat geen gebruikersrechten of beheergegevens.
Bij weigering mogen state, opslag en logs geen geslaagde mutatie tonen.

Vanaf Fase 2: aparte data/cycles.json met schema en revisie, maximaal 32 cycli.
Vanaf Fase 4: aparte data/regions.json; maximaal 32 gebieden, 64 punten per polygoon.
Limiet voor ieder JSON-bestand en beheerpayload: 256 KiB. Controleer ook diepte,
arrayvorm, strings, onbekende velden, NaN/infinity en referenties naar cycli.
Bestandswrites verifiëren en backupbeleid expliciet vastleggen; meld opslagfouten
en publiceer een nieuwe configuratie pas nadat de write is geslaagd.
Optimistische revisiecontrole voorkomt overschrijven door een oud formulier.
Een cyclus in gebruik kan niet worden verwijderd zonder expliciete herkoppeling.
Geen migratie/verwijdering van state.json of admin.json; oude installaties blijven
zonder v2-bestanden in hun huidige v1-modus starten.

## Gebieden en temperatuur

Buiten gebieden geldt globale fallback. Eerste versie weigert overlappende en
zelfsnijdende polygonen; gedeelde grenzen mogen, met vaste ID-tiebreak.
Valideer eindige mapcoördinaten en oppervlakte. Maak grens-hysterese en een korte
stabiliteitsperiode zodat stilstaan/rijden op grenzen geen weerflikkering geeft.
Teleports en reconnects krijgen directe doelgebiedbepaling met gecontroleerde blend.
Positiedetectie met begrensde frequentie/spatial filtering; geen alle-polygonen-scan
per frame. Clients mogen geen globale gebiedsstate wijzigen.

GTA-weer is een lokale weergave voor de speler: dit is geen echte ruimtelijke
regenwolk die je naast een zonnig gebied kunt zien. Test grensbeleving ingame.

Temperatuur is een visuele waarde in Celsius (-50..60), geen GTA-fysicasimulatie.
Voeg temperatuur pas in Fase 6 via een expliciete schema-upgrade toe; oude cycli
krijgen een gedocumenteerde neutrale default. Warmte/koude afzonderlijk aan/uit,
drempels en maximale intensiteit instelbaar. Effecten worden opgebouwd/afgebouwd,
bij resource-stop opgeruimd en draaien niet wanneer uitgeschakeld.
Timecycle-effecten kunnen botsen met andere resources: geen permanente strijd
door iedere tick opnieuw te forceren; bied uitschakeling en documenteer compatibiliteit.

## Fases en acceptatie

### Fase 1 — cyclusmodel en veilige basis

Implementeer schema-validatie, exacte verdeling, klokresolver, manifest-load en
gerichte tests. Geen activatie, saves, scheduler, gebieden of lege menutabs.
Acceptatie: 100%-controle, ongeldige input, middernacht, startoffset, blokgrenzen,
transitievoortgang, tijdsprongen en isolatie van gevalideerde data getest.
Ingame: normale start, bestaand menu, weer/tijd/blackout, resource-herstart.

### Fase 2 — cyclusservice, opslag en globale uitvoering

Voeg beheeropslag met revisies toe, activeren/stoppen en één scheduler op basis
van de bestaande klok. Integreer prioriteit met weighted/static en één clientblend.
Test freeze, scale=0, snelheid wijzigen tijdens overgang, handmatige tijdsprongen,
start tijdens overgang, corrupte opslag, rollback en geen dubbele schedulers.
Beveilig tijdelijke beheerinterfaces even strikt als de uiteindelijke NUI.

### Fase 3 — tab Weercycli

Hoofdadmin-only CRUD, ordenen, 100%-meter, tijdlijn, duurweergave, opslaan/activeren,
duidelijke foutmeldingen en NL/EN. Geen optimistische succesmeldingen vóór serverack.
Test twee beheerformulieren, verlopen revisie, ingetrokken rechten, focus/close,
kleine resoluties, persoonlijke thema's en persistence na herstart.

### Fase 4 — regionale weatherbasis

Introduceer gevalideerde gebieden, globale fallback, per-gebiedmodi en effectieve
speleromgeving; eerst eenvoudige configureerbare regio's. Geen tweede klok.
Test grensoverschrijding, voertuigen, vliegtuig, teleport, overlappen afwijzen,
spelerjoin, stoppen/herstarten en verschillende spelers in hetzelfde/ander gebied.

### Fase 5 — kaarteditor en gebiedsovergangen

Eigen kaartbediening: selecteren, tekenen, rechthoek, verplaatsen, punten bewerken,
naam, verwijderen, cyclus koppelen. Onderbouw herkomst/licentie van kaartafbeelding.
Vloeiende grensovergangen starten vanuit de actuele blend, ook bij snel doorreizen.
Test grenspendelen, regen/sneeuw-cleanup, actieve cycluswissel tijdens verplaatsing,
kaartcoördinaten, revisieconflicten en limieten. Geen verborgen dure animaties.

### Fase 6 — temperatuur en effecten

Schema-upgrade, temperatuur per blok/gebied, interpolatie, optionele hittetrilling
en subtiele vorstranden. Normale NUI mag gesloten blijven terwijl vorst zichtbaar is,
zonder muisfocus of ondoorzichtige achtergrond. Geen ongewenst zwart scherm.
Test drempels, onderbreking, regen/sneeuw, snelle grenswissel, freeze, effect-uit,
resource-stop en compatibiliteit met andere visuele effecten.

### Fase 7 — beveiliging en gemeten performance

Audit alle nieuwe ingangen, schema's, autoriteit, writes, callbacks en cleanup.
Meet client/server idle, overgangen, kaart open/gesloten en maximum gebieden.
Noteer build, spelersaantal, instellingen, meetduur en gemiddelde/pieken.
Geen claims van 0 ms op basis van code-inspectie. Statische scannerwaarschuwingen
controleren op werkelijke control flow; voeg geen Wait toe aan eindige berekeningen.

### Fase 8 — eindcontrole en productrelease

Singleplayer, echte tweeclient-sync, twee admins gelijktijdig, late join bij zowel
cyclus- als grensovergang, resource/server restart en v1-upgrade/rollback.
Ontbrekende multiplayertests expliciet release-TODO; geen verzonnen goedkeuring.
Pas na eigenaarakkoord versie 2.0.0, product-README, changelog en release opruimen.

## Fase 1 oplevering en testinstructies

Automatisch: `lua5.4 tests/v2_phase1.lua` vanuit de resource-root. Deze test draait
zonder FiveM en controleert uitsluitend model/validatie, niet GTA-rendering.
Runtimebestand wordt alleen server-side geladen na shared/utils.lua.
Geen nieuwe threads, events, commands, native calls of runtime-bestanden.

Ingame op de ontwikkelbranch:
1. Bewaar config en data buiten de resource, stop normaal en installeer de branch.
2. Start; controleer serverconsole/F8 op fouten.
3. Open /mstrmenu; controleer hoofdadmin en gewone toegang zoals in v1.
4. Wijzig weer geleidelijk/direct, tijd, freeze en blackout; controleer resultaat.
5. Herstart normaal en controleer opgeslagen instellingen en menu opnieuw.

Een nieuwe Weercycli-tab is in Fase 1 bewust nog niet aanwezig. STOP na rapportage.
