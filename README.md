# Workshop-B-N – Kanalstandard

Arbeitsgrundlage für die schrittweise Verfestigung eines gemeinsamen CAD-/Zeichnerstandards.
Das Dokument nimmt die bereitgestellten Quellen vollständig auf, gliedert sie nach Objekten und
Modulen und kennzeichnet alle noch offenen Entscheidungen. Es ist ausdrücklich **kein fertiger
Standard**, sondern die Entscheidungsgrundlage für den ersten 20–30-Minuten-Termin und die
Folgetermine.

## Öffnen

`index.html` im Browser öffnen – ohne Server, ohne Build, ohne Abhängigkeiten. Fehlende
Abbildungen erscheinen als Platzhalter mit dem erwarteten Dateinamen.

Für Weitergabe per Mail oder Teams eine Einzeldatei mit eingebetteten Bildern und Anhängen bauen:

```bash
node tools/build-standalone.mjs   # erzeugt dist/kanalstandard.html
```

## Aufbau

```
index.html                  Struktur und Prosaabschnitte
src/styles.css              Design-Tokens, Hell-/Dunkelmodus, Druckstil
src/data.js                 alle aufgenommenen Quelldaten
src/app.js                  Rendering, Filter, Beschlussliste, Import
assets/                     Originalbilder und Anhänge (siehe assets/README.md)
tools/build-standalone.mjs  erzeugt die selbsttragende Einzeldatei
```

Inhaltliche Änderungen gehören ausschließlich in `src/data.js`; `index.html` enthält nur Struktur
und die Abschnitte, die reinen Fließtext tragen.

## Abschnitte

| Nr. | Abschnitt | Inhalt |
| --- | --- | --- |
| 1 | Dokumentstatus und Quellenpriorität | Abgrenzung, Kennzahlen, Anhänge |
| 2 | Information #1 – Originalkontext | unveränderte Nachricht, abgeleitete Anforderungen |
| 3 | Zielbild | Module 1–4 |
| 4 | Erster Termin | 20–30-Minuten-Ablauf |
| 5 | Kanalarten | Haupt-, Sonder- und Ergänzungsformen |
| 6 | Information #2 | 10 Originalabbildungen und Übersichtsgrafik |
| 7 | Information #3 | Bestandslayer BKAN, objektbezogen gegliedert und filterbar |
| 8 | Kanalplanung | KANPL-Layer, visuell abgelesen |
| 9 | Information #5 | Schachtfähnchen und Blocknamen |
| 10 | V-Leitungen | BVER-Layer für spätere Termine |
| 11 | 1:250 / 1:500 | Maßstabsmatrix, im Termin ausfüllbar |
| 12 | Layer-Manager | alle 66 Datensätze, filterbar |
| 13 | Linientypkatalog | Gruppen, aufgenommene Einträge, Screenshots |
| 14 | Farbenkatalog | aktuell dokumentierter Farbwert magenta |
| 15 | Prüfpunkte | Auffälligkeiten ohne eigenmächtige Korrektur |
| 16 | Information #4 | Rolle der DIN 1356-1 |
| 17 | Beschlussliste | alle offenen Punkte mit Status und Notiz |
| 18 | Master-Prompt | wiederverwendbarer Arbeitsauftrag |

## Arbeitsprinzipien

Diese Regeln gelten für jede Ergänzung des Dokuments:

- **Quellenpriorität bei Abweichungen:** Originalbilder, dann XLSX/PDF, dann die erzeugte
  Übersichtsgrafik.
- **Nichts erfinden.** Noch nicht festgelegte Schriftgrößen, Farben oder Darstellungsregeln bleiben
  leer und werden als offen gekennzeichnet.
- **Schreibweisen nicht stillschweigend bereinigen.** Uneinheitliche Layer- und Linientypnamen
  (`LINIE`/`Linie`/`LINE`, `SCHACHTBAUW`/`SCHACHTBAUWERK`, `CONTINIOUS`/`Continuous`) sind selbst
  ein Workshop-Thema und stehen in Abschnitt 15 als Prüfpunkte.
- **DIN 1356-1 nur ergänzend.** Keine Norminhalte behaupten, solange die Datei nicht vorliegt.

## Noch zu übernehmende Quelldaten

Zwei Datenbereiche sind bewusst leer statt geraten. Beide lassen sich direkt im Dokument
einfügen, ohne Code zu bearbeiten:

1. **Eigenschaftswerte der 66 Layer** (Farbe, Linientyp, Linienstärke, Transparenz, Plotstil …).
   Abschnitt 12, „Eigenschaftswerte aus der XLSX einfügen“: Zeilen in Excel kopieren, einfügen,
   übernehmen. Der Stand bleibt lokal im Browser gespeichert.
2. **Vollständige Namensliste der 87 Linientypen.** Abschnitt 13, „Vollständige Linientypliste
   einfügen“. Bisher namentlich gesichert sind nur die Einträge, die in den Quellen ausdrücklich
   lesbar waren.

Beide Importe bieten „Als data.js-Block kopieren“ an. Damit lässt sich der eingefügte Stand
dauerhaft in `src/data.js` übernehmen, sodass er für alle Beteiligten gilt und nicht nur im
eigenen Browser.

## Termin-Werkzeuge

- **Maßstabsmatrix** (Abschnitt 11): Schriftgrößen für 1:250 und 1:500 direkt eintragen; Export als
  Markdown-Tabelle.
- **Beschlussliste** (Abschnitt 17): je Punkt Status `offen` / `in Klärung` / `entschieden` plus
  Notiz; Export als Markdown-Protokoll oder Download als `.md`.
- **Master-Prompt** (Abschnitt 18): entweder unverändert kopieren oder mit dem aktuellen
  Beschlussstand, um im nächsten Arbeitsschritt lückenlos anzusetzen.
- **Drucken**: eigener Druckstil, klappt alle Gruppen auf und setzt Tabellen auf weißen Grund.

Eingaben liegen im `localStorage` des jeweiligen Browsers (Schlüssel `kanalstandard.v1`). Für
verbindliche Ergebnisse das Protokoll exportieren und bestätigte Festlegungen in `src/data.js`
übernehmen.
