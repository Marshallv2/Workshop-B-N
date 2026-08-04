;;; =====================================================================
;;;  LEGENDEN.lsp
;;;  ---------------------------------------------------------------------
;;;  Erzeugt eine Legende fuer die im gewaehlten Projektbereich belegten
;;;  Layer. Beim Aufruf wird zuerst der Bereich (Rechteck) gewaehlt, dann
;;;  die Art der Legende:
;;;
;;;    [KLP]           -> Legende "Versorgungsleitungen / Kanal":
;;;                       je belegtem Fachlayer ein 32-Einheiten-Strich
;;;                       (Farbe + Linientyp vom Layer) + Text "vorh. ..."
;;;
;;;    [Schutzgebiete] -> Legende aus Symbolbloecken (Flaechennutzung /
;;;                       Schutzgebiete) aus 01_Standard_KLP.dwg.
;;;
;;;  ERKENNUNG "belegt" (im Projektbereich):
;;;    Zuerst wird der Projektbereich per Rechteck (_C Crossing) gewaehlt.
;;;    Nur Layer, auf denen im Bereich Objekte liegen, gelangen in die
;;;    Legende. Blockinhalte (INSERT) werden rekursiv ausgewertet.
;;;    Die Layertabellen-Erkennung (Stufe TAB) ist im Bereichsmodus AUS,
;;;    damit keine Layer ausserhalb des Bereichs in die Legende rutschen.
;;;
;;;  Quelldatei-Import (Schutzgebiete) ist mehrstufig abgesichert:
;;;    1. lokale Kopie nach %TEMP% -> ObjectDBX liest die Kopie
;;;    2. Fallback: ObjectDBX direkt am Originalpfad
;;;    3. Fallback: nativer InsertBlock der Datei (ohne COM-Server)
;;;
;;;  Befehle:  LEGENDEN  (Kurz: LEG)      LEGCHECK = Diagnose
;;;            LEGCHECK zeigt je Layer:  [OBJ] Objekte im Bereich
;;;                                      [TAB] nur in Layertabelle
;;;                                      [ - ] Layer fehlt komplett
;;;
;;;  AENDERUNG 08/2026 v3:
;;;    - Projektbereich muss vor der Legende gewaehlt werden
;;;    - Layer-Erkennung nur aus Objekten im gewaehlten Bereich
;;;    - TAB-Erkennung im Bereichsmodus deaktiviert (keine Layer
;;;      ausserhalb des Bereichs mehr in der Legende)
;;;
;;;  AENDERUNG 07/2026 v2:
;;;    - Stufe 1b: zusaetzliche Direktsuche per ssget "X"
;;;    - KLP: Layertabellen-Erkennung standardmaessig EIN (nur ohne
;;;      Bereichsauswahl relevant)
;;;
;;;  WICHTIG: Datei als ANSI (Windows-1252) speichern, sonst werden
;;;  Layer-/Blocknamen mit Umlauten (z.B. FERNWAERME, ...FLAECHEN) nicht
;;;  gefunden.
;;; =====================================================================

(vl-load-com)

;;; ======================= EINSTELLUNGEN ===============================

;; ---- gemeinsam ----
(setq *LEG-STYLE*  "BUN AKG")

;; ---- Erkennung "belegt" ----
;; Im Bereichsmodus (Standard) zaehlen nur Objekte im gewaehlten
;; Rechteck. TAB-Erkennung kann fuer Diagnose (LEGCHECK ohne Bereich)
;; weiterhin genutzt werden:
(setq *LEG-SG-TABOK*  T)
(setq *LEG-KLP-TABOK* T)

;; Bereichsauswahl vor Legende (T = Pflicht, nil = gesamte Zeichnung):
(setq *LEG-AREA-REQUIRED* T)

;; ---- Schutzgebiete (Symbolbloecke) ----
(setq *LEG-SRC*    "J:\\ACAD\\Vorlagen\\01_Standard_KLP.dwg")
(setq *LEG-LAYER*  "S_LEGENDE")
(setq *LEG-TXTH*   2.5)
(setq *LEG-ROWGAP* 1.0)
(setq *LEG-TXTGAP* 2.0)

;; ---- KLP (Strich + Text) ----
(setq *LEG-KLP-LEN*    32.0)
(setq *LEG-KLP-TXTH*   2.5)
(setq *LEG-KLP-TXTGAP* 4.0)
(setq *LEG-KLP-ROWGAP* 5.0)
(setq *LEG-KLP-PREFIX* "vorh. ")
(setq *LEG-KLP-LAYER*  "LGND_KLP_0.25")

;;; ----------------- ZUORDNUNG SCHUTZGEBIETE: BLOCK -> LAYER -----------
(setq *LEG-MAP*
  '(("ABSCHNITT_AESTE"             "S_DWG_ABSCHNITTEAESTE")
    ("BIOSPHAERENRESERVAT"         "S_BIOSPHAERENRESERVAT")
    ("BIOTOPKATASTERS"             "S_DWG_BIOTOPKATASTER")
    ("BIOTOPSVERBUNDFLAECHEN"      "S_DWG_BIOTOPVERBUNDFLAECHEN_FARB")
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
    ("NATURPARKS"                  ("S_DWG_NATURPARK" "S_DWG_NATURPARKE"))
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
   )
)

;;; ----------------- ZUORDNUNG KLP: LAYER -> BEZEICHNUNG ---------------
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
    ("BVER_AUSA"                      "Aussparung (AUSA)")
   )
)

;;; ======================= HILFSFUNKTIONEN =============================

;; Projektbereich per Rechteck waehlen -> Auswahlsatz oder nil
(defun LEG:get-area-ss ( / p1 p2 ss )
  (setq p1 (getpoint "\nErste Ecke des Projektbereichs: "))
  (if (null p1)
    nil
    (progn
      (setq p2 (getcorner p1 "\nGegenueberliegende Ecke: "))
      (if (null p2)
        nil
        (progn
          (setq ss (ssget "_C" p1 p2))
          (if (null ss)
            (progn
              (princ "\nKeine Objekte im gewaehlten Bereich gefunden.")
              nil)
            (progn
              (princ (strcat "\nProjektbereich gewaehlt - "
                             (itoa (sslength ss)) " Objekt(e) im Bereich."))
              ss))))))
)

;; Layer (UPPERCASE) in Liste eintragen, falls noch nicht vorhanden
(defun LEG:add-layer (lay used)
  (if lay
    (progn
      (setq lay (strcase lay))
      (if (member lay used) used (cons lay used)))
    used)
)

;; Alle Layer aus einer Blockdefinition rekursiv sammeln
(defun LEG:collect-block-layers (blkname used visited / blkent ed typ lay subblk)
  (if (and blkname (not (member blkname visited)))
    (progn
      (setq visited (cons blkname visited))
      (setq blkent (tblobjname "BLOCK" blkname))
      (if blkent
        (progn
          (setq blkent (entnext blkent))
          (while blkent
            (setq ed (entget blkent))
            (if ed
              (progn
                (setq typ (cdr (assoc 0 ed)))
                (if (/= typ "ENDBLK")
                  (progn
                    (setq lay (cdr (assoc 8 ed)))
                    (setq used (LEG:add-layer lay used))
                    (if (= typ "INSERT")
                      (setq used (LEG:collect-block-layers
                                    (cdr (assoc 2 ed)) used visited))))))
            (setq blkent (entnext blkent))))))
  used
)

;; Layer eines einzelnen Objekts (+ Blockinhalte bei INSERT) sammeln
(defun LEG:collect-entity-layers (en used visited / ed typ lay blkname)
  (setq ed (entget en))
  (if ed
    (progn
      (setq lay (cdr (assoc 8 ed)))
      (setq used (LEG:add-layer lay used))
      (setq typ (cdr (assoc 0 ed)))
      (if (= typ "INSERT")
        (progn
          (setq blkname (cdr (assoc 2 ed)))
          (setq used (LEG:collect-block-layers blkname used visited))))))
  used
)

;; Layerliste aus einem Bereichs-Auswahlsatz (inkl. Blockinhalte)
(defun LEG:build-usedlayers-from-ss (ss / used i)
  (setq used '())
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq used (LEG:collect-entity-layers (ssname ss i) used '()))
        (setq i (1+ i)))))
  used
)

;; Kontext fuer Layer-Erkennung: Bereich oder gesamte Zeichnung
;; Liefert Liste: (used laytab tabok area-ss)
;;   tabok = nil im Bereichsmodus (nur OBJ zaehlt)
(defun LEG:build-context (area-ss / used laytab tabok)
  (setq laytab (LEG:build-layertab))
  (if area-ss
    (progn
      (setq used  (LEG:build-usedlayers-from-ss area-ss)
            tabok nil)
      (princ (strcat "\nLayer im Projektbereich: " (itoa (length used)))))
    (progn
      (setq used  (LEG:build-usedlayers)
            tabok T)))
  (list used laytab tabok area-ss)
)

;; Liste ALLER im Plan von Objekten verwendeten Layer (gesamte Zeichnung)
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
        (setq en (entnext en))))
    (setq rec (tblnext "BLOCK" nil)))
  (if (>= cnt cap)
    (princ "\n(Hinweis: sehr grosse Zeichnung - Belegt-Scan ggf. unvollstaendig)"))
  used
)

(defun LEG:build-layertab ( / lst rec)
  (setq lst '()
        rec (tblnext "LAYER" T))
  (while rec
    (setq lst (cons (strcase (cdr (assoc 2 rec))) lst))
    (setq rec (tblnext "LAYER" nil)))
  lst
)

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

(defun LEG:layspec->list (spec)
  (if (listp spec) spec (list spec))
)

(defun LEG:spec->string (spec / s l)
  (setq s "")
  (foreach l (LEG:layspec->list spec)
    (setq s (if (= s "") l (strcat s " / " l))))
  s
)

;; Direktsuche: Objekt auf Layer im Bereich (area-ss) oder gesamt
(defun LEG:ss-on-layer (lay area-ss / ss filt i en ed)
  (setq filt (list (cons 8 (strcat lay ",*|" lay))))
  (if area-ss
    (progn
      (setq ss (ssadd) i 0)
      (while (< i (sslength area-ss))
        (setq en (ssname area-ss i)
              ed (entget en))
        (if (and ed
                 (or (= (strcase (cdr (assoc 8 ed))) (strcase lay))
                     (wcmatch (strcase (cdr (assoc 8 ed))) (strcat "*|" (strcase lay)))))
          (ssadd en ss))
        (setq i (1+ i)))
      (> (sslength ss) 0))
    (progn
      (setq ss (vl-catch-all-apply 'ssget
                 (list "_X" filt)))
      (if (or (null ss) (vl-catch-all-error-p ss))
        nil
        (> (sslength ss) 0)))))
)

(defun LEG:laystatus (lay used laytab area-ss)
  (cond
    ((LEG:in-used lay used)   'OBJ)
    ((LEG:ss-on-layer lay area-ss) 'OBJ)
    ((LEG:in-used lay laytab) 'TAB)
    (t nil))
)

(defun LEG:anystatus (spec used laytab area-ss tabok / best st l)
  (setq best nil)
  (foreach l (LEG:layspec->list spec)
    (setq st (LEG:laystatus l used laytab area-ss))
    (cond
      ((eq st 'OBJ) (setq best 'OBJ))
      ((and (eq st 'TAB) tabok (null best)) (setq best 'TAB))))
  best
)

(defun LEG:spec-bestlayer (spec used laytab / best l)
  (setq best nil)
  (foreach l (LEG:layspec->list spec)
    (if (and (null best) (LEG:in-used l used)) (setq best l)))
  (foreach l (LEG:layspec->list spec)
    (if (and (null best) (LEG:in-used l laytab)) (setq best l)))
  (if (null best) (setq best (car (LEG:layspec->list spec))))
  best
)

(defun LEG:sg-unmapped (laytab / mapped res nm base p pair l)
  (setq mapped '())
  (foreach pair *LEG-MAP*
    (foreach l (LEG:layspec->list (cadr pair))
      (setq mapped (cons (strcase l) mapped))))
  (setq res '())
  (foreach nm laytab
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

(defun LEG:localcopy (src / d dst)
  (setq d (getenv "TEMP"))
  (if (or (null d)(= d "")) (setq d (getenv "TMP")))
  (if (or (null d)(= d "")) (setq d "C:\\Temp"))
  (setq dst (strcat d "\\LEG_QUELLE_TMP.dwg"))
  (if (findfile dst)(vl-catch-all-apply 'vl-file-delete (list dst)))
  (vl-catch-all-apply 'vl-file-copy (list src dst))
  (if (findfile dst) dst nil)
)

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

(defun LEG:hasitem (coll name / r)
  (setq r (vl-catch-all-apply 'vla-item (list coll name)))
  (and r (not (vl-catch-all-error-p r)))
)

(defun LEG:ensurelayer (doc name)
  (if (and name (> (strlen name) 0))
    (progn
      (if (not (LEG:hasitem (vla-get-layers doc) name))
        (vl-catch-all-apply 'vla-add (list (vla-get-layers doc) name)))
      name)
    nil)
)

(defun LEG:objarr (lst / sa)
  (setq sa (vlax-make-safearray vlax-vbObject (cons 0 (1- (length lst)))))
  (vlax-safearray-fill sa lst)
  sa
)

(defun LEG:bbox (obj / mn mx)
  (vla-getboundingbox obj 'mn 'mx)
  (list (vlax-safearray->list mn) (vlax-safearray->list mx))
)

(defun LEG:style (doc)
  (if (and *LEG-STYLE* (> (strlen *LEG-STYLE*) 0)
           (LEG:hasitem (vla-get-textstyles doc) *LEG-STYLE*))
    *LEG-STYLE*
    (getvar "TEXTSTYLE"))
)

;;; ===================== TEIL 1: SCHUTZGEBIETE =========================
(defun LEG:do-schutzgebiete (area-ss / *error* acad doc space style oldclayer dbx
                      pair bn needed objs toplace missing failed srcuse
                      used laytab tabok ctx st nobj ntab tabl unmapped x
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

  ;; Belegte Layer im Projektbereich ermitteln
  (setq ctx    (LEG:build-context area-ss)
        used   (nth 0 ctx)
        laytab (nth 1 ctx)
        tabok  (if area-ss nil *LEG-SG-TABOK*))

  (setq needed '() nobj 0 ntab 0 tabl '())
  (foreach pair *LEG-MAP*
    (setq st (LEG:anystatus (cadr pair) used laytab area-ss tabok))
    (cond
      ((eq st 'OBJ)
       (setq needed (cons pair needed) nobj (1+ nobj)))
      ((eq st 'TAB)
       (setq needed (cons pair needed) ntab (1+ ntab)
             tabl   (cons (LEG:spec->string (cadr pair)) tabl)))))
  (setq needed (reverse needed))

  (if (null needed)
    (progn
      (princ "\nKein definierter Layer ist im Projektbereich belegt - keine Legende erstellt.")
      (princ "\n(Tipp: 'LEGCHECK' zeigt, welche Layer erkannt werden.)")
      (exit)))
  (princ (strcat "\n" (itoa (length needed)) " belegte(r) Layer im Bereich ("
                 (itoa nobj) " mit Objekten"
                 (if tabok (strcat ", " (itoa ntab) " nur ueber Layertabelle") "")
                 ")."))
  (if (and tabl tabok)
    (progn
      (princ "\n  nur ueber Layertabelle erkannt (keine Objekte in der DWG):")
      (foreach x (reverse tabl) (princ (strcat "\n    - " x)))))

  (if (not (findfile *LEG-SRC*))
    (progn
      (princ (strcat "\nQuelldatei nicht gefunden / Laufwerk nicht erreichbar:\n  " *LEG-SRC*))
      (exit)))

  (setq srcuse (LEG:localcopy *LEG-SRC*))
  (if (null srcuse)(setq srcuse *LEG-SRC*))

  (setq dbx (LEG:dbxopen srcuse))
  (if (and (null dbx)(/= srcuse *LEG-SRC*))
    (setq dbx (LEG:dbxopen *LEG-SRC*)))

  (setq objs '() toplace '() missing '())

  (cond
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

  (setq base (getpoint "\nEinfuegepunkt fuer Legende (obere linke Ecke): "))
  (if (null base)(progn (princ "\nAbgebrochen.")(exit)))
  (setq base (trans base 1 0)
        bx (car base)
        by (cadr base))

  (setq oldclayer (getvar "CLAYER"))
  (if (LEG:ensurelayer doc *LEG-LAYER*)
    (vl-catch-all-apply 'setvar (list "CLAYER" *LEG-LAYER*)))

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
        (vla-move blkref
          (vlax-3d-point (car mn) (cadr mx) 0.0)
          (vlax-3d-point bx cy 0.0))
        (if (> w maxw)(setq maxw w))
        (setq centery (- cy (/ h 2.0)))
        (setq rows (cons (list centery bn) rows))
        (setq cy  (- cy h *LEG-ROWGAP*))
        (setq cnt (1+ cnt)))))
  (setq rows (reverse rows))

  (foreach row rows
    (setq centery (car row)
          bn      (cadr row)
          mt (vla-addmtext space
               (vlax-3d-point (+ bx maxw *LEG-TXTGAP*) centery 0.0) 0.0 bn))
    (vl-catch-all-apply 'vla-put-stylename (list mt style))
    (vl-catch-all-apply 'vla-put-height (list mt *LEG-TXTH*))
    (vla-put-attachmentpoint mt 4)
    (vla-put-insertionpoint mt
      (vlax-3d-point (+ bx maxw *LEG-TXTGAP*) centery 0.0)))

  (vl-catch-all-apply 'setvar (list "CLAYER" oldclayer))
  (setq oldclayer nil)

  (if missing
    (progn
      (princ (strcat "\n\nNicht in Quelldatei gefunden (" (itoa (length missing)) "):"))
      (foreach x missing (princ (strcat "\n  - " x)))))
  (if failed
    (progn
      (princ (strcat "\n\nKonnten nicht eingefuegt werden (" (itoa (length failed)) "):"))
      (foreach x failed (princ (strcat "\n  - " x)))))

  (setq unmapped (LEG:sg-unmapped laytab))
  (if unmapped
    (progn
      (princ "\n\nHinweis - vorhandene S_-Layer OHNE Zuordnung in *LEG-MAP*:")
      (foreach x unmapped (princ (strcat "\n  - " x)))))

  (princ (strcat "\n\nLegende mit " (itoa cnt) " Eintrag/Eintraegen erstellt."))
  (princ)
)

;;; ===================== TEIL 2: KLP (Strich + Text) ===================
(defun LEG:do-klp (area-ss / *error* acad doc space style needed used laytab tabok
                      st nobj ntab tabl x pair lay lbl ctx
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

  (setq ctx    (LEG:build-context area-ss)
        used   (nth 0 ctx)
        laytab (nth 1 ctx)
        tabok  (if area-ss nil *LEG-KLP-TABOK*))

  (setq needed '() nobj 0 ntab 0 tabl '())
  (foreach pair *LEG-KLP-MAP*
    (setq st (LEG:anystatus (car pair) used laytab area-ss tabok))
    (cond
      ((eq st 'OBJ)
       (setq needed (cons pair needed) nobj (1+ nobj)))
      ((eq st 'TAB)
       (setq needed (cons pair needed) ntab (1+ ntab)
             tabl   (cons (LEG:spec->string (car pair)) tabl)))))
  (setq needed (reverse needed))

  (if (null needed)
    (progn
      (princ "\nKeiner der KLP-Layer ist im Projektbereich belegt - keine Legende erstellt.")
      (princ "\n(Tipp: 'LEGCHECK' zeigt, welche Layer erkannt werden.)")
      (exit)))
  (princ (strcat "\n" (itoa (length needed)) " belegte(r) Versorger-Layer im Bereich ("
                 (itoa nobj) " mit Objekten"
                 (if tabok (strcat ", " (itoa ntab) " nur ueber Layertabelle") "")
                 ")."))
  (if (and tabl tabok)
    (progn
      (princ "\n  nur ueber Layertabelle erkannt (keine Objekte in der DWG):")
      (foreach x (reverse tabl) (princ (strcat "\n    - " x)))))

  (setq base (getpoint "\nEinfuegepunkt fuer Legende (obere linke Ecke): "))
  (if (null base)(progn (princ "\nAbgebrochen.")(exit)))
  (setq base (trans base 1 0)
        bx (car base)
        by (cadr base))

  (setq txtlay (LEG:ensurelayer doc *LEG-KLP-LAYER*))

  (setq cy by cnt 0)
  (foreach pair needed
    (setq lay (LEG:spec-bestlayer (car pair) used laytab)
          lbl (cadr pair))

    (setq ln (vla-addline space
               (vlax-3d-point bx cy 0.0)
               (vlax-3d-point (+ bx *LEG-KLP-LEN*) cy 0.0)))
    (vl-catch-all-apply 'vla-put-layer         (list ln lay))
    (vl-catch-all-apply 'vla-put-color         (list ln 256))
    (vl-catch-all-apply 'vla-put-linetype      (list ln "ByLayer"))
    (vl-catch-all-apply 'vla-put-lineweight    (list ln -1))
    (vl-catch-all-apply 'vla-put-linetypescale (list ln 1.0))

    (setq xt (+ bx *LEG-KLP-LEN* *LEG-KLP-TXTGAP*))
    (setq mt (vla-addmtext space
               (vlax-3d-point xt cy 0.0) 0.0
               (strcat *LEG-KLP-PREFIX* lbl)))
    (vl-catch-all-apply 'vla-put-stylename (list mt style))
    (vl-catch-all-apply 'vla-put-height    (list mt *LEG-KLP-TXTH*))
    (vla-put-attachmentpoint mt 4)
    (vla-put-insertionpoint mt (vlax-3d-point xt cy 0.0))
    (if txtlay (vl-catch-all-apply 'vla-put-layer (list mt txtlay)))

    (setq cy  (- cy *LEG-KLP-ROWGAP*)
          cnt (1+ cnt)))

  (princ (strcat "\n\nKLP-Legende mit " (itoa cnt) " Eintrag/Eintraegen erstellt."))
  (princ)
)

;;; ========================= DIAGNOSE ==================================
(defun c:LEGCHECK ( / area-ss ctx used laytab tabok n1 n2 st tag unmapped pair x p1 p2 )
  (princ "\n=== LEGCHECK ===")

  (initget "Gesamt")
  (setq p1 (getpoint "\nErste Ecke des Projektbereichs oder [Gesamt] <Gesamt>: "))
  (cond
    ((or (null p1)
         (and (= (type p1) 'STR) (= (strcase p1) "GESAMT")))
     (setq area-ss nil))
    (t
     (setq p2 (getcorner p1 "\nGegenueberliegende Ecke: "))
     (if (null p2)
       (setq area-ss nil)
       (progn
         (setq area-ss (ssget "_C" p1 p2))
         (if (null area-ss)
           (progn
             (princ "\nKeine Objekte im Bereich - nutze gesamte Zeichnung.")
             (setq area-ss nil))
           (princ (strcat "\nProjektbereich gewaehlt - "
                          (itoa (sslength area-ss)) " Objekt(e).")))))))

  (setq ctx    (LEG:build-context area-ss)
        used   (nth 0 ctx)
        laytab (nth 1 ctx)
        tabok  (if area-ss nil T))

  (princ (strcat "\nModus: "
                 (if area-ss "Projektbereich" "gesamte Zeichnung")))
  (princ (strcat "\nLayer in der Zeichnung: " (itoa (length laytab))
                 "  |  davon erkannt: " (itoa (length used))))
  (princ "\nStatus: [OBJ] Objekte gefunden | [TAB] nur Layertabelle | [ - ] Layer fehlt")

  (setq n1 0)
  (princ "\n\n-- Schutzgebiete (Layer) --")
  (foreach pair *LEG-MAP*
    (setq st  (LEG:anystatus (cadr pair) used laytab area-ss tabok)
          tag (cond ((eq st 'OBJ) "[OBJ]")
                    ((eq st 'TAB) "[TAB]")
                    (t            "[ - ]")))
    (if (or (eq st 'OBJ) (and tabok (eq st 'TAB)))
      (setq n1 (1+ n1)))
    (princ (strcat "\n  " tag " " (LEG:spec->string (cadr pair)))))
  (princ (strcat "\n  => " (itoa n1) " kaemen in die Legende"
                 (if tabok "  (OBJ + TAB zaehlen)" "  (nur OBJ im Bereich)")))

  (setq n2 0)
  (princ "\n\n-- KLP (Versorger-Layer) --")
  (foreach pair *LEG-KLP-MAP*
    (setq st  (LEG:anystatus (car pair) used laytab area-ss tabok)
          tag (cond ((eq st 'OBJ) "[OBJ]")
                    ((eq st 'TAB) "[TAB]")
                    (t            "[ - ]")))
    (if (or (eq st 'OBJ) (and tabok (eq st 'TAB)))
      (setq n2 (1+ n2)))
    (princ (strcat "\n  " tag " " (LEG:spec->string (car pair)))))
  (princ (strcat "\n  => " (itoa n2) " kaemen in die Legende"
                 (if tabok "  (OBJ + TAB zaehlen)" "  (nur OBJ im Bereich)")))

  (setq unmapped (LEG:sg-unmapped laytab))
  (if unmapped
    (progn
      (princ "\n\n-- Vorhandene S_-Layer OHNE Zuordnung in *LEG-MAP* --")
      (foreach x unmapped (princ (strcat "\n  " x)))))
  (princ)
)

;;; ========================= BEFEHL / DISPATCH =========================
(defun c:LEGENDEN ( / m area-ss )
  ;; 1) Projektbereich waehlen (wenn aktiviert)
  (setq area-ss nil)
  (if *LEG-AREA-REQUIRED*
    (progn
      (setq area-ss (LEG:get-area-ss))
      (if (null area-ss)
        (progn (princ "\nAbgebrochen - kein Projektbereich gewaehlt.") (exit)))))

  ;; 2) Legendenart waehlen
  (initget "KLP Schutzgebiete")
  (setq m (getkword "\nLegende erstellen fuer [KLP/Schutzgebiete] <Schutzgebiete>: "))
  (cond
    ((= m "KLP")           (LEG:do-klp area-ss))
    ((= m "Schutzgebiete") (LEG:do-schutzgebiete area-ss))
    (t                     (LEG:do-schutzgebiete area-ss)))
  (princ)
)

(defun c:LEG () (c:LEGENDEN))

(princ "\nLEGENDEN.lsp geladen.  Befehl: LEGENDEN  (Kurz: LEG)  |  Diagnose: LEGCHECK")
(princ "\n  -> Projektbereich wird vor der Legende abgefragt.")
(princ)
