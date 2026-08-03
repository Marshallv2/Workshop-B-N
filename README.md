# Kanal- & Versorgungs-Workshop – Layereigenschaften

Interaktive HTML-Webanwendung zur gemeinsamen Festlegung von AutoCAD-Layereigenschaften für Bestandskanal und Versorgungsleitungen im Zeichner-Workshop.

## Nutzung

1. `index.html` im Browser öffnen (Doppelklick oder lokaler Webserver).
2. Pro Layer einstellen: Name, Farbe, Linientyp, Linienstärke, Maßstab (1:250 / 1:500), Plotstil (**Normal** oder **vonLayer**).
3. Fortschritt mit **Speichern (Browser)** sichern – mehrere Zeichner können jeweils exportieren und im Workshop abgleichen.
4. **Excel exportieren (.xlsx)** erzeugt eine Tabelle im Format des Layereigenschaften-Managers.

## Kategorien

| Kat. | Bedeutung |
|------|-----------|
| **A** | Quellenmäßig vorhanden (XLSX/PDF) – 66 Layer |
| **B** | Aus Originalbildern sichtbar (KANPL_* – nicht normalisiert) |
| **C** | Vorgeschlagene Workshop-Struktur (Planung, Blöcke, spätere V-Leitungen) |
| **D** | Noch gemeinsam zu entscheiden (OFFEN) |

## Quellen

Daten stammen ausschließlich aus der Workshop-Vorbereitung (Layer-Manager XLSX/PDF, CAD-Bilder, Master-Prompt). Nichts gilt als endgültiger Standard ohne Workshop-Bestätigung.
