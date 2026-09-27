# MSTR_Weather V1.0 — Werkinstructie voor coding agents (2026)

> Deze werkinstructie is AI-agnostisch. Gebruik hem met iedere coding agent of lokale AI.
> De huidige bestanden in de projectmap zijn altijd de technische bron van waarheid.

---

# 0. HOOFDREGELS VOOR DE CODING AGENT

Lees dit hoofdstuk volledig voordat je iets plant of wijzigt.

## 0.1 Bronvolgorde

Wanneer informatie elkaar tegenspreekt, gebruik deze volgorde:

1. De **huidige bestanden in `MSTR_Weather/`**.
2. Deze werkinstructie.
3. Expliciete instructies van de gebruiker in de huidige opdracht.
4. `cd_easytime` uitsluitend als functionele referentie.
5. Eigen aannames pas als laatste redmiddel.

Gebruik nooit een oude chat-samenvatting of eerdere versie van code als bron wanneer de huidige projectbestanden iets anders laten zien.

## 0.2 Huidige werkende code niet onnodig herschrijven

Wanneer een eerdere fase door de gebruiker als getest/werkend is gemarkeerd:

- behandel die implementatie als **known-good baseline**;
- verander die code alleen wanneer de nieuwe fase dit technisch vereist;
- leg vooraf uit waarom zo'n wijziging noodzakelijk is;
- maak geen grote refactors “omdat het netter kan”;
- introduceer geen nieuwe architectuur naast een bestaande werkende architectuur;
- herstel nooit automatisch oude code uit eerdere versies.

Doel: nieuwe functionaliteit **bovenop** de bestaande core bouwen, niet iedere fase opnieuw beginnen.

## 0.3 Werk altijd fase-gebonden

Werk uitsluitend aan de fase die expliciet is opgedragen.

Als de opdracht bijvoorbeeld is:

`FASE 4 — Dynamic Weather`

dan mag je NIET alvast bouwen:

- Persistence
- Blackout
- NUI
- Logging UI
- Presets
- Forecast
- Zones
- Buckets
- Database-integratie
- Andere toekomstige features

Voorbereidende interfaces of configvelden mogen alleen worden toegevoegd wanneer ze direct nodig zijn voor de huidige fase.

## 0.4 STOP-regel

Na iedere fase:

1. implementeer alleen die fase;
2. voer een self-review uit;
3. geef testinstructies;
4. rapporteer welke bestanden zijn gewijzigd;
5. **STOP**.

Begin nooit automatisch aan de volgende fase.

## 0.5 Geen ongewenste dependencies

MSTR_Weather V1.0 moet standalone functioneren.

Voeg zonder expliciete toestemming GEEN dependency toe op:

- oxmysql
- ox_lib
- ESX
- QBCore
- Qbox
- database resources
- externe API's
- externe notification resources
- andere server resources

Voeg ook geen dependency toe “voor later”.

## 0.6 Geen lokale `require()`-architectuur voor resourcebestanden

Lokale MSTR_Weather-bestanden worden via `fxmanifest.lua` geladen.

Gebruik voor interne modules één gedeelde namespace:

```lua
MSTR = MSTR or {}

MSTR.Constants
MSTR.Utils
MSTR.Permissions
MSTR.State
MSTR.WeatherEngine
MSTR.TimeEngine
```

Gebruik dus niet:

```lua
require('state')
require('weather_engine')
require('time_engine')
require('constants')
```

voor bestanden binnen deze resource.

## 0.7 Manifest is een contract

Houd `fxmanifest.lua` geldig en minimaal.

Gebruik:

```lua
fx_version 'cerulean'
game 'gta5'
```

Gebruik correcte directives:

```lua
shared_scripts { ... }
server_scripts { ... }
client_scripts { ... }
```

Gebruik NIET:

```lua
config_script
client { ... }
server { ... }
shared { ... }
```

Voeg niet onnodig toe:

```lua
lua54 'yes'
```

Lua 5.4 is in moderne FiveM builds standaard.

De load order moet altijd logisch zijn:

1. config
2. shared constants/utils
3. services/engines
4. main entrypoints

Controleer na iedere wijziging dat ieder bestand uit het manifest daadwerkelijk bestaat.

## 0.8 Server is authority

De server is de enige authority voor globale environment-state.

Clients mogen:

- state lezen;
- visuele GTA/FiveM natives toepassen;
- requests naar de server sturen.

Clients mogen NIET zelfstandig globale state bepalen.

Mutaties volgen altijd:

```text
Client/NUI/Command
        ↓
Server permission check
        ↓
Server validation
        ↓
Service/engine
        ↓
Central state
        ↓
Replication
        ↓
Clients apply environment
```

## 0.9 Server-side security is verplicht

Iedere muterende serverevent of command moet:

- permissions controleren;
- input valideren;
- ongeldige requests weigeren;
- geen clientwaarde blind vertrouwen.

Een client-side permission check is nooit voldoende.

## 0.10 Geen API/native gokken

Wanneer niet zeker is welke FiveM/Cfx native of API-semantiek correct is:

- controleer officiële Cfx/FiveM documentatie;
- gebruik geen verzonnen native;
- gebruik geen “waarschijnlijk bestaat dit” implementatie;
- documenteer kort waarom de gekozen native nodig is.

## 0.11 Geen stille regressies

Na iedere fase controleer expliciet dat bestaande functionaliteit nog werkt.

Een fase is NIET succesvol wanneer de nieuwe feature werkt maar een eerdere feature stuk is gegaan.

## 0.12 Geen onnodige bestanden

Maak geen:

- tijdelijke persistence engines;
- database adapters;
- framework bridges;
- lege toekomstige modules;
- placeholder systemen die threads starten;
- half afgemaakte toekomstige features.

Een leeg toekomstig mapje is acceptabel; actieve ongebruikte code niet.

---

# 1. DOEL VAN HET PROJECT

Bouw een volledig nieuwe FiveM-resource:

`MSTR_Weather`

MSTR_Weather is een moderne weather- en time-managementresource voor FiveM.

De bestaande `cd_easytime` resource mag uitsluitend worden gebruikt als **functionele referentie**:

- welke problemen een weather/time sync moet oplossen;
- welke edge-cases bestaan;
- welke functies gebruikers verwachten.

Kopieer niet simpelweg de EasyTime-architectuur, UI of code.

V1.0 moet stabiel, veilig, standalone, onderhoudbaar en uitbreidbaar zijn.

---

# 2. PROJECTGRENZEN

## 2.1 Toegestane projectmap

Werk uitsluitend binnen:

```text
MSTR_Weather/
```

tenzij de gebruiker expliciet vraagt om een bestand daarbuiten te wijzigen.

Wijzig niet automatisch:

- `server.cfg`
- `resources.cfg`
- andere resources
- EasyTime
- frameworkconfiguratie
- permissions-bestanden buiten de resource

Wanneer externe configuratie nodig is, geef alleen duidelijk aan welke regel de gebruiker zelf moet toevoegen.

## 2.2 EasyTime

`cd_easytime` is read-only referentiemateriaal.

Nooit:

- bestanden daarin wijzigen;
- code rechtstreeks kopiëren;
- de resource als dependency maken;
- dezelfde events/namen overnemen zonder reden.

---

# 3. VASTE ARCHITECTUURREGELS

## 3.1 Namespace

Gebruik:

```lua
MSTR = MSTR or {}
```

en daarna bijvoorbeeld:

```lua
MSTR.Constants = MSTR.Constants or {}
MSTR.Utils = MSTR.Utils or {}
MSTR.Permissions = MSTR.Permissions or {}
MSTR.State = MSTR.State or {}
MSTR.WeatherEngine = MSTR.WeatherEngine or {}
MSTR.TimeEngine = MSTR.TimeEngine or {}
```

## 3.2 Central state

Alle globale environment-state loopt via één state-service.

Andere modules mogen niet willekeurig overal `GlobalState[...]` schrijven.

Gebruik conceptueel:

```text
MSTR.State.SetWeather()
MSTR.State.SetDynamicWeather()
MSTR.State.SetBlackout()
MSTR.State.SetTimeFrozen()
MSTR.State.SetTimeScale()
MSTR.State.SetTimeAnchor()
MSTR.State.GetSnapshot()
```

De precieze functies mogen verschillen wanneer de huidige code al een werkend equivalent heeft.

## 3.3 `nil` versus `false`

Bij boolean state is `false` een geldige waarde.

Gebruik dus:

```lua
if value == nil then
```

en NIET:

```lua
if not value then
```

wanneer `false` geldig is.

Ook getters mogen nooit:

```lua
return stateValue or Config.Default
```

gebruiken wanneer `stateValue == false` geldig kan zijn.

## 3.4 ACE permissions

Minimaal:

```text
mstr.weather.admin
```

De server gebruikt `IsPlayerAceAllowed`.

Houd rekening met runtime-resultaten die afhankelijk van binding/build als boolean of truthy numerieke waarde kunnen terugkomen.

Normaliseer de uitkomst naar een echte Lua boolean.

Nooit standaard toegang verlenen voor “development”.

## 3.5 Debug

Gebruik één centrale:

```lua
Config.Debug = false
```

Gebruik waar mogelijk:

```lua
MSTR.Utils.Debug(...)
MSTR.Utils.Info(...)
MSTR.Utils.Warn(...)
```

Geen tientallen lokale `DebugLog()` implementaties wanneer de shared utility bestaat.

Errors en belangrijke warnings mogen zichtbaar blijven wanneer debug uit staat.

---

# 4. CONFIG-REGELS

`config.lua` is bedoeld voor server owners.

Gebruik overzichtelijke groepen:

```text
Debug
General
Branding
Permissions
Weather
DynamicWeather
Time
Blackout
Persistence
Logging
UI
```

Geen dubbele settings.

Gebruik expliciete eenheden in namen wanneer ambiguïteit mogelijk is.

Dus liever:

```lua
IntervalMinutes = 15
TransitionDurationSeconds = 30
```

dan:

```lua
Interval = 15
Duration = 30
```

als niet direct duidelijk is wat de eenheid is.

---

# 5. BRANDING

Branding is configureerbaar.

Minimaal:

```lua
Config.Branding = {
    Name = 'MSTR Weather',
    Logo = 'images/logo.png',
    ShowName = true
}
```

Het logo mag later niet hardcoded in HTML/CSS/JS staan.

Een server owner moet kunnen wijzigen naar bijvoorbeeld:

```lua
Config.Branding.Logo = 'images/myserver.png'
```

Gebruik lokale resource-assets.

De daadwerkelijke NUI-implementatie van branding hoort pas bij de betreffende UI/brandingfase.

---

# 6. WEATHER TYPES

Houd één centrale whitelist met ondersteunde weather types.

Bijvoorbeeld:

```text
EXTRASUNNY
CLEAR
CLOUDS
SMOG
FOGGY
OVERCAST
RAIN
THUNDER
CLEARING
NEUTRAL
SNOW
BLIZZARD
SNOWLIGHT
XMAS
HALLOWEEN indien daadwerkelijk ondersteund
```

Server-side validatie blijft verplicht, ook wanneer de UI alleen geldige opties toont.

Normaliseer waar nuttig invoer naar uppercase vóór validatie.

---

# 7. WEATHER ARCHITECTUUR

## 7.1 Eén Weather Engine

Er mag maar één echte weather implementation bestaan.

Alle weather changes — handmatig, dynamic weather, toekomstige NUI, exports — moeten uiteindelijk via dezelfde Weather Engine lopen.

Niet:

```text
Command → eigen weather code
Dynamic Weather → andere weather code
NUI → derde weather code
```

Wel:

```text
Command
Dynamic Weather
NUI
Exports
    ↓
MSTR.WeatherEngine
    ↓
MSTR.State
    ↓
Clients
```

## 7.2 Client responsibility

Client past de GTA/FiveM weather natives toe.

Centraliseer weather natives in de client weather module.

Verspreid weather natives niet over meerdere clientbestanden.

## 7.3 Smooth vs instant

Ondersteun:

- smooth transition;
- instant transition.

Een smooth transition moet daadwerkelijk voltooid worden.

Start geen tweede transition bovenop een bestaande transition zonder expliciet gedrag daarvoor.

## 7.4 Rain cleanup

Wanneer rain stopt moet rain intensity/effect-state correct worden opgeruimd.

## 7.5 Snow cleanup

Sneeuwsystemen zoals:

- ground snow;
- vehicle trails;
- ped footprints;

moeten correct worden geactiveerd én verwijderd wanneer snow weather eindigt.

---

# 8. TIME ARCHITECTUUR

## 8.1 Geen per-seconde GlobalState clock

De server mag NIET iedere seconde hour/minute naar `GlobalState` schrijven.

Gebruik een canonical time model.

Conceptueel:

```text
base game time
server timestamp / game timer anchor
time scale
frozen state
```

Clients berekenen lokaal de voortgang tussen synchronisatiemomenten.

## 8.2 Synchroniseer bij gebeurtenissen

Synchroniseer opnieuw wanneer:

- tijd handmatig verandert;
- freeze verandert;
- scale verandert;
- resource start;
- speler join/resync;
- rustige periodieke correctie indien noodzakelijk.

## 8.3 Geen fractionele clock-state

Bewaar geen fractionele minuten in globale state.

Reken intern nauwkeurig, maar pas GTA clock values als geldige integers toe.

## 8.4 Wrap-around

Moet correct werken:

```text
23:59 → 00:00
```

Ook handmatig achteruitzetten moet correct werken:

```text
18:00 → 08:00
```

Freeze → resume mag geen grote ongewenste tijdsprong veroorzaken.

---

# 9. DYNAMIC WEATHER ARCHITECTUUR

Dynamic Weather is een scheduler bovenop de bestaande Weather Engine.

Hij mag NOOIT zelf rechtstreeks client weather natives aanroepen.

Flow:

```text
Dynamic Weather Scheduler
        ↓
select next weather
        ↓
MSTR.WeatherEngine
        ↓
state + client application
```

## 9.1 Weather graph

Geen volledig random weather.

Gebruik een transition graph.

Voorbeeld:

```text
EXTRASUNNY
    ↓
CLEAR
 ↙      ↘
CLOUDS  EXTRASUNNY
   ↓
OVERCAST
 ↙     ↘
RAIN   CLEARING
 ↓
THUNDER
 ↓
RAIN
 ↓
CLEARING
 ↓
CLOUDS
```

## 9.2 Weighted random

Wanneer:

```lua
CLEAR = {
    CLOUDS = 70,
    EXTRASUNNY = 30
}
```

is geconfigureerd, moet de selector daadwerkelijk weighted random gebruiken.

Niet simpelweg één van twee entries met 50/50 kiezen.

## 9.3 Alle actieve weather types moeten een pad hebben

Een weather type dat handmatig actief kan worden, moet bij Dynamic Weather:

- een expliciete graph-entry hebben; of
- een gecontroleerde veilige fallback hebben.

Voorkom onlogische fallback zoals:

```text
FOGGY → THUNDER
```

tenzij expliciet toegestaan.

## 9.4 Special weather

Speciale weather zoals:

```text
SNOW
XMAS
HALLOWEEN
```

hoeft niet automatisch vanuit normale zomer/weather progression gekozen te worden.

Als een admin zo'n weather handmatig activeert, moet Dynamic Weather er wel logisch uit kunnen hervatten.

## 9.5 Enable/disable

Bij disable:

- annuleer toekomstige automatische wijzigingen;
- huidig weather blijft staan;
- handmatige weather blijft werken.

Bij enable:

- hervat vanaf huidig weather;
- reset niet naar default weather;
- start een nieuwe geldige interval countdown.

---

# 10. PERFORMANCE

Geen onnodige:

```lua
while true do
    Wait(0)
end
```

Gebruik event-driven state waar mogelijk.

Als een native periodiek opnieuw moet worden toegepast:

- kies de laagste redelijke frequentie;
- gebruik hogere frequentie alleen tijdens actieve transitions;
- verlaag de frequentie bij stabiele state.

Geen complete state meerdere keren per seconde naar alle spelers sturen.

Geen disk write per seconde/minuut.

---

# 11. COMMANDS EN TESTCOMMANDS

Commands zijn development/admin interfaces, geen aparte business logic.

Een command moet dezelfde service gebruiken als toekomstige NUI/exports.

Voor development mag `/mstrdebug` permanent bestaan.

`/mstrdebug`:

- alleen voor admin/ACE;
- mag niets muteren;
- toont actuele core-state;
- mag later worden uitgebreid met health/status informatie.

Andere tijdelijke testcommands mogen na de fase weer verwijderd worden.

---

# 12. RESOURCE LIFECYCLE

Ondersteun:

## Start

- config beschikbaar;
- shared modules geladen;
- state initialiseren;
- engines initialiseren;
- geen race condition door verkeerde manifestvolgorde.

## Player join / client start

Client moet actuele environment-state kunnen ophalen/toepassen.

## Resource restart

Clients moeten opnieuw een geldige environment krijgen.

## Resource stop

Voer noodzakelijke cleanup uit zodat tijdelijke weather/time overrides niet onbedoeld blijven hangen.

---

# 13. PROJECTSTRUCTUUR

Richtlijn:

```text
MSTR_Weather/
│
├── fxmanifest.lua
├── config.lua
│
├── shared/
│   ├── constants.lua
│   └── utils.lua
│
├── client/
│   ├── client.lua
│   ├── weather.lua
│   ├── time.lua
│   ├── blackout.lua          # pas wanneer betreffende fase wordt gebouwd
│   └── nui.lua               # pas wanneer betreffende fase wordt gebouwd
│
├── server/
│   ├── server.lua
│   ├── state.lua
│   ├── permissions.lua
│   ├── weather_engine.lua
│   ├── time_engine.lua
│   ├── dynamic_weather.lua   # indien afgesplitst en nodig
│   ├── persistence.lua       # pas Fase 5
│   └── logging.lua           # pas wanneer logging wordt gebouwd
│
├── data/
│   └── state.json            # pas zodra persistence is geïmplementeerd
│
└── web/                      # pas wanneer NUI wordt gebouwd
```

Gebruik geen leeg actief script alleen om deze structuur vooraf compleet te maken.

---

# 14. DEVELOPMENT-PROTOCOL PER FASE

Voor iedere fase voert de coding agent exact dit proces uit.

## Stap A — Inventory

Lees eerst de huidige relevante bestanden.

Rapporteer kort:

- huidige architectuur;
- welke bestaande services worden hergebruikt;
- welke bestanden waarschijnlijk moeten wijzigen;
- welke known-good functionaliteit behouden moet blijven.

Maak nog geen codewijzigingen als de gebruiker alleen om een plan vraagt.

## Stap B — Plan

Maak een concreet plan voor uitsluitend de gevraagde fase.

Noem:

- bestanden die worden gewijzigd;
- nieuwe bestanden;
- dataflow;
- state changes;
- permissions/validation;
- client/server-verdeling;
- tests.

## Stap C — Implementatie

Implementeer alleen de afgesproken fase.

Geen extra features.

## Stap D — Self-review

Controleer vóór afronding minimaal:

```text
Manifest geldig?
Alle manifestbestanden bestaan?
Geen nieuwe ongewenste dependency?
Geen lokale require() regressie?
Geen nieuwe duplicate state?
Geen client authority?
Alle mutaties server-side gevalideerd?
ACE-check aanwezig?
false/nil correct?
Geen code uit volgende fase?
Geen oude werkende feature verwijderd?
```

## Stap E — Testplan

Geef concrete commands/stappen voor ingame tests.

Maak onderscheid tussen:

- wat automatisch/statisch gecontroleerd is;
- wat alleen in echte FiveM runtime getest kan worden;
- wat door één speler niet volledig getest kan worden.

## Stap F — STOP

Rapporteer:

```text
Gewijzigde bestanden:
- ...

Nieuwe bestanden:
- ...

Niet gewijzigd:
- ...

Tests:
- ...

Openstaande TODO's:
- ...
```

Stop daarna.

---

# 15. FASE 1 — FOUNDATION

## Doel

Alleen de technische basis.

## Implementeren

```text
fxmanifest
folder structure
config structure
shared constants
shared utils
central state service
ACE permission service
debug utilities
minimal client/server entrypoints
```

## Niet implementeren

- Weather Engine
- Time Engine
- Dynamic Weather scheduler
- Persistence
- Blackout
- NUI
- Logging UI

## Acceptatiecriteria

- resource start zonder errors;
- Config correct geladen;
- namespace correct;
- state defaults correct;
- `false` state blijft geldig;
- ACE check werkt;
- `/mstrdebug` mag als read-only health check bestaan;
- geen ongewenste dependencies.

## STOP

Ga niet naar Fase 2 zonder gebruiker.

---

# 16. FASE 2 — WEATHER ENGINE

## Doel

Een complete handmatige Weather Engine waarop latere systemen kunnen bouwen.

## Implementeren

```text
weather manager
server-side validation
central weather state
instant weather
smooth weather transition
client-side weather application
rain handling/cleanup
snow handling/cleanup
late/client resync
```

## Architectuur

Alle weather changes gaan via:

```text
MSTR.WeatherEngine
```

## Tests

Minimaal:

```text
CLEAR → CLOUDS smooth
CLOUDS → RAIN smooth
RAIN → CLEAR smooth
CLEAR → SNOW
SNOW → CLEAR
instant weather
invalid weather
resource restart
client reconnect indien mogelijk
```

## Niet implementeren

- Dynamic Weather scheduler/graph
- Persistence
- Blackout
- NUI

## STOP

Ga niet naar Fase 3 zonder gebruiker.

---

# 17. FASE 3 — TIME ENGINE

## Doel

Server-authoritative tijd met lokale client progression.

## Implementeren

```text
canonical server time
client local calculation
manual time
time scale
freeze
resume
wrap-around
smooth correction indien nodig
resync
```

## Harde regels

- geen serverloop die iedere seconde `GlobalState` hour/minute verandert;
- geen fractionele minuten als globale state;
- client bepaalt nooit zelf de authoritative time;
- scale binnen config min/max;
- freeze boolean strict valideren.

## Commands

Wanneer development commands aanwezig zijn:

```text
/mstrtime HH:MM
/mstrtime freeze true|false
/mstrtime scale <value>
```

Ongeldige input geeft een fout en verandert niets.

## Tests

```text
normale cycle
23:59 → 00:00
18:00 → 08:00 manual
freeze true
wachten
freeze false
scale 0.5
scale 1
scale 2
scale onder minimum
scale boven maximum
invalid HH:MM
resource restart
```

## STOP

Ga niet naar Fase 4 zonder gebruiker.

---

# 18. FASE 4 — DYNAMIC WEATHER

## Doel

Automatische logische weather progression bovenop de bestaande Weather Engine.

## Implementeren

```text
weather graph
weighted transitions
interval scheduler
manual enable/disable
resume from current weather
debug/status
```

## Harde regels

- gebruik bestaande `MSTR.WeatherEngine`;
- geen tweede client weather implementation;
- geen persistence;
- geen database;
- geen NUI;
- geen blackout;
- geen nieuwe dependency.

## Scheduler

Gebruik `Config.DynamicWeather.IntervalMinutes` of een even duidelijke naam.

Scheduler moet:

- alleen draaien wanneer Dynamic Weather actief is;
- niet meerdere gelijktijdige timers maken;
- handmatige enable/disable correct verwerken;
- na handmatige weather change vanaf de nieuwe actuele state verder kunnen;
- geen transition starten wanneer een bestaande transition dat onveilig maakt.

## Weighted graph

Controleer mathematisch/logisch dat weights daadwerkelijk gebruikt worden.

## Tests

Voor development mag interval tijdelijk laag worden gezet.

Test:

```text
automatic CLEAR → volgende geldige weather
meerdere automatische cycli
dynamic false → geen automatische change
dynamic true → countdown hervat
handmatig weather + dynamic true → vervolg vanaf nieuwe weather
special weather → veilige exit
geen onlogische transition
/mstrdebug toont dynamic status/countdown
```

Na test config terugzetten naar normale waarde.

## STOP

Ga niet naar Fase 5 zonder gebruiker.

---

# 19. FASE 5 — BLACKOUT + PERSISTENCE

## Doel

Blackout en betrouwbare state persistence.

## Implementeren

```text
blackout state
client blackout application
vehicle light behavior setting
state serialization
state load
validation
defaults
corrupt JSON recovery
debounced writes
```

## Harde regels

- geen database;
- gebruik resource-local JSON;
- geen write iedere tick/minuut;
- save alleen bij relevante mutaties;
- load vóór definitieve state-initialisatie waar architectuur dit vereist;
- persisted data altijd opnieuw valideren.

## Startup sequence

Conceptueel:

```text
config defaults
↓
load saved state
↓
validate
↓
merge
↓
initialize central state
↓
replicate
```

## Tests

```text
blackout on/off
vehicle behavior true/false
resource restart
server restart
missing state.json
empty state.json
invalid JSON
invalid weather
invalid time
invalid booleans
```

## STOP

Ga niet naar Fase 6 zonder gebruiker.

---

# 20. FASE 6 — NUI

## Doel

Moderne admininterface zonder business logic te dupliceren.

## Pagina's

```text
Dashboard
Weather
Time
Logs
Settings
```

Alleen tonen wat daadwerkelijk functioneert.

Geen toekomstige lege menu-items.

## Eerst read-only

Bouw eerst:

- open/close;
- actuele serverstate tonen;
- live state updates ontvangen.

Test dit vóór controls.

## Daarna controls

Controls sturen requests naar server.

UI verandert state niet optimistisch alsof de request gegarandeerd gelukt is.

Flow:

```text
NUI
↓
client callback
↓
server request
↓
permission
↓
validation
↓
engine/service
↓
state replication
↓
NUI update
```

## STOP

Ga niet naar Fase 7 zonder gebruiker.

---

# 21. FASE 7 — BRANDING + LOGGING

## Branding

Gebruik uitsluitend `Config.Branding`.

Ondersteun:

```text
default logo
custom PNG
custom WEBP indien browser/NUI dit ondersteunt
missing logo fallback
ShowName
lange servernaam
lege servernaam fallback
```

Logo container mag layout niet breken.

Gebruik bijvoorbeeld `object-fit: contain`.

## Logging

Log minimaal:

```text
timestamp
source/type
player name indien adminactie
identifier indien nuttig
actie
oude waarde
nieuwe waarde
```

Types:

```text
ADMIN
SYSTEM
```

Bewaar een begrensd aantal entries.

Geen onbeperkte RAM-groei.

## STOP

Ga niet naar Fase 8 zonder gebruiker.

---

# 22. FASE 8 — SECURITY + PERFORMANCE AUDIT

Controleer ieder muterend event/command/export:

```text
permission?
validatie?
rate/spam risico?
client authority?
invalid payload?
duplicate implementation?
```

Controleer performance:

```text
idle
weather stable
weather transition
time progression
dynamic weather scheduler
NUI gesloten
NUI geopend
```

Optimaliseer op basis van daadwerkelijke metingen.

Geen premature micro-optimalisaties die leesbaarheid verslechteren.

---

# 23. FASE 9 — FINAL V1.0 TEST

## Eén speler

Test alle functionaliteit.

## Multiplayer

Indien beschikbaar:

- twee spelers;
- twee admins;
- simultaneous UI;
- state synchronization;
- late join.

Als multiplayer lokaal niet beschikbaar is:

markeer expliciet:

```text
RELEASE TODO:
- multiplayer synchronization verification
- late join with second real client
- concurrent admin UI verification
```

Doe niet alsof deze tests uitgevoerd zijn.

## Restart

Test:

- resource restart;
- volledige server restart;
- persistence herstel.

---

# 24. V1.0 FUNCTIONELE SCOPE

V1.0 bevat uiteindelijk:

## Weather

- handmatige weather;
- instant;
- smooth;
- Dynamic Weather;
- graph;
- weighted transitions;
- rain cleanup;
- snow cleanup;
- server/client sync.

## Time

- manual time;
- freeze/resume;
- scale;
- local progression;
- server authority;
- wrap-around;
- resync.

## Blackout

- on/off;
- vehicle effect config.

## Persistence

- state save/load;
- validation;
- corruption fallback.

## NUI

- Dashboard;
- Weather;
- Time;
- Logs;
- Settings.

## Security

- ACE;
- server-side validation;
- no client authority.

## Developer API

Minimaal read exports:

```text
GetWeather
GetTime
GetState
IsBlackout
IsTimeFrozen
```

Server-side gecontroleerde setters mogen uiteindelijk bestaan:

```text
SetWeather
SetTime
SetBlackout
SetDynamicWeather
```

Gebruik dezelfde engines/services als commands en NUI.

---

# 25. BEWUST NIET IN V1.0

Niet implementeren:

```text
Weather Timeline
Player Forecast
Weather Presets / Scenes
Weather Event Director
Storm sequences
Restart/Tsunami Event Director
Regional Weather
Weather Zones
Moving Weather Fronts
Routing Bucket Weather
Interior Override Stack
Advanced Developer Overrides
Real World Weather
Season System
Climate System
Drag & Drop Timeline
```

Architectuur mag uitbreidbaar zijn, maar geen half afgemaakte code hiervoor toevoegen.

---

# 26. CONFLICT DETECTOR

Voor V1.0 mag een eenvoudige startup-check worden toegevoegd voor bekende weather/time resources.

Alleen waarschuwen.

Niet automatisch:

- resources stoppen;
- configs aanpassen;
- files wijzigen.

Voorbeeld:

```text
[MSTR_Weather] WARNING:
qb-weathersync is running.
Running multiple weather synchronization resources may cause conflicts.
```

Houd de lijst centraal.

---

# 27. DEFINITION OF DONE — V1.0

V1.0 is pas klaar wanneer:

- resource zonder errors start;
- standalone functioneert;
- geen ongewenste dependency bevat;
- manifest correct is;
- namespace consistent is;
- weather correct synchroniseert;
- instant weather werkt;
- smooth weather werkt;
- Dynamic Weather logisch werkt;
- weighted graph werkt;
- rain cleanup werkt;
- snow cleanup werkt;
- time correct synchroniseert;
- freeze/resume werkt;
- scale werkt;
- midnight wrap werkt;
- blackout werkt;
- persistence werkt;
- NUI volledig functioneert;
- branding configureerbaar is;
- custom logo werkt;
- ACE permissions werken;
- alle muterende serverinterfaces beveiligd zijn;
- logging begrensd werkt;
- exports dezelfde services gebruiken;
- resource restart correct werkt;
- server restart correct werkt;
- bekende sync bugs zijn opgelost;
- idle performance acceptabel is;
- multiplayertests uitgevoerd zijn of expliciet als release-TODO zijn gemarkeerd.

---

# 28. VERPLICHTE SELF-REVIEW VOOR IEDERE AI-OPLEVERING

Beantwoord vóór je meldt dat een fase “voltooid” is intern deze vragen:

```text
1. Heb ik alleen de gevraagde fase gebouwd?
2. Heb ik bestanden uit een volgende fase toegevoegd?
3. Heb ik een dependency toegevoegd?
4. Heb ik het manifest veranderd? Zo ja, is elke wijziging noodzakelijk?
5. Bestaan alle paths uit het manifest?
6. Heb ik require() voor lokale resourcebestanden geïntroduceerd?
7. Gebruik ik de bestaande MSTR namespace?
8. Heb ik duplicate state of duplicate engines gemaakt?
9. Zijn alle mutaties server-authoritative?
10. Zijn permissions server-side?
11. Is input strikt gevalideerd?
12. Heb ik false/nil correct behandeld?
13. Heb ik een onnodige high-frequency loop toegevoegd?
14. Heb ik known-good code uit een vorige fase verwijderd of vervangen?
15. Heb ik daadwerkelijk getest wat ik claim getest te hebben?
16. Welke onderdelen kunnen alleen door de gebruiker in FiveM runtime worden getest?
```

Als één antwoord problematisch is:

**repareer dit vóór oplevering.**

---

# 29. RAPPORTAGEFORMAT NA IMPLEMENTATIE

Gebruik na iedere implementatie dit formaat:

```markdown
## Fase X — Implementatie afgerond

### Gewijzigde bestanden
- `...`
- `...`

### Nieuwe bestanden
- `...`

### Wat is geïmplementeerd
- ...
- ...

### Bestaande functionaliteit behouden
- ...
- ...

### Automatisch gecontroleerd
- syntax/structuur/manifest/etc.

### Ingame testen door gebruiker
1. ...
2. ...
3. ...

### Niet getest / TODO
- multiplayer indien niet beschikbaar
- ...

### Scopecontrole
- Geen functionaliteit uit Fase X+1 toegevoegd.
- Geen nieuwe dependency toegevoegd.

STOP — wacht op goedkeuring voor de volgende fase.
```

Noem een fase nooit “succesvol afgerond” wanneer de noodzakelijke runtime-tests nog niet uitgevoerd zijn.

Gebruik dan bijvoorbeeld:

```text
Implementatie afgerond — wacht op ingame validatie.
```

---

# 30. BELANGRIJKSTE ONTWIKKELREGEL

Bouw MSTR_Weather incrementeel.

Niet:

```text
iedere fase → opnieuw architectuur bedenken
```

Wel:

```text
Foundation
   ↓
Weather Engine
   ↓
Time Engine
   ↓
Dynamic Weather
   ↓
Blackout/Persistence
   ↓
NUI
   ↓
Branding/Logging
   ↓
Audit
   ↓
V1.0
```

Iedere laag bouwt voort op de vorige laag.

Wanneer een eerdere core-fout wordt ontdekt:

1. identificeer de fout;
2. repareer de kleinste noodzakelijke core-laag;
3. test regressies;
4. ga daarna verder.

Maak geen workaround naast een foutieve core.

Het eindresultaat moet één samenhangend systeem zijn, niet een verzameling losse implementaties.
