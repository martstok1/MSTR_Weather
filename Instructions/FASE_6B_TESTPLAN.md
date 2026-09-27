# Fase 6B — ingame acceptatie

Fase 1–5, Fase 6A en de persoonlijke thema's zijn door Mart goedgekeurd.
Ook live sync met een tweede speler en de zichtbare resmon-waarde 0 zijn gemeld.
Onderstaande uitbreiding is automatisch getest met mocks, nog niet ingame.
Geen Fase 7 starten vóór goedkeuring van deze tests.

## Voorbereiding

Stop de resource. Bewaar config.lua, data/state.json en bestaande .bak-bestanden
buiten de resource. Bewaar vanaf deze versie ook data/admin.json en zijn .bak.
Installeer de complete testbranch; meng geen oude en nieuwe web/Lua-bestanden.
Zorg dat data/ schrijfbaar is. Gebruik twee accounts, waarvan één gewone tester.

Voeg in de vanuit server.cfg geladen permissions.cfg toe:

```cfg
add_ace identifier.fivem:JOUW_FIVEM_ID mstr.weather.superadmin allow
```

Vervang alleen JOUW_FIVEM_ID door je numerieke Cfx-id. Herstart de server om de
config opnieuw te laden. In Beheer kun je de online identifiers terugvinden.

## Rechten

1. Jouw account ziet Beheer. Een tester zonder rechten kan /mstrmenu niet openen.
2. Geef de tester alleen Menu bekijken: dashboard en thema's werken, bediening
   en Beheer ontbreken. Commands mogen geen toestand veranderen.
3. Vink Weer en Tijd aan: beide menucontrols en commands werken; dynamic en
   blackout blijven verboden. Test daarna ieder vinkje apart en gezamenlijk.
4. Trek alle rechten in terwijl het menu openstaat: het sluit bij de volgende
   serverupdate. Een daaropvolgende actie of command wordt direct geweigerd.
5. Test ook een gewone legacy-admin: bediening werkt, Beheer ontbreekt. Een
   expliciete regel met alle vinkjes uit moet ook deze toegang intrekken.
6. Test jouw hoofdadmin-ACE verwijderen/toevoegen. Alleen de regel uit het
   bestand verwijderen of de resource herstarten verwijdert geen actieve ACE.
   Gebruik een volledige serverherstart, of tijdelijk in de serverconsole:

   ```cfg
   remove_ace identifier.fivem:JOUW_FIVEM_ID mstr.weather.superadmin allow
   ```

   Zonder een andere brede/inherited grant verdwijnt Beheer bij de volgende
   update. Gewone toegang kan blijven bestaan via legacy ACE of een gebruikersregel.
   Voeg de ACE terug met add_ace voor de positieve test. Bewerk ook de cfg zodat
   de gewenste toestand na een herstart behouden blijft.

## Bediening en synchronisatie

- Test alle weertypes: bijpassende illustratie; regen, sneeuw, mist en onweer
  zijn herkenbaar. Blackout wisselt lamp aan/uit; dynamic wisselt cyclus/pauze.
- Test smooth, tweede smooth tijdens een overgang (weigeren), expliciet Direct,
  tijd instellen, bevriezen/hervatten, snelheid, dynamic en blackout.
- Controleer de wereld en beide menu's, ook bij late join en resourceherstart.
- Verander de zes instellingen onder Beheer: grenzen worden gecontroleerd,
  Instant uit weigert Direct, interval begint opnieuw, sneeuwsporen en
  voertuigverlichting wijzigen bij beide spelers. Overgangsduur beïnvloedt
  volgende overgangen, niet de al lopende overgang.
- Persistence uit: nieuwe wereldtoestand wordt niet opgeslagen. Rechten en
  instellingen blijven wél bewaard. Aan: de huidige wereldtoestand wordt
  opgeslagen. Herstart en controleer opgeslagen instellingen/rechten/state.
- Laat een formulier open tijdens andere wijzigingen: gewone polling bewaart
  je invoer. Een verouderd beheerformulier wordt geweigerd; Opnieuw laden haalt
  de laatste beheerdata op en vervangt je conceptinvoer.

## NUI en regressies

- Join zonder menu: geen zwart vlak, geen muisfocus. Escape/sluitknop/command,
  resource-stop en reconnect laten geen focus of menu achter.
- Controleer thema's, kleurkiezers, lange namen en scroll bij 1280×720 en 1920×1080.
  Spelernamen moeten gewone tekst blijven; ze mogen geen HTML uitvoeren.
- Snel dubbelklikken mag geen dubbele actie veroorzaken. Sluit tijdens een
  verzoek: een laat antwoord mag het menu niet terug openen.
- Controleer F8/serverconsole en resmon bij gesloten/open menu, overgangen en
  tweede speler. SVG's zijn lokale assets, zonder externe downloads/dependencies.
- Alleen op een wegwerp-testserver: onschrijfbare data/ en beschadigde admin.json
  leveren een opslagfout/blokkade, geen nieuw recht. Een .bak wordt nooit vanzelf
  teruggezet. Herstel met de resource gestopt en controleer grants vóór herstart.

Noteer per onderdeel geslaagd/mislukt met F8/servermelding en reproductiestappen.
Stop na deze tests en laat de uitkomst beoordelen vóór Fase 7.
