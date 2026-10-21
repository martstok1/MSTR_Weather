# MSTR_Weather V2 — complete testversie

Versie: **2.0.0-rc.1**. Alle nieuwe bediening zit in het bestaande `/mstrmenu`.
De tijdelijke `/mstrcycle`-commando's en bestandsimport zijn vervallen.
Deze uitbreiding is niet ingame goedgekeurd: de eigenaar voert de tests uit.
Er zijn voor deze oplevering geen automatische, browser-, FiveM- of performancetests uitgevoerd.
Alleen de Lua- en JavaScript-syntax is gecontroleerd, zonder de scripts uit te voeren.

## Installeren

1. Stop MSTR_Weather normaal en bewaar `config.lua`, eigen afbeeldingen en de hele
   `data/`-map buiten de resource als backup.
2. Gebruik de volledige branch `feature/v2-phase2-cycles`. Kopieer alle
   gewijzigde én nieuwe bestanden, inclusief het manifest, shared-, server-, client-
   en webbestanden. De oude Phase5-zip is niet de bron voor V2.
3. Behoud je eigen config en runtime-JSON-bestanden. Er is geen database of nieuwe
   resource nodig. De resourcefolder blijft `MSTR_Weather`.
4. Start de resource, join en open `/mstrmenu` met je bestaande hoofdadminaccount.

Het bestaande recht `mstr.weather.superadmin` geeft toegang tot **Weercycli**,
**Gebieden** en **Temperatuur**. Hetzelfde recht wordt op de server gecontroleerd.
Gewone admins blijven hun eerder toegekende V1-bediening houden. De gedeelde taal
komt uit Beheer; persoonlijke kleuren gelden ook voor de nieuwe tabbladen.

## Weercycli

Klik **Nieuw** en geef de cyclus een naam en starttijd. Voeg maximaal 24 weerblokken
toe. Per blok stel je weertype, percentage, overgangsduur en temperatuur in.
Met de pijlen wijzig je de volgorde; met × verwijder je een blok.

- Samen exact 100%, maximaal twee decimalen: percentage is tijd, geen kans.
- Een speldag heeft 86400 spelseconden. 50% duurt dus 12 speluren.
- De overgang staat aan het begin van het blok en telt mee in het percentage.
- De overgangsduur is in **spelseconden**, maximaal de duur van dat blok.
- De tijdlijn toont begin/eindtijden; de duurweergave rekent ook om naar echte
  seconden met de huidige tijdsnelheid. Bij freeze of scale 0 staat er Gepauzeerd.
- Schema-1-cycli blijven leesbaar en gebruiken 20 °C. Opslaan in de editor schrijft
  schema 2 met expliciete temperatuur per blok. De opslagcontainer blijft schema 1.

**Opslaan** bewaart de cyclus; **Globaal activeren** kiest deze als globale omgeving.
Een opgeslagen wijziging aan een gebruikte cyclus geldt direct. **Dupliceren** maakt
een nieuw concept. **Globale cyclus stoppen** bevestigt eerst de wissel naar vast weer.
Een gebruikte cyclus kun je pas verwijderen nadat globale en gebiedskoppelingen weg zijn.

Gewone weerbediening bedient de **globale omgeving**. Een hoofdadmin krijgt een
bevestiging als die actie een globale cyclus stopt. Bij een gewone admin wordt deze
actie geweigerd zolang de cyclus actief is. Gebieden houden hun eigen instellingen.
Een geslaagde handmatige globale weerkeuze zet gewogen globaal weer uit.

## Gebieden

Maak een gebied of kies een voorbeeld voor Sandy Shores of het noorden. Voorbeelden
zijn concepten: ze werken pas nadat je ze opslaat. Kies per gebied:

- **Vast weer** met temperatuur.
- **Gewogen dynamisch** met relatieve gewichten, temperatuur en interval in echte minuten.
- **Weercyclus** uit de opgeslagen cycli; de temperatuur komt dan uit de cyclusblokken.

Schakel een gebied aan/uit zonder het te verwijderen. Buiten gebieden geldt het
globale weer. De spelklok en blackout blijven overal gelijk. Hoogte telt niet mee:
een vliegtuig boven het gebied hoort bij hetzelfde gebied.

De kaart is een **eigen schematische wereldkaart**, geen officiële GTA-straatkaart.
Noord staat boven; de coördinaten zijn GTA-wereldcoördinaten. Er zijn geen externe
kaarttegels, afbeeldingen of CodeM-assets gebruikt.

- **Veelhoek tekenen:** klik achtereenvolgens op de hoekpunten.
- **Rechthoek:** klik twee tegenoverliggende hoeken; vervangt het huidige concept.
- **Punten bewerken:** sleep een hoekpunt of wijzig X/Y onder de kaart.
- **Gebied verplaatsen:** sleep de hele vorm.
- **Selecteren:** klik een opgeslagen gebied om het te bewerken.
- **Kaart verschuiven** en het muiswiel: verschuiven en zoomen.
- **Mijn positie toevoegen:** gebruik je precieze positie in de wereld als hoekpunt.
- **Naar mijn positie:** centreert de kaart op jou.

Maximaal 32 gebieden, 64 punten per gebied, coördinaten -10000..10000. Overlap,
zelfsnijdende vormen, te kleine vormen en ongeldige cycluskoppelingen worden geweigerd.
Gedeelde grenzen mogen; een vaste ID-volgorde bepaalt de keuze op de grens. Er is
3 meter grensmarge en een korte stabiliteitsperiode tegen heen-en-weer flikkeren.
Grensovergangen lopen in echte seconden, dus ook met bevroren speltijd.

GTA kan slechts twee weertypes tegelijk mengen. Bij een onderbroken gebiedsovergang
wordt de bestaande mix eerst vloeiend afgemaakt, daarna wordt het nieuwe mengpaar
opgebouwd. Er is geen fysieke regenwolk die boven één gebied in de wereld hangt.

## Temperatuur en effecten

Temperatuur is een visuele waarde in Celsius, van -50 tot 60. Je stelt de temperatuur
in bij het gebied of het cyclusblok. Buiten gebieden/cycli geldt de globale temperatuur
uit **Temperatuur**. Het dashboard toont jouw lokale omgeving en temperatuur.

Warmte en koude staan standaard uit. Stel drempels, maximale intensiteit en opbouwduur
in en sla op. De instellingen gelden voor iedereen en worden onafhankelijk van de
bestaande instelling 'Weer en tijd bewaren' opgeslagen.

- **Hittetrilling:** een eigen runtime-timecyclemodificatie met beschikbare heat-haze-
  variabelen van jouw gamebuild. Andere actieve timecyclemodificaties krijgen voorrang.
  Na zo'n conflict blijft hitte uit totdat je hitte uit- en weer inschakelt.
- **Vorstranden:** transparante NUI-randen, zonder muisfocus en ook met het menu dicht.
- Geen gezondheidsschade, dorst, kledinglogica of wijzigingen aan andere scripts.
- Opbouw/afbouw verloopt geleidelijk; stoppen van de resource ruimt eigen effecten op.

De zichtbaarheid van hitte hangt af van gamebuild, grafische instellingen en andere
visuele resources. Ontbrekende variabelen geven een F8-waarschuwing. Visuele afstelling
en compatibiliteit zijn onderdeel van de ingame testronde, niet vooraf goedgekeurd.

## Opslag, herstel en rollback

`cycles.json` bewaart cycli, revisie en globale activatie. `regions.json` bewaart gebieden,
effectinstellingen en revisie. Beheer gebruikt revisies om een oud formulier te weigeren.
Bij een conflict blijft je invoer staan; herlaad bewust voordat je verder opslaat.

Beide bestanden hebben een `.bak` met de vorige geldige versie na een volgende write.
Een eerste save heeft nog geen vorige versie. Writes worden teruggelezen voordat de
live configuratie wordt vervangen. Een mislukte write laat de geheugenconfiguratie
intact, maar het primaire bestand kan beschadigd zijn: controleer het vóór herstart.
Er is geen automatische backuprestore die ongemerkt een oude cyclus activeert.
Herstel beschadigde opslag alleen met de resource gestopt. Bewaar cyclus- en
gebiedsbestanden samen zodat koppelingen geldig blijven.

De bestaande `state.json` en `admin.json` worden niet gemigreerd of verwijderd.
Cyclus- en gebiedsconfiguratie blijft bewaard als gewone omgevingspersistence uitstaat.
De spelklok na herstart volgt de bestaande V1-opslag/defaults. Er wordt geen offline
tijd ingehaald. Gewogen gebieden starten opnieuw vanaf hun ingestelde beginweer;
het laatste gelote regionale weertype is niet apart opgeslagen.

Rollback: stop V2, herstel je volledige V1-code/config-backup, behoud een aparte kopie
van alle V2-data en start V1. V1 gebruikt de extra bestanden niet. Bij terugkeer naar
V2 kunnen opgeslagen activaties terugkomen; controleer die bewust. Een rollback naar
alleen Fase 2 ondersteunt schema-2-temperatuurcycli niet: gebruik de bijbehorende backup.

## Jouw gezamenlijke testronde

Alles hieronder staat **open**. De eerdere 23 tests betroffen Fase 2, niet deze RC.

1. Start/join, F8/serverconsole en bestaande V1-menuonderdelen.
2. Hoofdadmin wel/geen ACE, gewone gebruikersrechten en NL/EN/thema's.
3. Cyclus aanmaken, ordenen, opslaan, dupliceren, activeren en verwijderen.
4. 100%-controle, ongeldige overgang, freeze, scale 0 en tijdsprongen.
5. Gebied tekenen, punten verplaatsen, overlapweigering en opgeslagen cyclus koppelen.
6. Binnen/buiten gebied rijden, grenspendelen, teleport, vliegtuig en snelle wissels.
7. Regen/sneeuw-cleanup, warmte/koude aan en uit, menu sluiten en resource stoppen.
8. Resource/server herstart, opgeslagen gegevens en upgrade/rollback.
9. Wanneer mogelijk: twee spelers in hetzelfde/andere gebied, late join, twee admins.
10. Resmon met menu dicht/open, kaart, overgangen en meerdere gebieden. Er is geen
    gemeten of gegarandeerde CPU-waarde voor deze versie.

Meld een probleem met versie, actie, verwachte uitkomst en F8/serverfout. De definitieve
2.0.0-release en goedkeuring van Fase 7/8 volgen pas na jouw bevindingen.
