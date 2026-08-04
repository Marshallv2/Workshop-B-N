;;; =====================================================================
;;; LEGENDEN_BEREICHSFILTER.lsp
;;; Erweiterung fuer LEGENDEN.lsp
;;;
;;; Diese Datei NACH LEGENDEN.lsp laden oder den gesamten Inhalt an dessen
;;; Ende anfuegen. Sie ersetzt nur den KLP-Ablauf.
;;;
;;; KLP arbeitet danach ausschliesslich mit den Objekten im vom Anwender
;;; gewaehlten Kreuzungsfenster. Die Layertabelle wird dabei absichtlich
;;; NICHT ausgewertet: Ein ausserhalb des Bereichs vorhandener oder nur
;;; geladener Fachlayer darf keinen Legendeneintrag erzeugen.
;;; =====================================================================

(vl-load-com)

;;; Liefert die Layer der Objekte in einem Auswahlfenster. Das
;;; Kreuzungsfenster (_C) nimmt auch Objekte auf, die die Bereichsgrenze
;;; schneiden. Es werden nur Layer zurueckgegeben, die an mindestens einem
;;; Objekt im gewaehlten Bereich tatsaechlich vorkommen.
(defun LEG:select-area-layers ( / p1 p2 ss i en ed lay layers )
  (setq p1 (getpoint "\nErste Ecke des Projektbereichs: "))
  (if p1
    (progn
      (setq p2 (getcorner p1 "\nGegenueberliegende Ecke des Projektbereichs: "))
      (if p2
        (progn
          (setq ss (ssget "_C" p1 p2))
          (if ss
            (progn
              (setq i 0 layers '())
              (while (< i (sslength ss))
                (setq en  (ssname ss i)
                      ed  (entget en)
                      lay (cdr (assoc 8 ed)))
                (if (and lay (not (member (strcase lay) layers)))
                  (setq layers (cons (strcase lay) layers)))
                (setq i (1+ i)))
              (reverse layers)))))))
)

;;; Wie LEG:in-used, jedoch fuer die in der Auswahl ermittelten Layer.
;;; XRef-Layer wie "Fachmodell|BVER_TELEKOM" werden weiterhin erkannt.
(defun LEG:in-area (lay arealayers)
  (LEG:in-used lay arealayers)
)

;;; Treffer fuer einen Einzel-Layer oder eine Liste alternativer Layer.
(defun LEG:spec-in-area (spec arealayers / hit candidate)
  (setq hit nil)
  (foreach candidate (LEG:layspec->list spec)
    (if (LEG:in-area candidate arealayers)
      (setq hit t)))
  hit
)

;;; Gibt den konkreten Layernamen aus der Auswahl zurueck. Bei XRefs muss
;;; der konkrete Name verwendet werden, damit der Beispielstrich die
;;; richtigen VonLayer-Eigenschaften erhaelt.
(defun LEG:area-bestlayer (spec arealayers / candidate actual hit)
  (setq hit nil)
  (foreach candidate (LEG:layspec->list spec)
    (foreach actual arealayers
      (if (and (null hit)
               (LEG:in-area candidate (list actual)))
        (setq hit actual))))
  (if hit
    hit
    (car (LEG:layspec->list spec)))
)

;;; Erstellt die KLP-Legende aus NUR dem gewaehlten Projektbereich.
;;; Alle anderen KLP-Layer bleiben ausgeschlossen, selbst wenn sie in der
;;; Zeichnung, einer XRef oder der Layertabelle vorhanden sind.
(defun LEG:do-klp-im-bereich ( / *error* acad doc space style needed
                                  arealayers pair lay lbl base bx by cy
                                  cnt ln mt txtlay xt )
  (defun *error* (m)
    (if (and m (not (wcmatch (strcase m) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\nFehler: " m)))
    (princ))

  (setq acad  (vlax-get-acad-object)
        doc   (vla-get-activedocument acad)
        space (vla-get-block (vla-get-activelayout doc))
        style (LEG:style doc))

  ;; Kein ssget "X", kein Block-Scan und kein Layertabellen-Fallback:
  ;; Massgeblich sind allein die im Fenster selektierten Objekte.
  (setq arealayers (LEG:select-area-layers))
  (if (null arealayers)
    (progn
      (princ "\nIm gewaehlten Projektbereich wurden keine Objekte gefunden.")
      (princ "\nKeine Legende erstellt.")
      (exit)))

  ;; Die KLP-Map ist die Whitelist: Andere Layer im Bereich, auch wenn sie
  ;; Versorgungsdaten aehnlich sehen, werden nicht ungefragt aufgenommen.
  (setq needed '())
  (foreach pair *LEG-KLP-MAP*
    (if (LEG:spec-in-area (car pair) arealayers)
      (setq needed (cons pair needed))))
  (setq needed (reverse needed))

  (if (null needed)
    (progn
      (princ "\nIm Projektbereich wurden keine definierten KLP-/Versorger-Layer gefunden.")
      (princ "\nKeine Legende erstellt.")
      (exit)))

  (princ (strcat "\n" (itoa (length needed))
                 " KLP-/Versorger-Layer im Projektbereich gefunden."))

  (setq base (getpoint "\nEinfuegepunkt fuer Legende (obere linke Ecke): "))
  (if (null base)
    (progn (princ "\nAbgebrochen.") (exit)))
  (setq base (trans base 1 0)
        bx (car base)
        by (cadr base)
        txtlay (LEG:ensurelayer doc *LEG-KLP-LAYER*)
        cy by
        cnt 0)

  (foreach pair needed
    ;; Bei einer XRef wird hier z.B. "Bestand|BVER_TELEKOM" verwendet.
    (setq lay (LEG:area-bestlayer (car pair) arealayers)
          lbl (cadr pair))
    (setq ln (vla-addline space
               (vlax-3d-point bx cy 0.0)
               (vlax-3d-point (+ bx *LEG-KLP-LEN*) cy 0.0)))
    (vl-catch-all-apply 'vla-put-layer         (list ln lay))
    (vl-catch-all-apply 'vla-put-color         (list ln 256))
    (vl-catch-all-apply 'vla-put-linetype      (list ln "ByLayer"))
    (vl-catch-all-apply 'vla-put-lineweight    (list ln -1))
    (vl-catch-all-apply 'vla-put-linetypescale (list ln 1.0))

    (setq xt (+ bx *LEG-KLP-LEN* *LEG-KLP-TXTGAP*)
          mt (vla-addmtext space
               (vlax-3d-point xt cy 0.0) 0.0
               (strcat *LEG-KLP-PREFIX* lbl)))
    (vl-catch-all-apply 'vla-put-stylename (list mt style))
    (vl-catch-all-apply 'vla-put-height    (list mt *LEG-KLP-TXTH*))
    (vla-put-attachmentpoint mt 4)
    (vla-put-insertionpoint mt (vlax-3d-point xt cy 0.0))
    (if txtlay (vl-catch-all-apply 'vla-put-layer (list mt txtlay)))
    (setq cy (- cy *LEG-KLP-ROWGAP*)
          cnt (1+ cnt)))

  (princ (strcat "\n\nKLP-Legende mit " (itoa cnt)
                 " Eintrag/Eintraegen aus dem Projektbereich erstellt."))
  (princ)
)

;;; Dispatch ersetzen: KLP verwendet den Bereichsfilter; Schutzgebiete
;;; behalten den bisherigen, globalen Ablauf aus LEGENDEN.lsp.
(defun c:LEGENDEN ( / m )
  (initget "KLP Schutzgebiete")
  (setq m (getkword "\nLegende erstellen fuer [KLP/Schutzgebiete] <Schutzgebiete>: "))
  (cond
    ((= m "KLP")           (LEG:do-klp-im-bereich))
    ((= m "Schutzgebiete") (LEG:do-schutzgebiete))
    (t                     (LEG:do-schutzgebiete)))
  (princ)
)

(defun c:LEG () (c:LEGENDEN))

(princ "\nLEGENDEN-Bereichsfilter geladen. KLP fragt nun nach dem Projektbereich.")
(princ)
