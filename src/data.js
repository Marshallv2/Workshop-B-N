/*
 * Kanalstandard – aufgenommene Quelldaten
 * ---------------------------------------
 * Quellenpriorität bei Abweichungen:
 *   1. Originalbilder (image-108 … image-129)
 *   2. Kanal_Layereigenschaften_Layer-Manager.xlsx / .pdf
 *   3. erzeugte Übersichtsgrafik
 *
 * Grundregel: Hier wird nur aufgenommen, was in den Quellen belegt ist.
 * Noch nicht festgelegte Werte bleiben leer und werden im Dokument als OFFEN
 * gekennzeichnet – sie werden nicht erfunden und Schreibweisen werden nicht
 * stillschweigend normalisiert.
 */

/* global window */
(function (root) {
  'use strict';

  /* ------------------------------------------------------------------ *
   * Information #1 – Originalkontext (unverändert bewahrt)
   * ------------------------------------------------------------------ */

  const ORIGINAL_MESSAGE = [
    'ja ok, dann pass mal auf. ich möchte ja immer noch mit euch Zeichnern den Standard verfestigen und als erste würde ich mir den Kanal vornehmen. Zu allerest den Bestandskanal. ich würde gerne sowas haben wie: Was für Kanäle gibt es (RW;SW;MW und vlt noch was wie Druckleitugnen). dann als nächstes würde ich gerne die Layer definieren für jedes Objekt, dann die Texte und die Schriftgröße.. und das einmal für 1:250 und 1:500',
    'wenn du möchtest kannst du nur dafür mal eine Struktur entwickeln, im besten Fall soll der Termin nicht über 20 bis 30min gehen. und beim nächsten mal gucken wir uns das gleich nur für die Kanalplanung an und dann am nächsten Termin die V-Leitungen und so erstellen wir gemeinsam eine DWG, die dann nach einem halben Jahr fertig ist'
  ];

  const WORK_REQUIREMENTS = [
    'Gemeinsamen Zeichnerstandard verfestigen.',
    'Mit dem Kanal beginnen, zuerst ausschließlich mit dem Bestandskanal.',
    'Kanalarten festlegen: RW, SW, MW und weitere vorhandene Formen wie Druckleitungen.',
    'Layer für jedes Objekt definieren.',
    'Textinhalte und Schriftgrößen definieren.',
    'Festlegungen getrennt für 1:250 und 1:500 treffen.',
    'Ersten Termin auf ungefähr 20 bis 30 Minuten begrenzen.',
    'Kanalplanung in einem eigenen Folgetermin behandeln.',
    'V-Leitungen/Versorgung in einem weiteren Termin behandeln.',
    'Schrittweise eine gemeinsame DWG aufbauen, die nach ungefähr einem halben Jahr fertig ist.'
  ];

  /* ------------------------------------------------------------------ *
   * Zielbild – Module und Terminstruktur
   * ------------------------------------------------------------------ */

  const MODULES = [
    {
      nr: 1,
      title: 'Bestandskanal',
      text: 'Kanalarten, Objektgruppen, Layer, Darstellungslogik, Textinhalte und Schriftgrößen für 1:250 und 1:500.'
    },
    {
      nr: 2,
      title: 'Kanalplanung',
      text: 'Dieselbe Struktur erneut für Planungslayer und Planungsblöcke; nicht mit dem ersten Termin vermischen.'
    },
    {
      nr: 3,
      title: 'Versorgungsleitungen',
      text: 'V-Leitungen und weitere BVER-Familien anhand der bereits vorhandenen Layer und Bilder.'
    },
    {
      nr: 4,
      title: 'Gemeinsame Standard-DWG',
      text: 'Bestätigte Layer, Blöcke, Texte und Darstellungsregeln schrittweise übernehmen, testen, pflegen und vereinheitlichen.'
    }
  ];

  const AGENDA = [
    {
      time: '0–3',
      title: 'Ziel und Abgrenzung',
      text: 'Heute nur Bestandskanal. Planung und Versorgung werden geparkt.'
    },
    {
      time: '3–8',
      title: 'Kanalarten bestätigen',
      text: 'RW, SW, MW, Drainage, Druck-, Saug- und Pumpleitung, Anschluss-/Hausanschluss.'
    },
    {
      time: '8–17',
      title: 'Objekte und Layer zuordnen',
      text: 'Kanalachse/Haltung, Rohrwandung, Schachtbauwerk, Schachtnummer, Stutzen, KD/KS, Deckel-/Sohltext, Haltungstext.'
    },
    {
      time: '17–23',
      title: 'Textinhalte definieren',
      text: 'Welche Pflichtangaben gehören an Haltung und Schacht? Reihenfolge, Abkürzungen und „vorh.“-Kennzeichnung festlegen.'
    },
    {
      time: '23–28',
      title: '1:250 und 1:500',
      text: 'Schriftgrößen und gegebenenfalls Detailgrad je Maßstab als Entscheidungsmatrix bearbeiten.'
    },
    {
      time: '28–30',
      title: 'Beschlüsse und offene Punkte',
      text: 'Bestätigte Punkte protokollieren; Restfragen für den nächsten Kanal-Termin sammeln.'
    }
  ];

  /* ------------------------------------------------------------------ *
   * Kanalarten und Darstellungsfamilien
   * ------------------------------------------------------------------ */

  const CHANNEL_TYPES_MAIN = [
    { name: 'RW / Regenwasser', text: 'in Layernamen und Bildern mit Kennung R.' },
    { name: 'SW / Schmutzwasser', text: 'mit Kennung S.' },
    { name: 'MW / Mischwasser', text: 'mit Kennung M.' },
    { name: 'Drainage', text: 'eigene Layer- und Darstellungsfamilie.' }
  ];

  const CHANNEL_TYPES_SPECIAL = [
    'Druckleitung – allgemein sowie differenziert nach R/M/S.',
    'Saugleitung.',
    'Pumpleitung.',
    'Anschlussleitung.',
    'Hausanschluss.',
    'Rohrwandungsdarstellung als alternative/ergänzende Kanalgeometrie.'
  ];

  /* ------------------------------------------------------------------ *
   * Information #2 – Originalbilder
   * ------------------------------------------------------------------ */

  const FIGURES = [
    {
      id: 108,
      file: 'image-108.png',
      source: 'image(108).png',
      section: 'kanal',
      title: 'Linien, Druckleitungen und Anschluss-/Versorgungsbeispiele',
      text: 'Zeigt Standard- und differenzierte Druckleitungsdarstellungen für Bestand und Planung (allgemein sowie nach M/S/R), außerdem Leerrohr, Kabelkanal-Schutzrohr, Beleuchtungskabel mit Schutzrohr und die BKAN-Anschlussleitung.'
    },
    {
      id: 109,
      file: 'image-109.png',
      source: 'image(109).png',
      section: 'kanal',
      title: 'Versorgungsleitungen – Hauptgruppen',
      text: 'Zeigt Lichtwellenleiter, Fernmeldekabel, Gas, Gashochdruckleitung, Hoch-, Mittel- und Niederspannung, Korrosionsschutz, Signalkabel, Steuerkabel, Trinkwasser und AUSA.'
    },
    {
      id: 110,
      file: 'image-110.png',
      source: 'image(110).png',
      section: 'kanal',
      title: 'Weitere Versorgungsleitungen',
      text: 'Zeigt Rohrpost, Breitband, Telekom, Fernwärme-Vorlauf, Fernwärme-Rücklauf und erneut eine BKAN-Anschlussleitung als Darstellungsbeispiel.'
    },
    {
      id: 111,
      file: 'image-111.png',
      source: 'image(111).png',
      section: 'kanal',
      title: 'Bestandskanal – Gesamtübersicht',
      text: 'Zeigt Bestandsdarstellungen für Drainage, Regenwasser, Mischwasser und Schmutzwasser; jeweils als Haltung und – soweit dargestellt – als Rohrwandung. Sichtbar sind Kanalachse, Haltungstext, Schachtnummer, KD/KS-Fähnchen, Deckel-/Sohltext, Schachtbauwerk und Rohrwandung.'
    },
    {
      id: 112,
      file: 'image-112.png',
      source: 'image(112).png',
      section: 'kanal',
      title: 'Kanalplanung – Gesamtübersicht',
      text: 'Zeigt entsprechende Planungsdarstellungen für Drainage, Regenwasser, Mischwasser und Schmutzwasser mit KANPL-Layerbezeichnungen, Schachtnummern, KD/KS-Fähnchen, Deckel-/Sohltexten, Schachtbauwerken und Rohrwandungen.'
    },
    {
      id: 113,
      file: 'image-113.png',
      source: 'image(113).png',
      section: 'kanal',
      title: 'Saug- und Pumpleitungen',
      text: 'Vergleicht Bestand und Planung für Saugleitung und Pumpleitung. Sichtbar sind Beispielbeschriftungen mit Höhen, Gefälle, Nennweite, Länge und Fließ-/Richtungspfeilen.'
    },
    {
      id: 114,
      file: 'image-114.png',
      source: 'image(114).png',
      section: 'kanal',
      title: 'KD/KS-Fähnchen und Pfeilblöcke',
      text: 'Zeigt mehrere Farb-/Darstellungsvarianten der KD-/KS-Beschriftung mit ovaler Nummer sowie verschiedene Pfeilblöcke für Bestand und Planung.'
    },
    {
      id: 115,
      file: 'image-115.png',
      source: 'image(115).png',
      section: 'kanal',
      title: 'Blöcke für Befehle',
      text: 'Zusammenstellung der wiederverwendbaren KD-/KS-/Nummern- und Pfeilblöcke als Grundlage für Befehle, Automatisierung und eine gemeinsame Standard-DWG.'
    },
    {
      id: 116,
      file: 'image-116.png',
      source: 'image(116).png',
      section: 'kanal',
      title: 'Detailansicht Schachtfähnchen – Bestand',
      text: 'Vergrößerte Bestandsdarstellung eines Regenwasserkanals mit Kanalachse, Haltung, Rohrwandung, Schachtbauwerk, Schachtnummer, KD/KS und Deckel-/Sohltext.'
    },
    {
      id: 117,
      file: 'image-117.png',
      source: 'image(117).png',
      section: 'kanal',
      title: 'Detailansicht Schachtfähnchen – Planung',
      text: 'Vergrößerte Planungsdarstellung eines Regenwasserkanals mit KANPL-Layern, Haltung, Schachtbauwerk, Schachtnummer, KD/KS und Deckel-/Sohltext.'
    },
    {
      id: 125,
      file: 'image-125.png',
      source: 'image(125).png',
      section: 'linientypen',
      title: 'Linientyp-Manager – oberer Bereich',
      text: 'AutoCAD-Linientyp-Manager mit den vorhandenen ENTW- und GP-Linientypen sowie den zugehörigen Darstellungen und Beschreibungen.'
    },
    {
      id: 126,
      file: 'image-126.png',
      source: 'image(126).png',
      section: 'linientypen',
      title: 'Linientyp-Manager – mittlerer Bereich',
      text: 'Fortsetzung der Linientypliste mit Höhenlinien, Kanalanschluss, LEV-, MARK-, Schutz- und VERS-Linientypen.'
    },
    {
      id: 127,
      file: 'image-127.png',
      source: 'image(127).png',
      section: 'linientypen',
      title: 'Linientyp-Manager – unterer Bereich',
      text: 'Unterer Abschluss der Liste mit VERS_TELEKOM_M500, Trinkwasser, vorhandener Druckleitung und Zaun-Linientypen.'
    },
    {
      id: 128,
      file: 'image-128.png',
      source: 'image(128).png',
      section: 'farben',
      title: 'Farbauswahl – AutoCAD-Farbindex',
      text: 'Im Register „Indexfarbe“ ist die Farbe magenta ausgewählt. Die Abbildung dokumentiert die AutoCAD-Farbindex-Palette und die sichtbare Farbbezeichnung.'
    },
    {
      id: 129,
      file: 'image-129.png',
      source: 'image(129).png',
      section: 'farben',
      title: 'Farbauswahl – True Color',
      text: 'True-Color-Definition der ausgewählten Farbe: RGB 255, 0, 255; HSL-Farbton 300, Sättigung 100, Helligkeit 50.'
    }
  ];

  const OVERVIEW_FIGURE = {
    file: 'uebersicht-kanalstandard.png',
    title: 'Erzeugte visuelle Übersicht',
    text: 'Diese Abbildung fasst die Themen grafisch zusammen und darf als Einstieg oder Titelgrafik verwendet werden. Wegen der automatischen Bildgenerierung ist sie nicht die maßgebliche Quelle für exakte Layernamen oder Schreibweise.',
    priority: 'Priorität bei Abweichungen: Originalbilder → XLSX/PDF → diese Übersicht.'
  };

  /* ------------------------------------------------------------------ *
   * Information #3 – Layerstruktur Bestandskanal (objektbezogen)
   * ------------------------------------------------------------------ */

  const BKAN_GROUPS = [
    {
      title: 'Anschluss / Hausanschluss',
      layers: ['BKAN_ANSCHLUSSLEITUNG', 'BKAN_HAUSANSCHL']
    },
    {
      title: 'Druck-, Saug- und Pumpleitungen',
      layers: [
        'BKAN_DRUCKLEITUNG',
        'BKAN_DRUCKLEITUNG_M',
        'BKAN_DRUCKLEITUNG_R',
        'BKAN_DRUCKLEITUNG_S',
        'BKAN_LINIE_PUMPLEITUNG_KAN',
        'BKAN_LINIE_SAUGLEITUNG_KAN',
        'BKAN_TEXT_DRUCKLEITUNG_M',
        'BKAN_TEXT_DRUCKLEITUNG_R',
        'BKAN_TEXT_DRUCKLEITUNG_S',
        'BKAN_TEXT_HALTUNG_PUMPLEITUNG_KAN',
        'BKAN_TEXT_HALTUNG_SAUGLEITUNG_KAN'
      ]
    },
    {
      title: 'Kanalachsen und Haltungen',
      layers: [
        'BKAN_KANALACHSE',
        'BKAN_LINIE_DRAINAGE_KANAL',
        'BKAN_LINIE_M_Haltung',
        'BKAN_LINIE_PUMPLEITUNG_KAN',
        'BKAN_LINIE_R_KANAL',
        'BKAN_LINIE_S_Haltung',
        'BKAN_LINIE_SAUGLEITUNG_KAN'
      ]
    },
    {
      title: 'Rohrwandungen',
      layers: ['BKAN_ROHRWANDUNG_M_KAN', 'BKAN_ROHRWANDUNG_R_KAN', 'BKAN_ROHRWANDUNG_S_KAN']
    },
    {
      title: 'Schachtbauwerke',
      layers: [
        'BKAN_SCHACHTBAUW_DRAINAGE_KAN',
        'BKAN_SCHACHTBAUW_M_KAN',
        'BKAN_SCHACHTBAUW_R_KAN',
        'BKAN_SCHACHTBAUW_S_KAN'
      ]
    },
    {
      title: 'Schachtnummern',
      layers: [
        'BKAN_SCHACHTNR_DRAINAGE',
        'BKAN_SCHACHTNR_M_KAN',
        'BKAN_SCHACHTNR_R_KAN',
        'BKAN_SCHACHTNR_S_KAN'
      ]
    },
    {
      title: 'Stutzen',
      layers: [
        'BKAN_STUTZEN_DRAINAGE',
        'BKAN_STUTZEN_M_KANAL',
        'BKAN_STUTZEN_R_KANAL',
        'BKAN_STUTZEN_S_KANAL'
      ]
    },
    {
      title: 'Deckel-/Sohltexte',
      layers: [
        'BKAN_TEXT_DECK_SOHLE_DRAINAGE',
        'BKAN_TEXT_DECK_SOHLE_M_KAN',
        'BKAN_TEXT_DECK_SOHLE_R_KAN',
        'BKAN_TEXT_DECK_SOHLE_S_KAN'
      ]
    },
    {
      title: 'Haltungstexte',
      layers: [
        'BKAN_TEXT_HALTUNG_DRAINAGE',
        'BKAN_TEXT_HALTUNG_M_KAN',
        'BKAN_TEXT_HALTUNG_PUMPLEITUNG_KAN',
        'BKAN_TEXT_HALTUNG_R_KAN',
        'BKAN_TEXT_HALTUNG_S_KAN',
        'BKAN_TEXT_HALTUNG_SAUGLEITUNG_KAN'
      ]
    },
    {
      title: 'Sonderfall Stauziel/WSP',
      layers: ['BKAN_STAUZIEL_WSP']
    }
  ];

  /* ------------------------------------------------------------------ *
   * Kanalplanung – visuell aus den Originalbildern abgelesen
   * (nicht Bestandteil der XLSX; Schreibweisen bewusst unverändert)
   * ------------------------------------------------------------------ */

  const KANPL_LAYERS = [
    'KANPL_KANALACHSE_DRAINAGE',
    'KANPL_LINE_DRAINAGE_KANAL',
    'KANPL_SCHACHTNR_DRAINAGE',
    'KANPL_TEXT_DECK_SOHLE_DRAINAGE',
    'KANPL_SCHACHTBAUWERK_DRAINAGE',
    'KANPL_KANALACHSE_R',
    'KANPL_Linie_R_KANAL',
    'KANPL_ROHRWANDUNG_R',
    'KANPL_SCHACHTNR_R',
    'KANPL_TEXT_DECK_SOHLE_R',
    'KANPL_SCHACHTBAUWERK_R',
    'KANPL_KANALACHSE_M',
    'KANPL_LINIE_M_KANAL',
    'KANPL_ROHRWANDUNG_M',
    'KANPL_SCHACHTNR_M',
    'KANPL_TEXT_DECK_SOHLE_M',
    'KANPL_SCHACHTBAUWERK_M',
    'KANPL_KANALACHSE_S',
    'KANPL_LINIE_S_KANAL',
    'KANPL_ROHRWANDUNG_S',
    'KANPL_SCHACHTNR_S',
    'KANPL_TEXT_DECK_SOHLE_S',
    'KANPL_SCHACHTBAUWERK_S',
    'KANPL_DRUCKLEITUNG',
    'KANPL_DRUCKLEITUNG_M',
    'KANPL_DRUCKLEITUNG_S',
    'KANPL_DRUCKLEITUNG_R',
    'KANPL_LINIE_SAUGLEITUNG_KAN',
    'KANPL_LINIE_PUMPLEITUNG_KAN'
  ];

  /* ------------------------------------------------------------------ *
   * Information #5 – Schachtfähnchen und Blocknamen
   * ------------------------------------------------------------------ */

  const BLOCKS = {
    planung: ['PFahneMisch', 'PFahneRegen', 'PFahneSchmutz', 'PfeilBlock'],
    bestand: ['BFahneMisch', 'BFahneRegen', 'BFahneSchmutz']
  };

  const BLOCK_PARTS = [
    'Schachtnummer als Kreis, z. B. R100, M100, S100 oder D100.',
    'Ovale Höhen-/Nummernangabe, im Beispiel „1000“.',
    'Getrennte Zeilen/Felder für KD und KS.',
    'Hinweislinien bzw. Fahnenlinien zum Schacht.',
    'Pfeilblöcke in verschiedenen Farben für Bestand/Planung und Richtungsangaben.',
    'Zuordnung zu Kanalachse, Schachtbauwerk und Deckel-/Sohltext.'
  ];

  /* ------------------------------------------------------------------ *
   * Spätere Termine – Versorgungsleitungen / V-Leitungen
   * ------------------------------------------------------------------ */

  const BVER_LAYERS = [
    'BVER_',
    'BVER_AUSA',
    'BVER_BELEUCHTUNGKABEL',
    'BVER_BELEUCHTUNGSKABEL_SCHUTZR',
    'BVER_BREITBAND',
    'BVER_FERNMELDEKABEL',
    'BVER_FERNWÄRME-RÜCK',
    'BVER_FERNWÄRME-VOR',
    'BVER_GAS',
    'BVER_GASHOCHDRUCKLEITUNG',
    'BVER_HOCHSPANNUNG',
    'BVER_KABELKAN_SCHUTZR',
    'BVER_KORROSIONSSCHUTZ',
    'BVER_LEERROHR',
    'BVER_LICHTWELLENLEITER',
    'BVER_MITTELSPANNUNG',
    'BVER_NIEDERSPANNUNG',
    'BVER_ROHRPOST',
    'BVER_SIGNALKABEL',
    'BVER_STEUERKABEL',
    'BVER_TELEKOM',
    'BVER_TRINKWASSER'
  ];

  /* ------------------------------------------------------------------ *
   * Texte, Inhalte und Schriftgrößen für 1:250 / 1:500
   * ------------------------------------------------------------------ */

  const SCALE_MATRIX = [
    {
      key: 'kanalachse',
      subject: 'Kanalachse',
      content: 'Achsen-/Leitungsgeometrie; teilweise mit Gefällerichtung'
    },
    {
      key: 'haltungstext',
      subject: 'Haltungsbeschriftung',
      content: 'DN, Material/Art, „vorh.“ bzw. Planung, Neigung in ‰; teils Länge/Höhe'
    },
    {
      key: 'schachtnummer',
      subject: 'Schachtnummer',
      content: 'R/M/S/D + Nummer in Kreis'
    },
    {
      key: 'kdks',
      subject: 'KD / KS',
      content: 'Kanaldeckel- und Kanalsohlenhöhe am Fähnchen'
    },
    {
      key: 'deckelsohltext',
      subject: 'Deckel-/Sohltext',
      content: 'Fahnen-/Hinweistext mit KD/KS und Nummern-/Höhenblock'
    },
    {
      key: 'druckleitung',
      subject: 'Druckleitung',
      content: 'Leitungsart, ggf. R/M/S, Pfeilsignatur/Richtung'
    },
    {
      key: 'saugpump',
      subject: 'Saug-/Pumpleitung',
      content: 'Höhe, Gefälle/Richtung, DN und ggf. Leitungslänge'
    },
    {
      key: 'sondertexte',
      subject: 'Sondertexte',
      content: 'Stauziel/WSP, Hinweise, Bestands-/Planungszusätze'
    }
  ];

  /* ------------------------------------------------------------------ *
   * Vollständiger Layer-Manager – 66 Datensätze aus der XLSX
   *
   * Reihenfolge und Schreibweise entsprechen der Quelldatei.
   * Die Eigenschaftsspalten (Ein, Frieren, Sperre, Plot, Farbe, Linientyp,
   * Linienstärke, Beschreibung, Transparenz, Frieren in neuen Ansichtsfenstern,
   * Plotstil) sind noch nicht zeilengetreu übernommen. Sie lassen sich über die
   * Zwischenablage aus der XLSX einfügen (Abschnitt 12, „Quelldaten einfügen“)
   * oder hier dauerhaft als props-Objekt hinterlegen:
   *
   *   { name: 'BKAN_KANALACHSE', props: { Farbe: '…', Linientyp: '…' } }
   * ------------------------------------------------------------------ */

  const LAYER_COLUMNS = [
    'Ein',
    'Frieren',
    'Sperre',
    'Plot',
    'Farbe',
    'Linientyp',
    'Linienstärke',
    'Beschreibung',
    'Transparenz',
    'Frieren in neuen Ansichtsfenstern',
    'Plotstil'
  ];

  const LAYER_MANAGER = [
    'BKAN_ANSCHLUSSLEITUNG',
    'BKAN_DRUCKLEITUNG',
    'BKAN_DRUCKLEITUNG_M',
    'BKAN_DRUCKLEITUNG_R',
    'BKAN_DRUCKLEITUNG_S',
    'BKAN_HAUSANSCHL',
    'BKAN_KANALACHSE',
    'BKAN_LINIE_DRAINAGE_KANAL',
    'BKAN_LINIE_M_Haltung',
    'BKAN_LINIE_PUMPLEITUNG_KAN',
    'BKAN_LINIE_R_KANAL',
    'BKAN_LINIE_S_Haltung',
    'BKAN_LINIE_SAUGLEITUNG_KAN',
    'BKAN_ROHRWANDUNG_M_KAN',
    'BKAN_ROHRWANDUNG_R_KAN',
    'BKAN_ROHRWANDUNG_S_KAN',
    'BKAN_SCHACHTBAUW_DRAINAGE_KAN',
    'BKAN_SCHACHTBAUW_M_KAN',
    'BKAN_SCHACHTBAUW_R_KAN',
    'BKAN_SCHACHTBAUW_S_KAN',
    'BKAN_SCHACHTNR_DRAINAGE',
    'BKAN_SCHACHTNR_M_KAN',
    'BKAN_SCHACHTNR_R_KAN',
    'BKAN_SCHACHTNR_S_KAN',
    'BKAN_STAUZIEL_WSP',
    'BKAN_STUTZEN_DRAINAGE',
    'BKAN_STUTZEN_M_KANAL',
    'BKAN_STUTZEN_R_KANAL',
    'BKAN_STUTZEN_S_KANAL',
    'BKAN_TEXT_DECK_SOHLE_DRAINAGE',
    'BKAN_TEXT_DECK_SOHLE_M_KAN',
    'BKAN_TEXT_DECK_SOHLE_R_KAN',
    'BKAN_TEXT_DECK_SOHLE_S_KAN',
    'BKAN_TEXT_DRUCKLEITUNG_M',
    'BKAN_TEXT_DRUCKLEITUNG_R',
    'BKAN_TEXT_DRUCKLEITUNG_S',
    'BKAN_TEXT_HALTUNG_DRAINAGE',
    'BKAN_TEXT_HALTUNG_M_KAN',
    'BKAN_TEXT_HALTUNG_PUMPLEITUNG_KAN',
    'BKAN_TEXT_HALTUNG_R_KAN',
    'BKAN_TEXT_HALTUNG_S_KAN',
    'BKAN_TEXT_HALTUNG_SAUGLEITUNG_KAN',
    'BKAT_GEBÄUDE',
    'BLAL_GEBAEUDE_TRAFO',
    'BVER_',
    'BVER_AUSA',
    'BVER_BELEUCHTUNGKABEL',
    'BVER_BELEUCHTUNGSKABEL_SCHUTZR',
    'BVER_BREITBAND',
    'BVER_FERNMELDEKABEL',
    'BVER_FERNWÄRME-RÜCK',
    'BVER_FERNWÄRME-VOR',
    'BVER_GAS',
    'BVER_GASHOCHDRUCKLEITUNG',
    'BVER_HOCHSPANNUNG',
    'BVER_KABELKAN_SCHUTZR',
    'BVER_KORROSIONSSCHUTZ',
    'BVER_LEERROHR',
    'BVER_LICHTWELLENLEITER',
    'BVER_MITTELSPANNUNG',
    'BVER_NIEDERSPANNUNG',
    'BVER_ROHRPOST',
    'BVER_SIGNALKABEL',
    'BVER_STEUERKABEL',
    'BVER_TELEKOM',
    'BVER_TRINKWASSER'
  ].map(function (name, index) {
    return { nr: index + 1, name: name, props: {} };
  });

  /* ------------------------------------------------------------------ *
   * Linientypkatalog
   *
   * Insgesamt 87 Linientypen sind im Linientyp-Manager vorhanden
   * (Abbildungen 125–127). Namentlich gesichert aufgenommen sind bisher die
   * unten gelisteten Einträge; die vollständige Namensliste wird aus der
   * Quelldatei bzw. der .lin-Datei übernommen (siehe Import in Abschnitt 13).
   * ------------------------------------------------------------------ */

  const LINETYPE_TOTAL = 87;

  const LINETYPE_GROUPS = [
    { key: 'ENTW', label: 'ENTW', note: 'Entwässerung / Kanal' },
    { key: 'GP', label: 'GP', note: 'Grundstücks-/Planungslinien' },
    { key: 'HOEHEN', label: 'Höhenlinien', note: 'Höhen- und Geländelinien' },
    { key: 'LEV', label: 'LEV', note: 'Leitungen Energie/Versorgung' },
    { key: 'MARK', label: 'MARK', note: 'Markierungen, M500-/M1000-Varianten' },
    { key: 'VERS', label: 'VERS', note: 'Versorgungsleitungen' },
    { key: 'ZAUN', label: 'ZAUN', note: 'Zäune und Einfriedungen' },
    { key: 'SONSTIGE', label: 'Sonstige', note: 'u. a. CONTINIOUS und Continuous' }
  ];

  const LINETYPES = [
    { name: 'CONTINIOUS', group: 'SONSTIGE', desc: '–', pattern: '————————————————' },
    { name: 'Continuous', group: 'SONSTIGE', desc: '–', pattern: '————————————————' },
    { name: 'ENTW_Entfaellt', group: 'ENTW', desc: 'Entfällt', pattern: '——— x ——— x ———' },
    { name: 'GP_GESTRICHELT 6_1', group: 'GP', desc: 'gestrichelt 6:1', pattern: '————  ————  ————' },
    {
      name: 'LEV_Mittelspannung_Fernheizung',
      group: 'LEV',
      desc: 'Mittelspannung / Fernheizung',
      pattern: '——— · ——— · ———'
    },
    { name: 'VERS_TELEKOM_M500', group: 'VERS', desc: 'Telekom, Maßstab 500', pattern: '——— T ——— T ———' }
  ];

  const LINETYPE_NOTES = [
    'Die Zeichenfolgen in der Spalte „Darstellung“ sind textuelle Annäherungen der sichtbaren AutoCAD-Vorschau. Maßgeblich sind die Screenshots und die in AutoCAD geladenen Linientypdefinitionen.',
    'Bewusst unverändert aufgenommen: die getrennten Einträge CONTINIOUS und Continuous, die Bezeichnungen ENTW_Entfaellt, GP_GESTRICHELT 6_1, LEV_Mittelspannung_Fernheizung sowie alle M500-/M1000-Varianten.'
  ];

  /* ------------------------------------------------------------------ *
   * Farbenkatalog – aktuell dokumentierter Farbwert
   * ------------------------------------------------------------------ */

  const COLORS = [
    {
      name: 'magenta',
      index: 'Bezeichnung im Register „Indexfarbe“: magenta. Eine numerische ACI-Indexnummer ist in der bereitgestellten Abbildung nicht sichtbar und wird deshalb nicht ergänzt.',
      truecolor: 'RGB 255, 0, 255 · HSL: Farbton 300, Sättigung 100, Helligkeit 50 · Farbmodell im Screenshot: HSL, True Color als RGB gespeichert.',
      css: 'rgb(255, 0, 255)'
    }
  ];

  /* ------------------------------------------------------------------ *
   * Auffälligkeiten und bewusste Prüfpunkte
   * ------------------------------------------------------------------ */

  const FINDINGS = [
    'BKAN_LINIE_DRAINAGE_KANAL im Layer-Manager, in Abbildungen teilweise BKAN_LINE_DRAINAGE_KANAL.',
    'Gemischte Schreibweisen wie BKAN_LINIE_M_Haltung, BKAN_LINIE_S_Haltung und andere Layer mit _KANAL.',
    'Planungsbilder zeigen KANPL_LINIE_…, KANPL_Linie_… und KANPL_LINE_…',
    'CONTINIOUS erscheint in mehreren BVER-Linientypen und sollte auf beabsichtigte Schreibweise geprüft werden.',
    'BVER_BELEUCHTUNGKABEL und BVER_BELEUCHTUNGSKABEL_SCHUTZR verwenden unterschiedliche „S“-Schreibweisen.',
    'Bestand nutzt teilweise SCHACHTBAUW, Planung in Bildern SCHACHTBAUWERK.',
    'Bei einigen Plotstilen/Feldern stehen Werte wie „Normal“, „Farbe“ oder leere Beschreibungen; ihre beabsichtigte Standardfunktion ist zu prüfen.',
    'Zu entscheiden ist, ob die Bildschirmfarben nur Arbeitsfarben sind oder Bestandteil des verbindlichen Darstellungsstandards werden.',
    'Im Linientypkatalog existieren sowohl CONTINIOUS als auch Continuous; die beabsichtigte Verwendung und Schreibweise ist zu prüfen.',
    'Die M500- und M1000-Linientypvarianten sind als eigene Einträge vorhanden; zu klären ist, ob sie maßstabsbezogen automatisch oder manuell eingesetzt werden.',
    'Der aktuell dokumentierte konkrete Farbwert ist magenta beziehungsweise RGB 255,0,255. Ein vollständiger verbindlicher Farbenkatalog bleibt weiter auszubauen.'
  ];

  /* ------------------------------------------------------------------ *
   * Offene Entscheidungen – Beschlussvorbereitung
   * ------------------------------------------------------------------ */

  const DECISIONS = [
    {
      key: 'schriftgroessen',
      title: 'Schriftgrößen für 1:250 und 1:500',
      text: 'Für alle Darstellungsgegenstände der Maßstabsmatrix sind noch keine Werte vorgegeben.',
      module: 'Termin 1'
    },
    {
      key: 'design-bestand',
      title: 'Klassisches Design im Bestand',
      text: 'In den „Sonstigen Informationen“ nicht eingetragen und damit offen.',
      module: 'Termin 1'
    },
    {
      key: 'design-planung',
      title: 'Klassisches Design in der Planung',
      text: 'Ebenfalls nicht eingetragen und damit offen.',
      module: 'Termin 2'
    },
    {
      key: 'familien-umfang',
      title: 'Verbindlicher Umfang der Darstellungsfamilien',
      text: 'Welche Familien gehören verbindlich in den „klassischen“ Bestandsstandard, welche werden nur bei Bedarf verwendet?',
      module: 'Termin 1'
    },
    {
      key: 'druckleitung-differenzierung',
      title: 'Druckleitung neutral oder nach R/M/S getrennt',
      text: 'Beide Varianten sind in den Layern und Bildern vorhanden.',
      module: 'Termin 1'
    },
    {
      key: 'schreibweisen',
      title: 'Schreibweisen der Layernamen',
      text: 'LINIE / Linie / LINE, SCHACHTBAUW / SCHACHTBAUWERK, _KAN / _KANAL / _Haltung.',
      module: 'Termin 1'
    },
    {
      key: 'pflichtangaben',
      title: 'Pflichtangaben und Reihenfolge in der Beschriftung',
      text: 'Welche Angaben gehören an Haltung und Schacht, in welcher Reihenfolge, mit welchen Abkürzungen und wie wird „vorh.“ gekennzeichnet?',
      module: 'Termin 1'
    },
    {
      key: 'stauziel',
      title: 'Behandlung von BKAN_STAUZIEL_WSP',
      text: 'Sonderfall ohne Gegenstück in den übrigen Objektgruppen.',
      module: 'Termin 1'
    },
    {
      key: 'continious',
      title: 'CONTINIOUS gegenüber Continuous',
      text: 'Zwei getrennte Linientypeinträge mit unterschiedlicher Schreibweise.',
      module: 'Termin 3'
    },
    {
      key: 'beleuchtungskabel',
      title: 'BVER_BELEUCHTUNGKABEL gegenüber BVER_BELEUCHTUNGSKABEL_SCHUTZR',
      text: 'Unterschiedliche „S“-Schreibweise innerhalb derselben Layerfamilie.',
      module: 'Termin 3'
    },
    {
      key: 'm500-m1000',
      title: 'M500-/M1000-Linientypvarianten',
      text: 'Maßstabsbezogen automatisch oder manuell einsetzen?',
      module: 'Termin 3'
    },
    {
      key: 'farbenkatalog',
      title: 'Farben als Arbeitsfarben oder Standardbestandteil',
      text: 'Bisher ist nur magenta (RGB 255,0,255) konkret dokumentiert; ein vollständiger Farbenkatalog fehlt.',
      module: 'Termin 1'
    },
    {
      key: 'layer-eigenschaften',
      title: 'Eigenschaftswerte aus dem Layer-Manager übernehmen',
      text: 'Farbe, Linientyp, Linienstärke, Transparenz und Plotstil sind zeilengetreu aus der XLSX zu übernehmen und danach als verbindlich zu bestätigen.',
      module: 'Termin 1'
    },
    {
      key: 'leere-felder',
      title: 'Leere Beschreibungs- und Plotstilfelder',
      text: 'Beabsichtigte Standardfunktion der leeren beziehungsweise mit „Normal“/„Farbe“ belegten Felder klären.',
      module: 'Termin 1'
    }
  ];

  /* ------------------------------------------------------------------ *
   * Quellen und Anhänge
   * ------------------------------------------------------------------ */

  const ATTACHMENTS = [
    {
      file: 'Kanal_Layereigenschaften_Layer-Manager.xlsx',
      label: 'Layer-Manager (XLSX)',
      note: 'Maßgebliche Quelle der 66 Layerdatensätze.'
    },
    {
      file: 'Kanal_Layereigenschaften_Layer-Manager.pdf',
      label: 'Layer-Manager (PDF)',
      note: 'Druckfassung derselben Layerliste.'
    },
    {
      file: 'DIN_1356-1_2018.pdf',
      label: 'DIN 1356-1_2018 (nur ergänzend)',
      note: 'Bauzeichnungen – Teil 1: Grundregeln der Darstellung. Im aktuell verarbeiteten Uploadsatz nicht als eigenständige Datei verfügbar.'
    }
  ];

  /* ------------------------------------------------------------------ *
   * Wiederverwendbarer Master-Prompt
   * ------------------------------------------------------------------ */

  const MASTER_PROMPT = [
    'MASTER-PROMPT: KANALSTANDARD / WORKSHOP-VORBEREITUNG',
    '',
    'ROLLE UND ARBEITSMODUS',
    'Du unterstützt bei der schrittweisen Entwicklung und Verfestigung eines gemeinsamen CAD-/Zeichnerstandards für Kanal- und später Versorgungspläne. Arbeite streng quellenbezogen mit den hier aufgenommenen Informationen. Erfinde keine noch nicht festgelegten Schriftgrößen, Designs, Layer oder Darstellungsregeln. Kennzeichne fehlende Entscheidungen ausdrücklich als OFFEN. Die DIN 1356-1 ist nur eine ergänzende Orientierung und darf die gemeinsam zu entwickelnde betriebliche Lösung nicht dominieren.',
    '',
    'ORIGINALKONTEXT',
    ORIGINAL_MESSAGE[0],
    '',
    ORIGINAL_MESSAGE[1],
    '',
    'ZIEL UND REIHENFOLGE',
    '1. Zuerst ausschließlich Bestandskanal strukturieren.',
    '2. Kanalarten bestimmen: mindestens RW/Regenwasser, SW/Schmutzwasser, MW/Mischwasser; zusätzlich die vorhandenen Sonderformen Drainage, Druckleitung, Saugleitung, Pumpleitung, Anschlussleitung und Hausanschluss berücksichtigen.',
    '3. Für jedes Objekt die zugehörigen Layer, Texte, Schacht-/Haltungsinformationen, Linien-/Signaturdarstellungen und Schriftgrößen definieren.',
    '4. Die Festlegungen getrennt für die Maßstäbe 1:250 und 1:500 treffen.',
    '5. Der erste Abstimmungstermin soll etwa 20 bis 30 Minuten dauern und zunächst eine belastbare Struktur sowie Entscheidungslisten erzeugen.',
    '6. In einem späteren Termin dieselbe Systematik für die Kanalplanung behandeln.',
    '7. Danach die Versorgungsleitungen/V-Leitungen behandeln.',
    '8. Alle bestätigten Ergebnisse schrittweise in eine gemeinsame Standard-DWG überführen, pflegen und innerhalb von ungefähr einem halben Jahr vervollständigen.',
    '',
    'BEREITGESTELLTE QUELLEN',
    '- Zehn originale CAD-Abbildungen image(108).png bis image(117).png.',
    '- Drei Screenshots des Linientyp-Managers image(125).png bis image(127).png.',
    '- Zwei Screenshots der AutoCAD-Farbauswahl image(128).png und image(129).png.',
    '- Kanal_Layereigenschaften_Layer-Manager.xlsx mit 66 Layerdatensätzen.',
    '- Kanal_Layereigenschaften_Layer-Manager.pdf als Druckfassung derselben Liste.',
    '- DIN 1356-1_2018 als ergänzende, nicht dominierende Orientierung.',
    '',
    'AUFGENOMMENE LAYERFAMILIEN',
    '- Bestandskanal BKAN: 42 Datensätze, objektbezogen gegliedert in Kanalachsen/Haltungen, Rohrwandungen, Schachtbauwerke, Schachtnummern, Stutzen, Deckel-/Sohltexte, Haltungstexte, Druck-/Saug-/Pumpleitungen, Anschluss/Hausanschluss und den Sonderfall BKAN_STAUZIEL_WSP.',
    '- Kanalplanung KANPL: visuell aus den Originalbildern abgelesen, nicht in der XLSX enthalten, Schreibweisen unverändert.',
    '- Versorgung BVER: 22 Datensätze für spätere Termine.',
    '- Zwei weitere Datensätze außerhalb dieser Familien: BKAT_GEBÄUDE und BLAL_GEBAEUDE_TRAFO.',
    '',
    'BLOCKNAMEN',
    '- Planung: PFahneMisch, PFahneRegen, PFahneSchmutz, PfeilBlock.',
    '- Bestand: BFahneMisch, BFahneRegen, BFahneSchmutz.',
    '- Bausteine: Schachtnummer im Kreis (R100/M100/S100/D100), ovale Höhen-/Nummernangabe, getrennte Felder für KD und KS, Fahnenlinien, Pfeilblöcke.',
    '',
    'LINIENTYPEN UND FARBEN',
    '- 87 Linientypen sind im Linientyp-Manager vorhanden, gegliedert in ENTW, GP, Höhenlinien, LEV, MARK, VERS, ZAUN und Sonstige.',
    '- Getrennte Einträge CONTINIOUS und Continuous sowie M500-/M1000-Varianten bewusst unverändert übernehmen.',
    '- Konkret dokumentierter Farbwert: magenta, RGB 255,0,255, HSL 300/100/50. Ein vollständiger Farbenkatalog ist noch aufzubauen.',
    '',
    'OFFENE PUNKTE, DIE NICHT EIGENMÄCHTIG ENTSCHIEDEN WERDEN',
    '- Schriftgrößen für 1:250 und 1:500.',
    '- Klassisches Design im Bestand und in der Planung.',
    '- Verbindlicher Umfang der Darstellungsfamilien.',
    '- Druckleitung neutral oder getrennt nach R/M/S.',
    '- Vereinheitlichung der Schreibweisen in Layernamen und Linientypen.',
    '- Pflichtangaben und Reihenfolge der Beschriftung an Haltung und Schacht.',
    '- Verbindlichkeit von Farben, Plotstilen und leeren Feldern.',
    '',
    'ARBEITSWEISE',
    '- Quellenpriorität bei Abweichungen: Originalbilder, dann XLSX/PDF, dann erzeugte Übersichtsgrafik.',
    '- Uneinheitliche Layernamen nicht stillschweigend bereinigen, sondern als Entscheidungspunkt ausweisen.',
    '- Ergebnisse als Struktur, Entscheidungsmatrix und Beschlussliste ausgeben, nicht als fertige Norm.',
    '- Jede Ergänzung so aufbereiten, dass sie ohne Umbau in dieses Dokument übernommen werden kann.'
  ].join('\n');

  root.KANALSTANDARD = {
    originalMessage: ORIGINAL_MESSAGE,
    workRequirements: WORK_REQUIREMENTS,
    modules: MODULES,
    agenda: AGENDA,
    channelTypesMain: CHANNEL_TYPES_MAIN,
    channelTypesSpecial: CHANNEL_TYPES_SPECIAL,
    figures: FIGURES,
    overviewFigure: OVERVIEW_FIGURE,
    bkanGroups: BKAN_GROUPS,
    kanplLayers: KANPL_LAYERS,
    blocks: BLOCKS,
    blockParts: BLOCK_PARTS,
    bverLayers: BVER_LAYERS,
    scaleMatrix: SCALE_MATRIX,
    layerColumns: LAYER_COLUMNS,
    layerManager: LAYER_MANAGER,
    linetypeTotal: LINETYPE_TOTAL,
    linetypeGroups: LINETYPE_GROUPS,
    linetypes: LINETYPES,
    linetypeNotes: LINETYPE_NOTES,
    colors: COLORS,
    findings: FINDINGS,
    decisions: DECISIONS,
    attachments: ATTACHMENTS,
    masterPrompt: MASTER_PROMPT
  };
})(window);
