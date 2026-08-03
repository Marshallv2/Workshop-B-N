# assets/

Hier liegen die Originaldateien. Solange eine Datei fehlt, zeigt das Dokument an ihrer Stelle
einen Platzhalter mit dem erwarteten Dateinamen an – der übrige Inhalt bleibt vollständig nutzbar.

## Abbildungen

Die Originalbilder heißen in der Quelle `image(108).png` bis `image(129).png`. Weil Klammern in
URLs kodiert werden müssen, erwartet das Dokument sie ohne Klammern:

| Quelle | Dateiname hier | Abschnitt im Dokument |
| --- | --- | --- |
| `image(108).png` | `image-108.png` | 6 – Originalbilder |
| `image(109).png` | `image-109.png` | 6 – Originalbilder |
| `image(110).png` | `image-110.png` | 6 – Originalbilder |
| `image(111).png` | `image-111.png` | 6 – Originalbilder |
| `image(112).png` | `image-112.png` | 6 – Originalbilder |
| `image(113).png` | `image-113.png` | 6 – Originalbilder |
| `image(114).png` | `image-114.png` | 6 – Originalbilder |
| `image(115).png` | `image-115.png` | 6 – Originalbilder |
| `image(116).png` | `image-116.png` | 6 – Originalbilder |
| `image(117).png` | `image-117.png` | 6 – Originalbilder |
| `image(125).png` | `image-125.png` | 13 – Linientypkatalog |
| `image(126).png` | `image-126.png` | 13 – Linientypkatalog |
| `image(127).png` | `image-127.png` | 13 – Linientypkatalog |
| `image(128).png` | `image-128.png` | 14 – Farbenkatalog |
| `image(129).png` | `image-129.png` | 14 – Farbenkatalog |

Zusätzlich erwartet Abschnitt 6 die erzeugte Übersichtsgrafik als `uebersicht-kanalstandard.png`.

Umbenennen unter Linux oder macOS:

```bash
cd assets
for f in image\(*\).png; do n="${f#image(}"; mv "$f" "image-${n%).png}.png"; done
```

Unter Windows in PowerShell:

```powershell
Get-ChildItem assets\image`(*`).png | Rename-Item -NewName { $_.Name -replace '\((\d+)\)', '-$1' }
```

## Anhänge

| Dateiname | Inhalt |
| --- | --- |
| `Kanal_Layereigenschaften_Layer-Manager.xlsx` | maßgebliche Quelle der 66 Layerdatensätze |
| `Kanal_Layereigenschaften_Layer-Manager.pdf` | Druckfassung derselben Layerliste |
| `DIN_1356-1_2018.pdf` | nur ergänzende Orientierung, im Uploadsatz bisher nicht enthalten |

Weitere Dateien dürfen hier liegen; `tools/build-standalone.mjs` bettet alle bekannten Dateitypen
in die Einzeldatei ein.
