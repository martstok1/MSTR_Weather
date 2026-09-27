# MSTR_Weather — ingame validatie vóór Fase 6

Status: implementatie gereed voor testen. Fase 6 is niet gestart.

## 0. Installeren en veilig bewaren

1. Stop `MSTR_Weather` normaal via txAdmin/serverconsole. Dit bewaart live state.
2. Kopieer je huidige resource als backup naar een map buiten actieve resources.
   Bewaar vooral `config.lua`, `data/state.json` en eventueel `data/state.json.bak`.
3. Gebruik de bestanden uit de fix-branch. Een gewone pull van `main` bevat deze
   wijzigingen pas na merge. Je kunt de fix-branch selecteren in VS Code of op
   GitHub die branch openen en via **Code → Download ZIP** downloaden.
4. Bij ZIP-gebruik: zet de inhoud in je bestaande resource-map `MSTR_Weather`,
   niet in een extra geneste map. `fxmanifest.lua` moet direct in die map staan.
5. Neem je eigen configkeuzes zorgvuldig over. De oude `Config.Weather.Weights`
   fallback is vervallen; de gewone transition graph blijft configureerbaar.
6. De map `data/` moet bestaan en schrijfbaar zijn. Er zit bewust geen opgeslagen
   ontwikkelstate in Git. Zet je backup-state terug als je die wilt behouden.
   Bij het overschakelen van de oude branch kan Git het oude tracked statebestand
   verwijderen; maak de backup dus vóór het wisselen van branch.
7. Zorg dat andere weather/time-resources voor deze test niet tegelijk sturen.
   Controleer bestaande ACE-toegang voor `mstr.weather.admin`; het script wijzigt
   geen server.cfg/resources.cfg of permissions buiten de resource.
8. Start `MSTR_Weather`. Controleer F8 en serverconsole op errors.

Alle slashcommands hieronder zijn ingame. `restart MSTR_Weather`,
`stop MSTR_Weather` en `ensure MSTR_Weather` zijn serverconsolecommands.
Met de standaardconfig duurt een smooth overgang 30 seconden.
Gebruik een compatibele chatresource om commandmeldingen te zien.

## 1. Start en permissions

- [ ] `/mstrdebug` toont geldige weather/time/dynamic/blackout/freeze/scale.
- [ ] Geen Lua-errors in F8/serverconsole bij starten en opnieuw starten.
- [ ] Admin kan onderstaande commands gebruiken.
- [ ] Account zonder ACE krijgt geen toegang tot debug of muterende commands.
- [ ] Ongeldige input wijzigt niets: `/mstrweather ONZIN`,
  `/mstrweather RAIN verkeerd`, `/mstrtime 24:00`, `/mstrtime freeze misschien`,
  `/mstrtime scale -1`, `/mstrtime scale 11`, `/mstrblackout misschien`.

## 2. Weather, regen en sneeuw

Begin met `/mstrweather dynamic false`. Zet `/mstrtime 12:00` en
`/mstrtime freeze true` voor een constante belichting tijdens vergelijking.

| Actie | Verwacht resultaat |
|---|---|
| `/mstrweather CLEAR instant` | Direct helder; geen actieve overgang. |
| `/mstrweather CLOUDS smooth` | Geleidelijke overgang; na circa 30 s klaar. |
| Na afloop `/mstrweather RAIN smooth` | Geleidelijke regenovergang; regen en geluid werken. |
| Na afloop `/mstrweather CLEAR smooth` | Regen/geluid stoppen na overgang; plassen mogen natuurlijk opdrogen. |
| `/mstrweather THUNDER instant`, daarna `CLEAR instant` | Directe wissel, geen blijvende regenoverride. |
| `/mstrweather SNOW instant` | Sneeuwweer, grondsneeuw en sporen. |
| Herhaal met `SNOWLIGHT`, `BLIZZARD` en `XMAS` | Geen crashes/native-errors; effecten passen bij het weertype. |
| `/mstrweather CLEAR instant` | Grondsneeuw verdwijnt; geen nieuwe sneeuwsporen. |

- [ ] Herhaal `SNOW → CLEAR` ook met smooth, en loop/rij om nieuwe sporen te controleren.
- [ ] Test `Config.Weather.EnableSnowTrails = false` na restart: wel grondsneeuw,
  geen geforceerde voertuig-/voetsporen. Zet je gewenste instelling terug.

## 3. Lopende overgang, onderbreken en late join

1. `/mstrweather CLEAR instant`, daarna `/mstrweather RAIN smooth`.
2. Na ongeveer 10 seconden: `/mstrweather CLOUDS smooth`.
   Verwacht: melding dat een overgang actief is; oorspronkelijke overgang loopt
   verder zonder terug te springen naar CLEAR.
3. `/mstrweather EXTRASUNNY instant` onderbreekt wel direct. Wacht daarna minstens
   35 seconden: het oude RAIN-target mag niet alsnog terugkomen.
4. Start opnieuw `CLEAR → RAIN smooth`. Laat een tweede echte speler middenin
   aansluiten. Vergelijk de lucht/regen: de tweede speler begint bij de huidige
   voortgang, niet opnieuw volledig bij CLEAR. Beide eindigen op RAIN.
5. Herhaal met een langere `TransitionDuration = 120` als verbinden te lang duurt.
   Zet de waarde na testen terug op 30.

- [ ] Overgangsverloop visueel soepel op beide clients.
- [ ] Late join/reconnect ontvangt ook de actuele tijd en blackout.
- [ ] Niet met twee spelers kunnen testen? Markeer dit expliciet als **NIET GETEST**.

## 4. Tijd

Houd Dynamic Weather uit zodat je je op de klok kunt richten.

| Actie | Verwacht resultaat |
|---|---|
| `/mstrtime freeze false`, `/mstrtime scale 2` | Klok loopt ongeveer 2 gameseconden per echte seconde. |
| `/mstrtime 23:59` | Na ongeveer 30 s naar 00:00 bij scale 2. |
| `/mstrtime 18:00`, daarna `/mstrtime 08:00` | Direct achteruit, geen omweg via een hele dag. |
| `/mstrtime freeze true`, 30 s wachten | Tijd blijft staan. |
| `/mstrtime freeze false` | Verder vanaf bevroren tijd; geen inhaalsprong. |
| Scales `0`, `0.5`, `1`, `2`, `10` | Stilstand respectievelijk passende snelheid. |

- [ ] Kijk minstens 2 minuten naar tijd/lucht: geen hinderlijke sprongen bij correcties.
- [ ] Vergelijk twee spelers, ook bij aansluiten/reconnect en freeze.
- [ ] Zet scale terug op 2 en freeze op false na de test.

## 5. Dynamic Weather

Zet tijdelijk `Config.DynamicWeather.IntervalMinutes = 0.1` en restart de resource.
Er wordt dan iedere 6 seconden een beslissing gepland, maar een bestaande
30-secondenovergang wordt niet gestapeld: de scheduler wacht verder.

- [ ] `/mstrweather dynamic true`: `/mstrdebug` toont een countdown.
- [ ] Laat minstens drie automatische overgangen volledig aflopen; graph blijft logisch.
- [ ] `/mstrweather dynamic false`: geen nieuwe automatische overgangen.
  Een reeds geaccepteerde overgang mag nog wel afronden.
- [ ] Snel meerdere keren true/false zetten veroorzaakt geen dubbele cycli.
- [ ] Handmatig `/mstrweather FOGGY instant` met dynamic aan: vervolg vanuit FOGGY.
- [ ] Handmatig XMAS/HALLOWEEN: logisch vervolg, geen reset naar configdefault.
- [ ] Optioneel fallbacktest op testserver: maak alleen `Transitions.FOGGY = {}`,
  restart, zet FOGGY en dynamic aan. Verwacht waarschuwing en FOGGY → CLOUDS.
  Herstel daarna de oorspronkelijke graph.
- [ ] Zet `IntervalMinutes` terug op 15 en restart na de test.

## 6. Blackout

1. Zet `/mstrtime 23:00`, `/mstrtime freeze true`.
2. `/mstrblackout true`: kunstmatige wereldverlichting uit.
3. `/mstrblackout false`: verlichting terug.
4. Test voertuiglichten met `Config.Blackout.AffectVehicles = false` en `true`,
   telkens na restart. Bij false blijven voertuiglichten buiten blackout;
   bij true worden ze meegenomen. Zet daarna je gewenste configwaarde terug.
5. Laat een tweede speler aansluiten terwijl blackout aanstaat.

## 7. Persistence en herstarts

Voer bestandstests alleen met backups en op de testserver uit.

- [ ] Stel herkenbare waarden in: RAIN instant, dynamic false, 18:30,
  freeze true, scale 0.5, blackout true. Wacht 2 seconden.
- [ ] `data/state.json` en `.bak` bestaan en bevatten geldige JSON.
- [ ] `restart MSTR_Weather`: waarden blijven behouden, beide clients synchroniseren.
- [ ] Herhaal met dynamic/blackout/freeze **false**: false blijft behouden.
- [ ] Herhaal na een volledige normale serverherstart.
- [ ] Start CLEAR → RAIN smooth en restart na 5 seconden:
  na restart is RAIN direct actief; de overgang zelf wordt niet hervat.
- [ ] Wijzig tijd of blackout en stop direct, vóór de debounce verstreken is:
  na starten is de laatste toestand toch hersteld.
- [ ] Zonder mutaties: geen elke-seconde/minuut writes. Een normale stop schrijft wel.

Voor elk scenario hieronder: **eerst stoppen**, daarna de bestanden aanpassen,
dan starten. Stoppen ná het aanpassen zou jouw testbestand opnieuw overschrijven.

| Bestandsituatie | Verwacht resultaat |
|---|---|
| Beide runtimebestanden ontbreken | Defaults uit config, geen crash. |
| Primaire bestand leeg/kapotte JSON, backup geldig | Waarschuwing + herstel vanuit backup. |
| Beide bestanden leeg/ongeldig | Waarschuwing + configdefaults. |
| Primaire JSON heeft deels ongeldige waarden | Geldige velden behouden; ongeldige velden naar defaults. |
| `version: 99` in primaire JSON | Niet als huidig formaat accepteren; backup/defaults gebruiken. |

Voorbeeld van deels ongeldige JSON: weather `"ONZIN"`, time.hour `99`, timeScale
`999`, blackout `"false"` (string), dynamicWeather `false` (echte boolean).
Na laden moet dynamic false blijven; de ongeldige velden krijgen configdefaults.
De backup bevat een vorige succesvolle toestand en kan dus bewust iets ouder zijn.

## 8. Cleanup en performance

- [ ] Stop de resource terwijl sneeuw, freeze en blackout actief zijn.
  Tijdoverride, geforceerde grondsneeuw/sporen en blackout worden vrijgegeven.
- [ ] Start opnieuw: opgeslagen toestand wordt weer correct toegepast.
- [ ] Controleer `resmon 1` in F8 bij stabiel weer, actieve overgang en dynamic uit.
  Noteer waarden; er is hier geen live performanceclaim gedaan.
- [ ] Geen nieuwe errors of snel oplopende activiteit na herhaald veranderen.

## Testresultaten teruggeven

```text
Versie/branch:
Server artifact / game build:
Start + ACE:
Weather + regen/sneeuw:
Onderbreken overgang:
Late join / twee spelers:
Tijd:
Dynamic Weather:
Blackout:
Persistence + herstarts:
Cleanup + resmon:
Errors (exacte tekst/screenshot):
Niet getest:
```

De automatische Lua-tests controleren logica met mocks. GTA-weergave, echte
netwerksynchronisatie, schrijfrechten en live resourcegedrag zijn pas bevestigd
na deze runtimechecks. Stop na testen; Fase 6 start alleen na akkoord van Mart.
