# Fase 6B — acceptatie van taal en visuele afwerking

Maak vóór de update backups van config en data/state.json, data/admin.json en
hun .bak-bestanden buiten de resource. Installeer de hele testbranch; behoud
je runtime-data. Je bestaande hoofdadmin-ACE blijft hetzelfde.

## Taal en rechten

1. Open Instellingen als gewone admin en hoofdadmin. Alleen de persoonlijke
   kleuren staan hier; geen actieve serverconfiguratie en geen taalkeuze.
2. Open Beheer als hoofdadmin. Kies Engels en sla Serverinstellingen op.
   Controleer álle tabs, titels, knoppen, instellingen, weernamen in de keuzelijst,
   overgangsmeldingen, themafeedback en rechtenvelden. Alles hoort Engels te zijn.
3. Laat een tweede admin zijn menu openhouden. Binnen circa twee seconden moet
   ook diens menu Engels zijn, zonder dat onopgeslagen invoer wordt gewist.
4. Zet terug naar Nederlands. Herhaal de controle, inclusief foutieve invoer,
   verboden actie, actieve overgang en opslag-/rechtenfeedback waar van toepassing.
   Thema-namen als Champagne/Jade en identifiers blijven herkenbare eigennamen.
5. Controleer commandfeedback in beide talen. Commandnamen en technische
   argumenten veranderen niet: blijf bijvoorbeeld `instant` en `true` gebruiken.
6. Reconnect en herstart de resource: de opgeslagen taal moet behouden blijven.
   Doe dit ook met een bestaand admin.json uit de vorige versie. Rechten en
   overige instellingen mogen niet verdwijnen. Gewone admins kunnen de taal
   niet wijzigen; de server weigert dat ook buiten de zichtbare UI.

## Tijd en afbeeldingen

- Zet de tijd op 04:59, 05:00, 06:59, 07:00, 18:59, 19:00, 20:59 en 21:00.
  Controleer het dagdeel en het zon/maan-icoon in Tijd en het overzichtskaartje.
  Laat de tijd ook één grens vanzelf passeren en test met bevroren tijd.
- Smog: nevelbanen met gedempte zon; mist: wolk met mistbanen.
- Zwaarbewolkt/OVERCAST: één wolk. Wolken/CLOUDS: drie wolken.
- Opklaringen/CLEARING: zon deels achter de wolk, zonder doorschijnende overlap.
- Neutraal: apart rustig zon/horizon-icoon.
- SNOWLIGHT: één sneeuwvlok. SNOW: twee. BLIZZARD: drie plus wind.
- Halloween: volle maan met vleermuis. Test ook op lichte themakleuren.

## Halloween in de wereld

Zet dynamisch weer uit zodat het type niet vanzelf verandert. Ga buiten staan.
Kies Halloween met Direct en bekijk het bij 12:00 en 23:00 met bevroren tijd.
Herhaal met een geleidelijke overgang en wacht tot deze volledig voltooid is.
Controleer met twee spelers en bij late join. Zet daarna helder weer terug:
neerslag moet verdwijnen, zonder achterblijvende sneeuwsporen of overrides.

De code-route en neerslagcleanup zijn automatisch getest. Of GTA het gewenste
Halloween-uiterlijk rendert, kan alleen ingame worden vastgesteld. Als het nog
niet werkt: stuur tijd, gamebuild, gebruikte overgang, F8/servermeldingen en
welke andere resources het weer kunnen beïnvloeden. Geen ingame succes claimen
op basis van alleen de weergegeven weernaam.

## Bestaand gedrag

Controleer join zonder zwart vlak, Escape/focus, thema bewaren, beheerrechten,
weer/tijd-sync, scroll en iconen bij 1280×720 en 1920×1080. Open/sluit een menu
tijdens een taalwijziging: het mag niet onverwacht heropenen of conceptinvoer
verliezen. Noteer eventuele resmon-verandering en fouten in F8/serverconsole.

Automatisch geslaagd: Lua core/NUI/beheerregressies, taalvalidatie en migratie,
commandvertalingen, beperkte snapshots, native-aanroep Halloween, JS-catalogus,
taalwissels zonder form-reset, dagdeelgrenzen en verschillende SVGs.
Er is geen echte CEF/GTA-renderingtest in de ontwikkelomgeving uitgevoerd.

Stop na deze tests. Fase 7 begint pas na expliciete goedkeuring.
