<img width="1193" height="839" alt="image" src="https://github.com/user-attachments/assets/76f86406-a7ab-4981-9888-59aec1464c03" />


# MSTR_Weather

**Standalone weer- en tijdsbeheer voor FiveM · v1.0.0 · Martstok**

Beheer het weer, de tijd en blackout vanuit één menu. MSTR_Weather synchroniseert de omgeving via de server en biedt afzonderlijke rechten per beheerder, Nederlandse en Engelse menuteksten en persoonlijke menukleuren.

## Functies

- Vijftien weertypes, direct wijzigen of geleidelijk overgaan.
- Dynamisch weer met instelbaar interval en gewogen, logische vervolgstappen.
- Tijd instellen, bevriezen, hervatten en versnellen of vertragen.
- Blackout met instelbare invloed op voertuigverlichting.
- Automatisch bewaren van omgeving, beheerinstellingen en toegangsrechten.
- Hoofdadminpaneel met rechten per persoon en een gedeelde servertaal.
- Persoonlijke thema's en aanpasbare naam en logo.
- Begrensde actielog voor hoofdadmins.
- Server-side rechtencontrole, invoervalidatie en verzoeklimieten.

Geen ESX, QBCore, ox_lib, database of externe webdienst nodig. De interface wordt lokaal meegeleverd; er is geen buildstap nodig.

## Installatie

1. Download of clone deze repository.
2. Plaats de resource als `MSTR_Weather` in je resources-map. `fxmanifest.lua` moet direct in die map staan, niet in een extra submap.
3. Laat de map `data/` bestaan en zorg dat FXServer hierin kan schrijven.
4. Schakel andere weer- en tijdsynchronisatie uit, inclusief eventuele modules in admin- of frameworkresources.
5. Stel je hoofdadminrechten in zoals hieronder.
6. Voeg aan je geladen `resources.cfg` toe:

```cfg
ensure MSTR_Weather
```

Zorg dat je serverconfig `permissions.cfg` en `resources.cfg` daadwerkelijk uitvoert, met de permissies vóór het starten van de resource. Start vervolgens de server en open ingame `/mstrmenu`, of gebruik `mstrmenu` in F8.

De resource past externe configuratiebestanden niet automatisch aan.

## Toegang en hoofdadmin

Zet in je geladen `permissions.cfg`:

```cfg
add_ace identifier.fivem:JOUW_FIVEM_ID mstr.weather.superadmin allow
```

Vervang `JOUW_FIVEM_ID` door het numerieke deel van je eigen `fivem:`-identifier. Geef deze ACE alleen aan het bedoelde account. Bestaande brede ACE-regels of groepsrechten kunnen ook toegang geven.

| Toegang | Mogelijkheden |
| --- | --- |
| Geen rechten | Ontvangt de gesynchroniseerde omgeving, kan het beheermenu niet gebruiken |
| Gedelegeerde gebruiker | Alleen de aangevinkte onderdelen |
| `mstr.weather.admin` | Gewone bediening, zonder hoofdadminpaneel of logs |
| `mstr.weather.superadmin` | Alle bediening, beheerinstellingen, gebruikersrechten en logs |

Voeg als hoofdadmin via **Beheer** een online speler toe of vul handmatig een `fivem:123456`-identifier of een lowercase `license:` met 40 hextekens in. Stel per persoon de rechten in voor menu bekijken, weer, tijd, dynamisch weer en blackout.

**Menu bekijken** is vereist voor de overige gewone rechten. Een opgeslagen gebruikersregel heeft voorrang op de gewone admin-ACE. Alle vinkjes uitzetten trekt gewone toegang in. Meerdere opgeslagen identifiers van dezelfde speler worden beperkend gecombineerd.

Hoofdadminrechten worden uitsluitend via ACE toegekend, nooit via het menu. Een hoofdadmin behoudt die rechten ongeacht de gewone gebruikersvinkjes. Er kunnen maximaal 256 gebruikersregels worden opgeslagen.

## Bediening

Open met `/mstrmenu`. Sluit met Escape, de sluitknop of hetzelfde command.

| Onderdeel | Gebruik |
| --- | --- |
| Dashboard | Overzicht van de actuele omgeving |
| Weer | Weertype kiezen, overgang instellen en dynamisch weer bedienen |
| Tijd | Tijdstip, bevriezen en tijdsnelheid bedienen |
| Instellingen | Persoonlijke menukleuren aanpassen |
| Beheer | Gedeelde instellingen en gebruikersrechten; alleen hoofdadmin |
| Logs | Actiegeschiedenis; alleen hoofdadmin |

Het open menu ontvangt ongeveer elke twee seconden actuele servergegevens. De weergegeven klok is een momentopname; de spelklok loopt lokaal door op basis van de serverinstellingen.

Tijdens een geleidelijke weerovergang wordt een tweede geleidelijke wijziging geweigerd. Een directe wijziging kan de lopende overgang onderbreken, wanneer direct wijzigen is toegestaan.

Dynamisch weer kiest de volgende stap uit `Config.Weather.Transitions`. De getallen zijn relatieve kansen. Sneeuw en Halloween worden in de standaardconfiguratie niet automatisch vanuit normaal weer gekozen. Schakel dynamisch weer uit als je een handmatig gekozen weertype wilt behouden.

Ondersteunde types: `EXTRASUNNY`, `CLEAR`, `CLOUDS`, `SMOG`, `FOGGY`, `OVERCAST`, `RAIN`, `THUNDER`, `CLEARING`, `NEUTRAL`, `SNOW`, `SNOWLIGHT`, `BLIZZARD`, `XMAS` en `HALLOWEEN`.

## Configuratie

Pas de startinstellingen aan in [config.lua](config.lua) en herstart de resource.

| Configuratie | Standaard / betekenis |
| --- | --- |
| `General.Locale` | `nl`; ondersteunt `nl` en `en` |
| `General.MenuCommand` | `mstrmenu` |
| `Weather.Default` | `CLEAR` |
| `Weather.TransitionDuration` | 30 seconden |
| `Weather.AllowInstantChange` | Direct wijzigen toegestaan |
| `Weather.EnableSnowTrails` | Sneeuwsporen ingeschakeld |
| `DynamicWeather.Enabled` | Ingeschakeld |
| `DynamicWeather.IntervalMinutes` | 15 minuten |
| `Time.DefaultHour / DefaultMinute` | 12:00 |
| `Time.CycleSpeed` | 2; twee spelseconden per echte seconde |
| `Time.Frozen` | Uitgeschakeld |
| `Blackout.Default` | Uitgeschakeld |
| `Blackout.AffectVehicles` | Uitgeschakeld |
| `Persistence.Enabled` | Ingeschakeld |
| `Logging.MaxEntries` | 200; instelbaar van 10 tot 1000 |
| `Debug` | Uitgeschakeld |

**Opgeslagen gegevens hebben voorrang op startdefaults.** De hoofdadmin kan overgangsduur, direct wijzigen, dynamisch interval, sneeuwsporen, invloed op voertuigverlichting, omgevingsopslag en servertaal via **Beheer** opslaan. Deze instellingen staan in `data/admin.json`. De opgeslagen omgeving staat afzonderlijk in `data/state.json`.

Een gewijzigde overgangsduur geldt vanaf de volgende overgang. Een gewijzigd dynamisch interval begint een nieuwe aftelling. Omgevingsopslag inschakelen bewaart de actuele toestand; uitschakelen verwijdert bestaande bestanden niet.

### Taal en uitstraling

**Beheer → Servertaal** kiest Nederlands of Engels voor iedereen. Open menu's volgen de wijziging bij de volgende update. De taal is geen persoonlijke voorkeur.

Onder **Instellingen → Jouw uitstraling** kiest iedere beheerder een thema of eigen kleuren. Deze voorkeur wordt lokaal in de NUI-browser opgeslagen. Cache wissen of een andere computer gebruiken kan de voorkeur resetten.

Configureer je branding in `config.lua`:

```lua
Config.Branding = {
    Name = 'Mijn server',
    Logo = 'images/mijnlogo.png',
    ShowName = true
}
```

Plaats je PNG- of WEBP-bestand in `images/`. Gebruik een eenvoudige bestandsnaam met letters, cijfers, streepjes of underscores en een lowercase extensie. Het standaardlogo is `images/default.svg`. Een ontbrekend of ongeldig logo valt terug op het standaardlogo. Met `ShowName = false` verberg je de naam.

### Optionele commands

Alleen het menucommand staat standaard aan. Voor optionele commands vervang je `false` in `Config.General` door de bijbehorende naam:

| Configveld | Naam | Voorbeelden |
| --- | --- | --- |
| `WeatherCommand` | `mstrweather` | `/mstrweather RAIN smooth`, `/mstrweather CLEAR instant`, `/mstrweather dynamic false` |
| `TimeCommand` | `mstrtime` | `/mstrtime 18:30`, `/mstrtime freeze true`, `/mstrtime scale 2` |
| `BlackoutCommand` | `mstrblackout` | `/mstrblackout true` |
| `DebugCommand` | `mstrdebug` | Alleen actuele status lezen |

Gebruik expliciet `false` om een optioneel command uit te schakelen; een ontbrekend veld kan door configuratievalidatie worden aangevuld. Deze commands werken ingame en controleren dezelfde rechten als het menu. Zichtbare commandfeedback gebruikt `chat:addMessage` en vereist een compatibele chatresource.

Commands en menuacties delen een limiet van één verzoek per speler per 500 ms. Te snelle commands worden genegeerd. Het statuscommand heeft een afzonderlijke limiet en staat los van `Config.Debug`.

## Opslag, backups en updates

| Bestand | Inhoud |
| --- | --- |
| `data/state.json` | Weer, tijd, dynamisch weer, blackout, bevriezen en tijdsnelheid |
| `data/state.json.bak` | Vorige geldige omgevingsopslag |
| `data/admin.json` | Gedeelde beheerinstellingen en gebruikersrechten |
| `data/admin.json.bak` | Vorige beheeropslag |

Deze bestanden worden tijdens gebruik aangemaakt en horen niet in Git. Bewaar ze bij updates:

1. Stop de resource normaal.
2. Maak buiten de resource een backup van `config.lua`, eigen logo's en alle bovenstaande JSON- en backupbestanden.
3. Werk de resourcebestanden bij en neem je eigen configuratiewaarden over.
4. Behoud of herstel de runtimebestanden in `data/`.
5. Start de resource opnieuw.

Writes worden gebundeld en teruggelezen ter controle. Bij normale stop wordt de actuele omgeving opgeslagen. Een crash kan wijzigingen sinds de laatste geslaagde opslag verliezen. Seconden, overgangsvoortgang en offline verstreken tijd worden niet bewaard. Tijdens een overgang wordt het doelweer opgeslagen en na herstart direct toegepast.

Bij ongeldige omgevingsopslag probeert de resource de backup en daarna de defaults. **Voor beheerrechten is er bewust geen automatische backuprestore**: een oude backup kan ingetrokken rechten teruggeven. Beschadigde beheeropslag blokkeert gewone toegang en beheerschrijfacties. De hoofdadmin kan nog kijken. Stop de resource, controleer primary en backup en herstel bewust een geldige versie.

Verwijder `admin.json` en de backup niet zomaar: zonder beide bestanden gelden opnieuw defaults en gewone ACE-rechten. Zie ook [data/README.md](data/README.md).

## Logging

De hoofdadmin ziet ADMIN- en SYSTEM-acties met tijdstip, bron, speler/identifier waar van toepassing en oude/nieuwe waarden. Logs staan uitsluitend in het geheugen, zijn begrensd en verdwijnen bij een resource- of serverherstart. Er is geen database- of bestandsarchief voor logs.

## Problemen oplossen

| Probleem | Controle |
| --- | --- |
| Menu opent niet | Resource gestart, commandnaam correct en effectieve ACE of gebruikersrechten aanwezig |
| Beheer of Logs ontbreekt | Eigen account heeft de hoofdadmin-ACE nodig |
| Configwijziging lijkt genegeerd | Opgeslagen beheerinstellingen of omgevingsstate hebben voorrang |
| Weer of tijd springt terug | Controleer of een andere resource of dynamisch weer de omgeving wijzigt |
| Wijziging wordt geweigerd | Controleer rechten, actieve overgang, invoer en de verzoeklimiet |
| Opslagmelding of vergrendeld beheer | Controleer serverconsole, schrijfrechten en JSON-bestanden; volg de hersteluitleg hierboven |
| Logo verschijnt niet | Controleer bestandspad, naam, extensie en of het bestand is meegeleverd |

Gebruik voor ondersteuning de F8- en servermeldingen, resourceversie en concrete stappen om het probleem te herhalen. Deel geen spelersidentifiers of beheerbestanden openbaar.

## Versiestatus

Versie **1.0.0** is op verzoek van de eigenaar als eindversie afgerond na goedgekeurde ingame controles tot en met Fase 8. Eerder is synchronisatie met een tweede speler bevestigd.

**Release-TODO:** de volledige multiplayer-eindcontrole op deze eindversie is uitgesteld: synchronisatie met twee echte clients, late join tijdens een overgang en gelijktijdige bediening door twee admins. Deze controles zijn niet als geslaagd aangemerkt. Er wordt geen vaste CPU- of resmonwaarde gegarandeerd.

De ontwikkeltests en fase-documentatie zijn uit de productversie verwijderd; eerdere versies blijven beschikbaar in de Git-geschiedenis. Deze versie biedt geen publieke developer-exports, zones, afzonderlijk weer per routing bucket of real-world weather.

## Auteur

**Martstok** · MSTR_Weather

Copyright © 2026 Martstok. Alle rechten voorbehouden.
