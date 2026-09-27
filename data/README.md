# Runtime-opslag

Deze map moet blijven bestaan en beschrijfbaar zijn door FXServer.

`state.json`, `state.json.bak`, `admin.json` en `admin.json.bak` worden tijdens
gebruik aangemaakt en zijn uitgesloten van Git. Lever deze bestanden niet mee
aan andere servers: beheeropslag bevat spelersidentifiers en rechten.

Stop vóór een update de resource normaal en maak buiten de resource een backup
van alle vier de bestanden. Behoud ze bij het bijwerken van de code.

## Omgeving

`state.json` bewaart weer, dynamisch weer, blackout, bevriezen, tijdsnelheid en
hele uren/minuten. Tijdens een overgang wordt het doelweer opgeslagen en na
herstart direct toegepast. Seconden, overgangsvoortgang en offline verstreken
tijd worden niet bewaard.

Bij een ontbrekende of ongeldige primary probeert de resource een geldige backup
en daarna de defaults. Writes worden gebundeld en gecontroleerd door teruglezen.
Mislukte omgevingswrites worden maximaal drie keer geprobeerd, met een melding.
Een normale stop bewaart de actuele omgeving. Een crash kan wijzigingen sinds de
laatste geslaagde write verliezen.

Om uitsluitend de omgeving te resetten: stop de resource, maak een backup en
verwijder bewust zowel `state.json` als `state.json.bak`. Alleen de primary
verwijderen kan de backup terugladen. Beheerinstellingen blijven van toepassing.

## Beheer en rechten

`admin.json` bewaart gedeelde instellingen, servertaal en gebruikersrechten,
ook wanneer omgevingsopslag uitstaat. Deze instellingen hebben voorrang op de
overeenkomstige configuratiedefaults.

Beschadigde beheeropslag, of een ontbrekende primary terwijl een backup bestaat,
blokkeert gewone toegang en beheerschrijfacties. Hoofdadmins kunnen nog kijken.
Er is geen automatische backuprestore: die kan ingetrokken rechten herstellen.
Stop de resource en herstel bewust een gecontroleerde geldige versie.

Verwijder niet zomaar beide beheerbestanden: dan gelden opnieuw defaults en
gewone ACE-rechten. Bewaar backups buiten de resource.
