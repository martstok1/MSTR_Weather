# Fase 7 — branding en logging

Deze fase bouwt voort op de goedgekeurde Fase 6. Test eerst op een kopie en
bewaar `data/state.json`, `data/admin.json` en backups buiten de resource.

## Branding

- Controleer de standaardnaam, het standaardlogo en de fallback wanneer een
  logo ontbreekt.
- Zet in `Config.Branding` een eigen naam, `ShowName = false`, een PNG en een
  WEBP. Controleer ook een lege/lange naam en een ongeldig pad. De configuratie
  wordt gevalideerd en de layout mag niet verschuiven.
- Controleer dat branding alleen uit `Config.Branding` komt en na reconnect of
  resourceherstart opnieuw wordt geladen.

## Logging

- Voer als hoofdadmin weather, tijd, snelheid, freeze, dynamic, blackout,
  gebruikers- en serverinstellingenacties uit. Open Logs en controleer type,
  tijd, speler, identifier, actie en oude/nieuwe waarde.
- Controleer systeemregels bij resource-start, dynamic weather en het voltooien
  van een overgang.
- Open Logs als gewone admin of zonder menu-recht: de server weigert dit.
- Trek hoofdadminrechten in terwijl Logs openstaat: de regels verdwijnen en
  het menu keert terug naar het overzicht. Controleer logs in Nederlands en Engels.
- Stel `Config.Logging.MaxEntries` laag in en genereer meer acties. Controleer
  dat alleen de nieuwste regels blijven bestaan en dat oudere logs laden werkt.
- Herstart de resource: de geschiedenis mag opnieuw beginnen; `state.json` en
  `admin.json` blijven onafhankelijk behouden.
- Controleer dat namen en gewijzigde waarden als tekst worden weergegeven en
  geen HTML kunnen uitvoeren.

## Regressies

Test daarnaast menu openen/sluiten, rechten, live sync met twee spelers,
weerovergangen, tijd, persistence, taal en iconen. Noteer F8/serverconsole,
resmon en eventuele layoutproblemen. Fase 7 is geslaagd wanneer branding,
toegang en begrensde logging werken; daarna stopt de implementatie vóór Fase 8.
