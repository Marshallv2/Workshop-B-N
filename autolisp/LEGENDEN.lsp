;;; =====================================================================
;;;  LEGENDEN.lsp
;;;  ---------------------------------------------------------------------
;;;  Erzeugt eine Legende fuer die in einem vom Anwender ausgewaehlten
;;;  Planbereich belegten Layer.
;;;
;;;  Beim Aufruf wird zuerst der PROJEKTBEREICH abgefragt (Objekte per
;;;  Fenster/Schneiden/Einzelwahl auswaehlen), danach welche Art Legende:
;;;
;;;    [KLP]           -> Legende "Versorgungsleitungen / Kanal":
;;;                       je belegtem Fachlayer ein 32-Einheiten-Strich
;;;                       (Farbe + Linientyp vom Layer) + Text "vorh. ..."
;;;
;;;    [Schutzgebiete] -> Legende aus Symbolbloecken (Flaechennutzung /
;;;                       Schutzgebiete) aus 01_Standard_KLP.dwg.
;;;
;;;  BEREICHSAUSWAHL (WICHTIG):
;;;    Vor der eigentlichen Legendenerstellung fragt der Befehl:
;;;      "Bereich fuer die Legende auswaehlen (Fenster/Objekte) ..."
;;;    Hier waehlt man per Fenster/Schneidenfenster/Einzelklick genau die
;;;    Objekte im eigenen Projektbereich aus (z.B. alle Leitungen/Symbole
;;;    innerhalb der Planumgrenzung). NUR die Layer, auf denen dabei
;;;    tatsaechlich Objekte liegen, kommen als "belegt" in Frage - und
;;;    auch nur, wenn sie zusaetzlich in *LEG-KLP-MAP* bzw. *LEG-MAP*
;;;    als gewuenschter Versorger-/Schutzgebiets-Layer eingetragen sind.
;;;    Damit landen keine Layer mehr in der Legende, die zwar irgendwo
;;;    in der Zeichnung (anderer Planbereich, andere Blattgrenze, XRef
;;;    einer Nachbar-Trasse etc.) vorkommen, aber nicht zum ausgewaehlten
;;;    Bereich gehoeren.
;;;
;;;    Die Bereichsauswahl wird rekursiv ausgewertet: liegt im Bereich
;;;    eine Blockreferenz (auch geladene XRefs, verschachtelte Bloecke,
;;;    Attribute), werden auch die darin enthaltenen Objekte/Layer erfasst.
;;;
;;;  ERKENNUNG "belegt" bei der Legendenerstellung (LEGENDEN/LEG):
;;;    Ausschliesslich Objekt-Scan INNERHALB des ausgewaehlten Bereichs
;;;    (siehe oben). Es gibt bewusst KEINEN Fallback mehr auf "Layer
;;;    existiert irgendwo in der Zeichnung/Layertabelle" - genau das war
;;;    die Ursache dafuer, dass Layer aus fremden Planbereichen in der
;;;    Legende auftauchten.
;;;
;;;  ERKENNUNG "belegt" bei der Diagnose (LEGCHECK):
;;;    LEGCHECK bewertet weiterhin die GESAMTE Zeichnung (nicht nur einen
;;;    Bereich) und zeigt dreistufig:
;;;      Stufe 1 (OBJ): Objekt-Scan ueber ALLE Blockdefinitionen.
;;;      Stufe 1b (OBJ): Direktsuche per Auswahlsatz (ssget "X").
;;;      Stufe 2 (TAB): Layer existiert in der Layertabelle.
;;;    Das ist weiterhin nuetzlich, um zu sehen, welche Layer ueberhaupt
;;;    irgendwo vorkommen bzw. welche S_-Layer noch nicht in *LEG-MAP*
;;;    eingetragen sind. Fuer die eigentliche Legende (LEGENDEN) zaehlt
;;;    aber nur der ausgewaehlte Bereich, s.o.
;;;
;;;  Quelldatei-Import (Schutzgebiete) ist mehrstufig abgesichert:
;;;    1. lokale Kopie nach %TEMP% -> ObjectDBX liest die Kopie
;;;    2. Fallback: ObjectDBX direkt am Originalpfad
;;;    3. Fallback: nativer InsertBlock der Datei (ohne COM-Server)
;;;
;;;  Befehle:  LEGENDEN  (Kurz: LEG)      LEGCHECK = Diagnose (Gesamtplan)
;;;            LEGCHECK zeigt je Layer:  [OBJ] Objekte gefunden
;;;                                      [TAB] nur in Layertabelle
;;;                                      [ - ] Layer fehlt komplett
;;;
;;;  AENDERUNG 08/2026:
;;;    - NEU: Vor der Legendenerstellung wird der Projektbereich per
;;;      Objektauswahl (ssget) abgefragt. Die Belegt-Erkennung fuer
;;;      LEGENDEN laeuft nur noch ueber diesen Bereich (rekursiv inkl.
;;;      Bloecke/XRefs/Attribute) - dadurch werden keine Layer aus
;;;      fremden Planbereichen mehr mit in die Legende aufgenommen.
;;;    - Die bisherige "Layertabelle reicht"-Stufe (TAB) wird bei der
;;;      Legendenerstellung NICHT mehr verwendet (Ursache des Fehlers:
;;;      ein Layer, der irgendwo in der Zeichnung existiert, wurde immer
;;;      als "belegt" gewertet - unabhaengig vom Planbereich). *LEG-SG-
;;;      TABOK* / *LEG-KLP-TABOK* wirken jetzt nur noch in LEGCHECK.
;;;    - LEGCHECK unveraendert als Ganz-Zeichnung-Diagnose erhalten.
;;;
;;;  AENDERUNG 07/2026 v2:
;;;    - Stufe 1b: zusaetzliche Direktsuche per ssget "X", falls der
;;;      Block-Scan ein Objekt verpasst (Beispiel: BVER_TELEKOM)
;;;    - KLP: Layertabellen-Erkennung jetzt standardmaessig EIN,
;;;      damit belegte Layer garantiert gefunden werden; nur-TAB-
;;;      Treffer werden in der Meldung einzeln aufgelistet
;;;
;;;  AENDERUNG 07/2026:
;;;    - zweistufige Belegt-Erkennung (OBJ/TAB, s.o.)
;;;    - je Legendeneintrag sind jetzt MEHRERE alternative Layernamen
;;;      moeglich (Liste statt Einzelname)
;;;    - NATURSCHUTZBEREICHE deckt beide Namensvarianten ab
;;;      (S_DWG_BEREICHESCHUTZNATUR / S_DWG_NATURSCHUTZBEREICH)
;;;    - NATURPARKS deckt S_DWG_NATURPARK und S_DWG_NATURPARKE ab
;;;    - LEGCHECK erweitert + Hinweis auf vorhandene S_-Layer ohne
;;;      Zuordnung in *LEG-MAP*
;;;
;;;  WICHTIG: Datei als ANSI (Windows-1252) speichern, sonst werden
;;;  Layer-/Blocknamen mit Umlauten (z.B. FERNWAERME, ...FLAECHEN) nicht
;;;  gefunden.
;;; =====================================================================

(vl-load-com)

;;; ======================= EINSTELLUNGEN ===============================

;; ---- gemeinsam ----
;; Textstil fuer die Beschriftung (Fallback auf aktuellen Stil,
;; falls im Plan nicht vorhanden):
(setq *LEG-STYLE*  "BUN AKG")

;; ---- Erkennung "belegt" ----
;; Diese beiden Schalter wirken NUR noch auf LEGCHECK (Diagnose der
;; gesamten Zeichnung). Die eigentliche Legendenerstellung (LEGENDEN/
;; LEG) verwendet ausschliesslich den vom Anwender vorher ausgewaehlten
;; Bereich (Objekt-Scan, s. Kopfkommentar) und ignoriert die
;; Layertabellen-Stufe bewusst, damit keine planfremden Layer mehr in
;; die Legende gelangen.
(setq *LEG-SG-TABOK*  T)   ;; LEGCHECK Schutzgebiete: T = Layer vorhanden reicht
(setq *LEG-KLP-TABOK* T)   ;; LEGCHECK KLP:           T = Layer vorhanden reicht

;; ---- Schutzgebiete (Symbolbloecke) ----
;; Quelldatei mit den Symbolbloecken:
(setq *LEG-SRC*    "J:\\ACAD\\Vorlagen\\01_Standard_KLP.dwg")
;; Layer, auf den Symbole + Text gelegt werden ("" = aktueller Layer):
(setq *LEG-LAYER*  "S_LEGENDE")
;; Texthoehe -> an Planmaszstab anpassen:
(setq *LEG-TXTH*   2.5)
;; Vertikaler Abstand ZWISCHEN zwei Symbolen (zusaetzlich zur Symbolhoehe):
(setq *LEG-ROWGAP* 1.0)
;; Horizontaler Abstand: rechte Symbolkante -> Text:
(setq *LEG-TXTGAP* 2.0)

;; ---- KLP (Strich + Text) ----
;; Laenge des Beispielstrichs in Zeichnungseinheiten:
(setq *LEG-KLP-LEN*    32.0)
;; Texthoehe der Beschriftung:
(setq *LEG-KLP-TXTH*   2.5)
;; Horizontaler Abstand: Strichende -> Text:
(setq *LEG-KLP-TXTGAP* 4.0)
;; Vertikaler Zeilenabstand (Mitte zu Mitte):
(setq *LEG-KLP-ROWGAP* 5.0)
;; Text-Praefix vor jeder Bezeichnung:
(setq *LEG-KLP-PREFIX* "vorh. ")
;; Layer fuer die TEXTE ("" = aktueller Layer).
;; ACHTUNG: Die Striche bleiben IMMER auf ihrem Fachlayer, damit Farbe
;; und Linientyp stimmen - nur der Text wandert auf diesen Layer.
(setq *LEG-KLP-LAYER*  "LGND_KLP_0.25")

;;; ----------------- ZUORDNUNG SCHUTZGEBIETE: BLOCK -> LAYER -----------
;; Reihenfolge hier = Reihenfolge in der Legende.
;; Format: ("BLOCKNAME" LAYER)
;;   LAYER = "NAME"  ODER  Liste alternativer Namen ("NAME1" "NAME2").
;;   Der Eintrag gilt als belegt, sobald EINER der Namen zutrifft
;;   (nuetzlich bei unterschiedlich benannten Quell-DWGs).
(setq *LEG-MAP*
  '(("ABSCHNITT_AESTE"             "S_DWG_ABSCHNITTEAESTE")
    ("BIOSPHAERENRESERVAT"         "S_BIOSPHAERENRESERVAT")
    ("BIOTOPKATASTERS"             "S_DWG_BIOTOPKATASTER")
    ("BIOTOPSVERBUNDFL�CHEN"       "S_DWG_BIOTOPVERBUNDFLAECHEN_FARB")
    ("DEPONIEN"                    "S_DEPONIE")
    ("FFH-GEBIET"                  "S_DWG_FFH-GEBIETE")
    ("GEM_BAUFLAECHEN"             "S_GEMISCHTE_BAUFLAECHE_FARB")
    ("GEMEINBEDARF"                "S_GEMEINBEDARF")
    ("GES_LANDSCHAFTSBESTANDTEILE" "S_GES_LANDSCHAFTSBESTANDTEIL")
    ("GESCHUETZTE_BIOTOPE"         "S_DWG_GESCHUETZTEBIOTOPE")
    ("GEW_BAUFLAECHE"              "S_GEWERBLICHE_BAUFLAECHE_FARB")
    ("HEILQUELLENSCHUTZGEBIETE"    "S_HEILQUELLENSCHUTZGEBIET")
    ("KULTUR_BAU_BODENDENKMAL"     "S_KULTUR_BAU_BODENDENKMAL")
    ("LANDSCHAFTSRAUM"             "S_DWG_LANDSCHAFTSRAEUME")
    ("LANDSCHAFTSSCHUTZGEBIETE"    "S_DWG_LANDSCHAFTSSCHUTZGEBIETE")
    ("NATIONAL_NATURMONUMENTE"     "S_NATIONALES_NATURMONUMENT")
    ("NATIONALPARK"                "S_NATIONALPARK")
    ("NATURDENKMAL"                "S_NATURDENKMAL")
    ;; deckt Singular- und Plural-Layer ab:
    ("NATURPARKS"                  ("S_DWG_NATURPARK" "S_DWG_NATURPARKE"))
    ;; deckt beide Namensvarianten ab:
    ("NATURSCHUTZBEREICHE"         ("S_DWG_BEREICHESCHUTZNATUR" "S_DWG_NATURSCHUTZBEREICH"))
    ("NATURSCHUTZGEBIETE"          "S_DWG_NATURSCHUTZGEBIETE")
    ("RAMSAR"                      "S_DWG_RAMSAR")
    ("SCHUTZWAELDER"               "S_SCHUTZWALD")
    ("SONDERBAUFLAECHE"            "S_SONDERBAUFLAECHE_FARB")
    ("UEBERSCHWEMMUNGSGEBITE"      "S_DWG_UEBERSCHWEMMUNGSGEBIETE")
    ("VOGELSCHUTZGEBIETE"          "S_DWG_VOGELSCHUTZGEBIETE")
    ("WASSERSCHUTZZONE_III"        "S_WASSERSCHUTZZONE_III")
    ("WASSERSCHUTZZONE_II"         "S_WASSERSCHUTZZONE_I_II")
    ("WOHNBAUFLAECHEN"             "S_WOHNBAUFLAECHE_FARB")
    ;; TODO: Blocknamen in 01_Standard_KLP.dwg pruefen und eintragen,
    ;; dann einkommentieren (Layer sind in Plaenen bereits aufgetaucht):
    ;; ("????"                     "S_DWG_GEBIETESCHUTZNATUR")
    ;; ("????"                     "S_WANDERWEGE")
   )
)

;;; ----------------- ZUORDNUNG KLP: LAYER -> BEZEICHNUNG ---------------
;; Reihenfolge hier = Reihenfolge in der Legende.
;; Format: (LAYER "Bezeichnung")  -> Text wird "vorh. Bezeichnung"
;;   LAYER = "NAME" oder Liste alternativer Namen (wie oben).
;; Nur belegte Layer landen in der Legende (belegt = im ausgewaehlten
;; Bereich vorhanden, siehe Kopfkommentar).
(setq *LEG-KLP-MAP*
  '(;; --- Kanal (BKAN) ---
    ("BKAN_LINIE_R_KANAL"             "Regenwasserkanal")
    ("BKAN_LINIE_M_Haltung"           "Mischwasserkanal")
    ("BKAN_LINIE_S_Haltung"           "Schmutzwasserkanal")
    ("BKAN_ROHRWANDUNG_R_KAN"         "Regenwasserkanal (Rohrwandung)")
    ("BKAN_ROHRWANDUNG_M_KAN"         "Mischwasserkanal (Rohrwandung)")
    ("BKAN_ROHRWANDUNG_S_KAN"         "Schmutzwasserkanal (Rohrwandung)")
    ("BKAN_DRUCKLEITUNG_R"            "Regenwasserdruckleitung")
    ("BKAN_DRUCKLEITUNG_M"            "Mischwasserdruckleitung")
    ("BKAN_DRUCKLEITUNG_S"            "Schmutzwasserdruckleitung")
    ("BKAN_DRUCKLEITUNG"              "Druckleitung")
    ("BKAN_LINIE_PUMPLEITUNG_KAN"     "Pumpleitung")
    ("BKAN_LINIE_SAUGLEITUNG_KAN"     "Saugleitung")
    ("BKAN_LINIE_DRAINAGE_KANAL"      "Drainage")
    ("BKAN_KANALACHSE"                "Kanalachse")
    ("BKAN_HAUSANSCHL"                "Hausanschluss")
    ("BKAN_ANSCHLUSSLEITUNG"          "Anschlussleitung")

    ;; --- Versorgung (BVER) ---
    ("BVER_NIEDERSPANNUNG"            "Niederspannung")
    ("BVER_MITTELSPANNUNG"            "Mittelspannung")
    ("BVER_HOCHSPANNUNG"              "Hochspannung")
    ("BVER_BELEUCHTUNGKABEL"          "Beleuchtungskabel")
    ("BVER_BELEUCHTUNGSKABEL_SCHUTZR" "Beleuchtungskabel (Schutzrohr)")
    ("BVER_TRINKWASSER"               "Wasser")
    ("BVER_GAS"                       "Gas")
    ("BVER_GASHOCHDRUCKLEITUNG"       "Gashochdruckleitung")
    ("BVER_FERNWÄRME-VOR"             "Fernwärme Vorlauf")
    ("BVER_FERNWÄRME-RÜCK"            "Fernwärme Rücklauf")
    ("BVER_FERNMELDEKABEL"            "Fernmeldekabel")
    ("BVER_TELEKOM"                   "Telekom")
    ("BVER_LICHTWELLENLEITER"         "Lichtwellenleiter")
    ("BVER_STEUERKABEL"               "Steuerkabel")
    ("BVER_SIGNALKABEL"               "Signalkabel")
    ("BVER_BREITBAND"                 "Breitbandkabel")
    ("BVER_KABELKAN_SCHUTZR"          "Kabelkanal (Schutzrohr)")
    ("BVER_ROHRPOST"                  "Rohrpost")
    ("BVER_LEERROHR"                  "Leerrohr")
    ("BVER_KORROSIONSSCHUTZ"          "Korrosionsschutz")
    ;; unklare Kuerzel -> Bezeichnung bei Bedarf anpassen:
    ("BVER_AUSA"                      "Aussparung (AUSA)")

    ;; --- reine Beschriftungs-/Symbol-Layer: bewusst AUS ---------------
    ;; (keine Linien; bei Bedarf einkommentieren + Text anpassen)
    ;; ("BKAN_SCHACHTBAUW_R_KAN"      "Schachtbauwerk (Regen)")
    ;; ("BKAN_SCHACHTBAUW_M_KAN"      "Schachtbauwerk (Misch)")
    ;; ("BKAN_SCHACHTBAUW_S_KAN"      "Schachtbauwerk (Schmutz)")
    ;; ("BKAT_GEBÄUDE"                "Gebäude (Kataster)")
    ;; ("BLAL_GEBAEUDE_TRAFO"         "Trafogeb�ude")
   )
)

;;; ======================= HILFSFUNKTIONEN =============================

;; Liste ALLER im Plan von Objekten verwendeten Layer (UPPERCASE),
;; ermittelt durch Scan ueber jede Blockdefinition (inkl. Modell-/
;; Layoutbereich, Bloecke, geladene XRefs). Wird NUR noch von LEGCHECK
;; (Ganz-Zeichnung-Diagnose) verwendet - die Legendenerstellung selbst
;; nutzt LEG:build-usedlayers-from-selection (s.u.).
(defun LEG:build-usedlayers ( / used rec en ed lay cnt cap)
  (setq used '() cnt 0 cap 4000000)
  (setq rec (tblnext "BLOCK" T))
  (while (and rec (< cnt cap))
    (setq en (cdr (assoc -2 rec)))
    (while (and en (< cnt cap))
      (setq cnt (1+ cnt)
            ed  (entget en))
      (if ed
        (progn
          (setq lay (cdr (assoc 8 ed)))
          (if lay
            (progn
              (setq lay (strcase lay))
              (if (not (member lay used)) (setq used (cons lay used)))))
          (if (= (cdr (assoc 0 ed)) "ENDBLK")
            (setq en nil)
            (setq en (entnext en))))
        ;; entget fehlgeschlagen -> Objekt ueberspringen statt Block abbrechen
        (setq en (entnext en))))
    (setq rec (tblnext "BLOCK" nil)))
  (if (>= cnt cap)
    (princ "\n(Hinweis: sehr grosse Zeichnung - Belegt-Scan ggf. unvollstaendig)"))
  used
)

;; Liste ALLER Layernamen der Layertabelle (UPPERCASE, inkl. XRef-Layer).
;; Wird NUR noch von LEGCHECK verwendet.
(defun LEG:build-layertab ( / lst rec)
  (setq lst '()
        rec (tblnext "LAYER" T))
  (while rec
    (setq lst (cons (strcase (cdr (assoc 2 rec))) lst))
    (setq rec (tblnext "LAYER" nil)))
  lst
)

;; Ist Layer "lay" in der Liste "used"?  Beruecksichtigt exakte Treffer
;; UND XRef-abhaengige Namen ("xref|layer").  Case-egal.
;; Funktioniert fuer Objekt-Scan-Liste UND Layertabellen-Liste.
(defun LEG:in-used (lay used / layU pat n hit)
  (setq layU (strcase lay))
  (if (member layU used)
    t
    (progn
      (setq pat (strcat "|" layU) n (strlen pat) hit nil)
      (foreach u used
        (if (and (null hit)
                 (>= (strlen u) n)
                 (= (substr u (1+ (- (strlen u) n))) pat))
          (setq hit t)))
      hit))
)

;; Layer-Spezifikation normalisieren: "NAME" -> ("NAME"), Liste bleibt.
(defun LEG:layspec->list (spec)
  (if (listp spec) spec (list spec))
)

;; Anzeige-String einer Layer-Spezifikation: "A" bzw. "A / B"
(defun LEG:spec->string (spec / s l)
  (setq s "")
  (foreach l (LEG:layspec->list spec)
    (setq s (if (= s "") l (strcat s " / " l))))
  s
)

;; Stufe 1b (nur LEGCHECK): Direktsuche per Auswahlsatz ueber die GESAMTE
;; Zeichnung. Findet Objekte auf dem Layer (auch XRef-Variante
;; "xref|layer"), falls der Block-Scan sie in Sonderfaellen verpasst.
;; Liefert T bei mindestens einem Treffer.
;; ACHTUNG: bewusst NICHT bereichsbezogen - deshalb nur fuer die
;; Ganz-Zeichnung-Diagnose (LEGCHECK) verwenden, nicht fuer LEGENDEN!
(defun LEG:ss-on-layer (lay / ss)
  (setq ss (vl-catch-all-apply 'ssget
             (list "_X" (list (cons 8 (strcat lay ",*|" lay))))))
  (if (or (null ss) (vl-catch-all-error-p ss))
    nil
    (> (sslength ss) 0))
)

;; Status EINES Layers ueber die GESAMTE Zeichnung (nur LEGCHECK):
;;   'OBJ = Objekte gefunden | 'TAB = nur Layertabelle | nil = fehlt
(defun LEG:laystatus (lay used laytab)
  (cond
    ((LEG:in-used lay used)   'OBJ)
    ((LEG:ss-on-layer lay)    'OBJ)
    ((LEG:in-used lay laytab) 'TAB)
    (t nil))
)

;; Bester Status ueber eine Layer-Spezifikation, GESAMTE Zeichnung
;; (nur LEGCHECK; OBJ schlaegt TAB)
(defun LEG:anystatus (spec used laytab / best st l)
  (setq best nil)
  (foreach l (LEG:layspec->list spec)
    (setq st (LEG:laystatus l used laytab))
    (cond
      ((eq st 'OBJ) (setq best 'OBJ))
      ((and (eq st 'TAB) (null best)) (setq best 'TAB))))
  best
)

;; Status EINER Layer-Spezifikation NUR bezogen auf den vom Anwender
;; ausgewaehlten Bereich ("used" = Ergebnis von
;; LEG:build-usedlayers-from-selection). Bewusst OHNE Fallback auf die
;; Layertabelle oder eine zeichnungsweite ssget-Suche - genau das war
;; die Ursache dafuer, dass planfremde Layer in der Legende landeten.
(defun LEG:area-anystatus (spec used / best l)
  (setq best nil)
  (foreach l (LEG:layspec->list spec)
    (if (LEG:in-used l used) (setq best 'OBJ)))
  best
)

;; Layer fuer den Beispielstrich (KLP): bevorzugt einen mit Objekten
;; im ausgewaehlten Bereich, sonst den ersten der Liste.
(defun LEG:spec-bestlayer (spec used / best l)
  (setq best nil)
  (foreach l (LEG:layspec->list spec)
    (if (and (null best) (LEG:in-used l used)) (setq best l)))
  (if (null best) (setq best (car (LEG:layspec->list spec))))
  best
)

;; Vorhandene S_-Layer, die in KEINER *LEG-MAP*-Zeile zugeordnet sind
;; (XRef-Praefixe werden abgeschnitten; *LEG-LAYER* wird ignoriert).
;; "namelist" kann sowohl die volle Layertabelle (LEGCHECK) als auch
;; die Bereichs-Layerliste (LEGENDEN) sein.
(defun LEG:sg-unmapped (namelist / mapped res nm base p pair l)
  (setq mapped '())
  (foreach pair *LEG-MAP*
    (foreach l (LEG:layspec->list (cadr pair))
      (setq mapped (cons (strcase l) mapped))))
  (setq res '())
  (foreach nm namelist
    (setq base nm)
    (while (setq p (vl-string-search "|" base))
      (setq base (substr base (+ 2 p))))
    (if (and (wcmatch base "S_*")
             (/= base (strcase *LEG-LAYER*))
             (not (member base mapped))
             (not (member base res)))
      (setq res (cons base res))))
  (if res (acad_strlsort res) res)
)

;;; ---------------- BEREICHSAUSWAHL (NEU 08/2026) -----------------------

;; Layer + zugehoerige Attribut-/Unterobjekte EINES Objekts einsammeln.
;; Rekursiv: bei INSERT/MINSERT/DIMENSION wird zusaetzlich in die
;; referenzierte Blockdefinition hineingescannt (deckt verschachtelte
;; Bloecke UND geladene XRefs ab), bei Attributen wird bis SEQEND
;; mitgelaufen. *LEG-BLKSEEN* verhindert Mehrfach-Scans derselben
;; Blockdefinition (Performance bei vielen gleichen Symbolen).
(defun LEG:collect-ename-layers (en used / ed lay btype bname ben)
  (setq ed (entget en))
  (if ed
    (progn
      (setq lay (cdr (assoc 8 ed)))
      (if lay
        (progn
          (setq lay (strcase lay))
          (if (not (member lay used)) (setq used (cons lay used)))))
      (setq btype (cdr (assoc 0 ed)))
      (if (member btype '("INSERT" "MINSERT" "DIMENSION"))
        (progn
          (setq bname (cdr (assoc 2 ed)))
          (if (and bname (/= bname "")) (setq used (LEG:collect-block-layers bname used)))
          (if (and (assoc 66 ed) (= (cdr (assoc 66 ed)) 1))
            (progn
              (setq ben (entnext en))
              (while (and ben (/= (cdr (assoc 0 (entget ben))) "SEQEND"))
                (setq used (LEG:collect-ename-layers ben used))
                (setq ben (entnext ben)))))))))
  used
)

;; Alle Layer aus einer Blockdefinition (rekursiv, inkl. verschachtelter
;; Bloecke/XRefs) einsammeln.
(defun LEG:collect-block-layers (bname used / bnU rec en)
  (setq bnU (strcase bname))
  (if (member bnU *LEG-BLKSEEN*)
    used
    (progn
      (setq *LEG-BLKSEEN* (cons bnU *LEG-BLKSEEN*))
      (setq rec (tblobjname "BLOCK" bname))
      (if rec
        (progn
          (setq en (entnext rec))
          (while en
            (setq used (LEG:collect-ename-layers en used))
            (setq en (entnext en)))))
      used))
)

;; Layer aus einem Auswahlsatz (= vom Anwender gewaehlter Projektbereich)
;; ermitteln, inkl. verschachtelter Bloecke/XRefs/Attribute.
;; Liefert Liste UPPERCASE Layernamen.
(defun LEG:build-usedlayers-from-selection (ss / used n i en)
  (setq used '() *LEG-BLKSEEN* '())
  (if ss
    (progn
      (setq n (sslength ss) i 0)
      (while (< i n)
        (setq en (ssname ss i))
        (setq used (LEG:collect-ename-layers en used))
        (setq i (1+ i)))))
  used
)

;; Fragt den Anwender nach dem Projektbereich (Objektauswahl - Fenster,
;; Schneidenfenster oder Einzelauswahl sind alle moeglich, da normales
;; ssget). Liefert den Auswahlsatz oder nil bei Abbruch/leerer Auswahl.
(defun LEG:pick-bereich ( / ss )
  (princ "\nBereich fuer die Legende auswaehlen (Fenster/Schneiden/Objekte).")
  (setq ss (ssget))
  (cond
    ((and ss (> (sslength ss) 0))
     (princ (strcat "\n" (itoa (sslength ss)) " Objekt(e) im Bereich ausgewaehlt."))
     ss)
    (t
     (princ "\nKein Bereich ausgewaehlt - Befehl abgebrochen.")
     nil))
)

;; Neues ObjectDBX-Dokument (versionsunabhaengig)
(defun LEG:newdbx ( / app ver doc r )
  (setq app (vlax-get-acad-object)
        ver (itoa (atoi (getvar "ACADVER"))))
  (foreach pid (list (strcat "ObjectDBX.AxDbDocument." ver)
                     "ObjectDBX.AxDbDocument")
    (if (null doc)
      (progn
        (setq r (vl-catch-all-apply
                  'vla-getinterfaceobject (list app pid)))
        (if (not (vl-catch-all-error-p r)) (setq doc r)))))
  doc
)

;; ObjectDBX-Dokument fuer einen Pfad oeffnen -> geoeffnetes doc oder nil.
;; Letzte Fehlermeldung landet in *LEG-LASTERR* (Diagnose).
(defun LEG:dbxopen (path / dbx r)
  (setq dbx (LEG:newdbx))
  (cond
    ((null dbx)
     (setq *LEG-LASTERR* "ObjectDBX-Server nicht verfuegbar")
     nil)
    (t
     (setq r (vl-catch-all-apply 'vla-open (list dbx path)))
     (if (vl-catch-all-error-p r)
       (progn
         (setq *LEG-LASTERR* (vl-catch-all-error-message r))
         (vl-catch-all-apply 'vlax-release-object (list dbx))
         nil)
       dbx)))
)

;; Lokale Kopie der Quelle nach %TEMP% -> Pfad der Kopie oder nil
(defun LEG:localcopy (src / d dst)
  (setq d (getenv "TEMP"))
  (if (or (null d)(= d "")) (setq d (getenv "TMP")))
  (if (or (null d)(= d "")) (setq d "C:\\Temp"))
  (setq dst (strcat d "\\LEG_QUELLE_TMP.dwg"))
  (if (findfile dst)(vl-catch-all-apply 'vl-file-delete (list dst)))
  (vl-catch-all-apply 'vl-file-copy (list src dst))
  (if (findfile dst) dst nil)
)

;; Fallback ohne COM-Server: Quelldatei per InsertBlock laden,
;; eingefuegte Referenz sofort wieder loeschen -> Blockdefs bleiben lokal.
;; Holt alle Defs, die in der Quelle im Modellbereich referenziert sind.
(defun LEG:import-via-insert (src space / oldatt ref)
  (setq oldatt (getvar "ATTREQ"))
  (setvar "ATTREQ" 0)
  (setq ref (vl-catch-all-apply 'vla-insertblock
              (list space (vlax-3d-point 1.0e8 1.0e8 0.0)
                    src 1.0 1.0 1.0 0.0)))
  (if (and ref (not (vl-catch-all-error-p ref)))
    (vl-catch-all-apply 'vla-delete (list ref)))
  (setvar "ATTREQ" oldatt)
  (princ)
)

;; Existiert benanntes Element in einer VLA-Collection?
(defun LEG:hasitem (coll name / r)
  (setq r (vl-catch-all-apply 'vla-item (list coll name)))
  (and r (not (vl-catch-all-error-p r)))
)

;; Layer sicherstellen (anlegen falls fehlt); gibt Namen oder nil zurueck
(defun LEG:ensurelayer (doc name)
  (if (and name (> (strlen name) 0))
    (progn
      (if (not (LEG:hasitem (vla-get-layers doc) name))
        (vl-catch-all-apply 'vla-add (list (vla-get-layers doc) name)))
      name)
    nil)
)

;; Safearray (vbObject) aus Objektliste
(defun LEG:objarr (lst / sa)
  (setq sa (vlax-make-safearray vlax-vbObject (cons 0 (1- (length lst)))))
  (vlax-safearray-fill sa lst)
  sa
)

;; vla-GetBoundingBox -> (min-list max-list)
(defun LEG:bbox (obj / mn mx)
  (vla-getboundingbox obj 'mn 'mx)
  (list (vlax-safearray->list mn) (vlax-safearray->list mx))
)

;; Textstil bestimmen (Fallback auf aktuellen)
(defun LEG:style (doc)
  (if (and *LEG-STYLE* (> (strlen *LEG-STYLE*) 0)
           (LEG:hasitem (vla-get-textstyles doc) *LEG-STYLE*))
    *LEG-STYLE*
    (getvar "TEXTSTYLE"))
)

;;; ===================== TEIL 1: SCHUTZGEBIETE =========================
;; ss = vom Anwender vorher ausgewaehlter Projektbereich (Auswahlsatz).
(defun LEG:do-schutzgebiete ( ss / *error* acad doc space style oldclayer dbx
                      pair bn needed objs toplace missing failed srcuse
                      used st nobj unmapped x
                      base bx by cy maxw rows centery
                      blkref bb mn mx w h cnt mt row )

  (defun *error* (m)
    (if oldclayer (vl-catch-all-apply 'setvar (list "CLAYER" oldclayer)))
    (if dbx (vl-catch-all-apply 'vlax-release-object (list dbx)))
    (if (and m (not (wcmatch (strcase m) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\nFehler: " m)))
    (princ)
  )

  (setq *LEG-LASTERR* nil)
  (setq acad  (vlax-get-acad-object)
        doc   (vla-get-activedocument acad)
        space (vla-get-block (vla-get-activelayout doc))
        style (LEG:style doc))

  ;; 1) Belegte Layer NUR im ausgewaehlten Bereich ermitteln.
  (setq used (LEG:build-usedlayers-from-selection ss))
  (setq needed '() nobj 0)
  (foreach pair *LEG-MAP*
    (setq st (LEG:area-anystatus (cadr pair) used))
    (if (eq st 'OBJ)
      (setq needed (cons pair needed) nobj (1+ nobj))))
  (setq needed (reverse needed))

  (if (null needed)
    (progn
      (princ "\nIm ausgewaehlten Bereich ist keiner der definierten Schutzgebiets-Layer belegt - keine Legende erstellt.")
      (princ "\n(Tipp: 'LEGCHECK' zeigt, welche Layer in der GESAMTEN Zeichnung erkannt werden.)")
      (exit)))
  (princ (strcat "\n" (itoa nobj) " belegte(r) Layer im ausgewaehlten Bereich gefunden."))

  ;; Quelldatei pruefen
  (if (not (findfile *LEG-SRC*))
    (progn
      (princ (strcat "\nQuelldatei nicht gefunden / Laufwerk nicht erreichbar:\n  " *LEG-SRC*))
      (exit)))

  ;; 2) Quelle zugaenglich machen: lokale Kopie (umgeht Sperren/Netz)
  (setq srcuse (LEG:localcopy *LEG-SRC*))
  (if (null srcuse)(setq srcuse *LEG-SRC*))

  ;; 3) ObjectDBX oeffnen: erst Kopie, dann Original
  (setq dbx (LEG:dbxopen srcuse))
  (if (and (null dbx)(/= srcuse *LEG-SRC*))
    (setq dbx (LEG:dbxopen *LEG-SRC*)))

  (setq objs '() toplace '() missing '())

  (cond
    ;; ===== Weg A: ObjectDBX verfuegbar =====
    (dbx
     (foreach pair needed
       (setq bn (car pair))
       (cond
         ((LEG:hasitem (vla-get-blocks doc) bn)
          (setq toplace (cons pair toplace)))
         ((LEG:hasitem (vla-get-blocks dbx) bn)
          (setq objs    (cons (vla-item (vla-get-blocks dbx) bn) objs)
                toplace (cons pair toplace)))
         (t (setq missing (cons bn missing)))))
     (setq toplace (reverse toplace)
           missing (reverse missing))
     (if objs
       (vla-copyobjects dbx (LEG:objarr objs) (vla-get-blocks doc)))
     (vlax-release-object dbx)(setq dbx nil))

    ;; ===== Weg B: ObjectDBX nicht moeglich -> nativer INSERT-Fallback =====
    (t
     (princ "\nObjectDBX nicht moeglich")
     (if *LEG-LASTERR* (princ (strcat " (" *LEG-LASTERR* ")")))
     (princ " - nutze INSERT-Fallback ...")
     (LEG:import-via-insert srcuse space)
     (foreach pair needed
       (setq bn (car pair))
       (if (LEG:hasitem (vla-get-blocks doc) bn)
         (setq toplace (cons pair toplace))
         (setq missing (cons bn missing))))
     (setq toplace (reverse toplace)
           missing (reverse missing)))
  )

  ;; temporaere Kopie wieder entfernen
  (if (and srcuse (/= srcuse *LEG-SRC*) (findfile srcuse))
    (vl-catch-all-apply 'vl-file-delete (list srcuse)))

  (if (null toplace)
    (progn
      (if missing
        (progn
          (princ "\nKein Block konnte geladen werden:")
          (foreach x missing (princ (strcat "\n  - " x)))))
      (if *LEG-LASTERR*
        (princ (strcat "\n(ObjectDBX-Meldung: " *LEG-LASTERR* ")")))
      (princ "\nKeine Legende erstellt.")
      (exit)))

  ;; 4) Einfuegepunkt (obere linke Ecke)
  (setq base (getpoint "\nEinfuegepunkt fuer Legende (obere linke Ecke): "))
  (if (null base)(progn (princ "\nAbgebrochen.")(exit)))
  (setq base (trans base 1 0)
        bx (car base)
        by (cadr base))

  ;; Legendenlayer setzen
  (setq oldclayer (getvar "CLAYER"))
  (if (LEG:ensurelayer doc *LEG-LAYER*)
    (vl-catch-all-apply 'setvar (list "CLAYER" *LEG-LAYER*)))

  ;; Symbole platzieren + vermessen + oben-links ausrichten
  (setq cy by maxw 0.0 rows '() cnt 0 failed '())
  (foreach pair toplace
    (setq bn (car pair))
    (setq blkref (vl-catch-all-apply 'vla-insertblock
                   (list space (vlax-3d-point 0.0 0.0 0.0)
                         bn 1.0 1.0 1.0 0.0)))
    (if (vl-catch-all-error-p blkref)
      (setq failed (cons bn failed))
      (progn
        (setq bb (LEG:bbox blkref)
              mn (car bb) mx (cadr bb)
              w  (- (car mx) (car mn))
              h  (- (cadr mx) (cadr mn)))
        ;; aktuelle obere-linke Ecke -> Ziel obere-linke Ecke
        (vla-move blkref
          (vlax-3d-point (car mn) (cadr mx) 0.0)
          (vlax-3d-point bx cy 0.0))
        (if (> w maxw)(setq maxw w))
        (setq centery (- cy (/ h 2.0)))
        (setq rows (cons (list centery bn) rows))
        (setq cy  (- cy h *LEG-ROWGAP*))
        (setq cnt (1+ cnt)))))
  (setq rows (reverse rows))

  ;; Beschriftung rechts daneben (vertikal mittig zum Symbol)
  (foreach row rows
    (setq centery (car row)
          bn      (cadr row)
          mt (vla-addmtext space
               (vlax-3d-point (+ bx maxw *LEG-TXTGAP*) centery 0.0) 0.0 bn))
    (vl-catch-all-apply 'vla-put-stylename (list mt style))
    (vl-catch-all-apply 'vla-put-height (list mt *LEG-TXTH*))
    (vla-put-attachmentpoint mt 4) ;; 4 = acAttachmentPointMiddleLeft
    (vla-put-insertionpoint mt
      (vlax-3d-point (+ bx maxw *LEG-TXTGAP*) centery 0.0)))

  ;; Layer zuruecksetzen
  (vl-catch-all-apply 'setvar (list "CLAYER" oldclayer))
  (setq oldclayer nil)

  ;; Hinweise
  (if missing
    (progn
      (princ (strcat "\n\nNicht in Quelldatei gefunden (" (itoa (length missing)) "):"))
      (foreach x missing (princ (strcat "\n  - " x)))))
  (if failed
    (progn
      (princ (strcat "\n\nKonnten nicht eingefuegt werden (" (itoa (length failed)) "):"))
      (foreach x failed (princ (strcat "\n  - " x)))))

  (setq unmapped (LEG:sg-unmapped used))
  (if unmapped
    (progn
      (princ "\n\nHinweis - im Bereich vorhandene S_-Layer OHNE Zuordnung in *LEG-MAP*:")
      (foreach x unmapped (princ (strcat "\n  - " x)))))

  (princ (strcat "\n\nLegende mit " (itoa cnt) " Eintrag/Eintraegen erstellt."))
  (princ)
)

;;; ===================== TEIL 2: KLP (Strich + Text) ===================
;; ss = vom Anwender vorher ausgewaehlter Projektbereich (Auswahlsatz).
(defun LEG:do-klp ( ss / *error* acad doc space style needed used
                      st nobj x pair lay lbl
                      base bx by cy cnt ln mt txtlay xt )

  (defun *error* (m)
    (if (and m (not (wcmatch (strcase m) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\nFehler: " m)))
    (princ)
  )

  (setq acad  (vlax-get-acad-object)
        doc   (vla-get-activedocument acad)
        space (vla-get-block (vla-get-activelayout doc))
        style (LEG:style doc))

  ;; belegte Layer NUR im ausgewaehlten Bereich ermitteln.
  (setq used (LEG:build-usedlayers-from-selection ss))
  (setq needed '() nobj 0)
  (foreach pair *LEG-KLP-MAP*
    (setq st (LEG:area-anystatus (car pair) used))
    (if (eq st 'OBJ)
      (setq needed (cons pair needed) nobj (1+ nobj))))
  (setq needed (reverse needed))

  (if (null needed)
    (progn
      (princ "\nIm ausgewaehlten Bereich ist keiner der KLP-Layer (Versorger) belegt - keine Legende erstellt.")
      (princ "\n(Tipp: 'LEGCHECK' zeigt, welche Layer in der GESAMTEN Zeichnung erkannt werden.)")
      (exit)))
  (princ (strcat "\n" (itoa nobj) " belegte(r) Versorger-Layer im ausgewaehlten Bereich gefunden."))

  ;; Einfuegepunkt (obere linke Ecke)
  (setq base (getpoint "\nEinfuegepunkt fuer Legende (obere linke Ecke): "))
  (if (null base)(progn (princ "\nAbgebrochen.")(exit)))
  (setq base (trans base 1 0)
        bx (car base)
        by (cadr base))

  ;; Text-Layer sicherstellen (Striche bleiben auf ihrem Fachlayer!)
  (setq txtlay (LEG:ensurelayer doc *LEG-KLP-LAYER*))

  ;; Zeilen zeichnen
  (setq cy by cnt 0)
  (foreach pair needed
    (setq lay (LEG:spec-bestlayer (car pair) used)
          lbl (cadr pair))

    ;; 32-Einheiten-Strich auf dem Fachlayer, Eigenschaften VONLAYER
    (setq ln (vla-addline space
               (vlax-3d-point bx cy 0.0)
               (vlax-3d-point (+ bx *LEG-KLP-LEN*) cy 0.0)))
    (vl-catch-all-apply 'vla-put-layer         (list ln lay))
    (vl-catch-all-apply 'vla-put-color         (list ln 256)) ;; BYLAYER
    (vl-catch-all-apply 'vla-put-linetype      (list ln "ByLayer"))
    (vl-catch-all-apply 'vla-put-lineweight    (list ln -1))  ;; BYLAYER
    (vl-catch-all-apply 'vla-put-linetypescale (list ln 1.0))

    ;; Text rechts daneben, vertikal mittig zum Strich
    (setq xt (+ bx *LEG-KLP-LEN* *LEG-KLP-TXTGAP*))
    (setq mt (vla-addmtext space
               (vlax-3d-point xt cy 0.0) 0.0
               (strcat *LEG-KLP-PREFIX* lbl)))
    (vl-catch-all-apply 'vla-put-stylename (list mt style))
    (vl-catch-all-apply 'vla-put-height    (list mt *LEG-KLP-TXTH*))
    (vla-put-attachmentpoint mt 4) ;; 4 = acAttachmentPointMiddleLeft
    (vla-put-insertionpoint mt (vlax-3d-point xt cy 0.0))
    (if txtlay (vl-catch-all-apply 'vla-put-layer (list mt txtlay)))

    (setq cy  (- cy *LEG-KLP-ROWGAP*)
          cnt (1+ cnt)))

  (princ (strcat "\n\nKLP-Legende mit " (itoa cnt) " Eintrag/Eintraegen erstellt."))
  (princ)
)

;;; ========================= DIAGNOSE ==================================
;; LEGCHECK bewertet bewusst die GESAMTE Zeichnung (kein Bereich), damit
;; man sehen kann, was ueberall vorkommt bzw. was in *LEG-MAP* fehlt.
(defun c:LEGCHECK ( / used laytab n1 n2 st tag unmapped pair x )
  (princ "\n=== LEGCHECK (gesamte Zeichnung) ===")
  (setq used   (LEG:build-usedlayers)
        laytab (LEG:build-layertab))
  (princ (strcat "\nLayer in der Zeichnung: " (itoa (length laytab))
                 "  |  davon per Objekt-Scan belegt: " (itoa (length used))))
  (princ "\nStatus: [OBJ] Objekte gefunden | [TAB] nur Layertabelle | [ - ] Layer fehlt")
  (princ "\nHinweis: LEGENDEN selbst arbeitet bereichsbezogen (Bereichsauswahl vor der")
  (princ "\nLegendenerstellung) - hier siehst du den Belegt-Status ueber die ganze Zeichnung.")

  (setq n1 0)
  (princ "\n\n-- Schutzgebiete (Layer) --")
  (foreach pair *LEG-MAP*
    (setq st  (LEG:anystatus (cadr pair) used laytab)
          tag (cond ((eq st 'OBJ) "[OBJ]")
                    ((eq st 'TAB) "[TAB]")
                    (t            "[ - ]")))
    (if (or (eq st 'OBJ) (and *LEG-SG-TABOK* (eq st 'TAB)))
      (setq n1 (1+ n1)))
    (princ (strcat "\n  " tag " " (LEG:spec->string (cadr pair)))))
  (princ (strcat "\n  => " (itoa n1) " kaemen (zeichnungsweit) in Frage"
                 (if *LEG-SG-TABOK*
                   "  (OBJ + TAB zaehlen)"
                   "  (nur OBJ zaehlt)")))

  (setq n2 0)
  (princ "\n\n-- KLP (Layer) --")
  (foreach pair *LEG-KLP-MAP*
    (setq st  (LEG:anystatus (car pair) used laytab)
          tag (cond ((eq st 'OBJ) "[OBJ]")
                    ((eq st 'TAB) "[TAB]")
                    (t            "[ - ]")))
    (if (or (eq st 'OBJ) (and *LEG-KLP-TABOK* (eq st 'TAB)))
      (setq n2 (1+ n2)))
    (princ (strcat "\n  " tag " " (LEG:spec->string (car pair)))))
  (princ (strcat "\n  => " (itoa n2) " kaemen (zeichnungsweit) in Frage"
                 (if *LEG-KLP-TABOK*
                   "  (OBJ + TAB zaehlen)"
                   "  (nur OBJ zaehlt)")))

  (setq unmapped (LEG:sg-unmapped laytab))
  (if unmapped
    (progn
      (princ "\n\n-- Vorhandene S_-Layer OHNE Zuordnung in *LEG-MAP* --")
      (foreach x unmapped (princ (strcat "\n  " x)))))
  (princ)
)

;;; ========================= BEFEHL / DISPATCH =========================
(defun c:LEGENDEN ( / m ss )
  ;; 1) Projektbereich VORHER auswaehlen - nur Layer mit Objekten in
  ;;    diesem Bereich kommen (sofern in *LEG-MAP*/*LEG-KLP-MAP*
  ;;    eingetragen) in die Legende.
  (setq ss (LEG:pick-bereich))
  (if ss
    (progn
      (initget "KLP Schutzgebiete")
      (setq m (getkword "\nLegende erstellen fuer [KLP/Schutzgebiete] <Schutzgebiete>: "))
      (cond
        ((= m "KLP")           (LEG:do-klp ss))
        ((= m "Schutzgebiete") (LEG:do-schutzgebiete ss))
        (t                     (LEG:do-schutzgebiete ss)))) ;; Enter = Default
    (princ))
  (princ)
)

;; Kurzbefehl
(defun c:LEG () (c:LEGENDEN))

(princ "\nLEGENDEN.lsp geladen.  Befehl: LEGENDEN  (Kurz: LEG)  |  Diagnose: LEGCHECK")
(princ)
