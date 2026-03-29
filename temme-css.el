;;; temme-css.el --- CSS abbreviation expansion for temme-mode -*- lexical-binding: t; -*-

;; Author: Lycomedes1814, GPT-5.4, Opus 4.6
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, editing
;; URL: https://github.com/Lycomedes1814/temme-mode

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; CSS abbreviation expansion for `temme-mode'.  Provides `temme-css-expand'
;; (bound to C-c . in `temme-mode') which expands CSS abbreviations at point.
;;
;; Examples:
;;
;;   m10                              => margin: 10px;
;;   p10-20-30-40                     => padding: 10px 20px 30px 40px;
;;   m10p                             => margin: 10%;
;;   m-10                             => margin: -10px;
;;   df                               => display: flex;
;;   posa                             => position: absolute;
;;   tac                              => text-align: center;
;;   fwb                              => font-weight: bold;
;;   c#f00                            => color: #f00;
;;   z10                              => z-index: 10;
;;   bg                               => background: ;
;;   ff                               => font-family: ;

;;; Code:

(defconst temme--css-properties
  '(;; Margin
    ("m"    . "margin")
    ("mt"   . "margin-top")
    ("mr"   . "margin-right")
    ("mb"   . "margin-bottom")
    ("ml"   . "margin-left")
    ("mi"   . "margin-inline")
    ("mis"  . "margin-inline-start")
    ("mie"  . "margin-inline-end")
    ("mb"   . "margin-bottom")
    ;; Padding
    ("p"    . "padding")
    ("pt"   . "padding-top")
    ("pr"   . "padding-right")
    ("pb"   . "padding-bottom")
    ("pl"   . "padding-left")
    ("pi"   . "padding-inline")
    ("pis"  . "padding-inline-start")
    ("pie"  . "padding-inline-end")
    ;; Width / height
    ("w"    . "width")
    ("h"    . "height")
    ("maw"  . "max-width")
    ("mah"  . "max-height")
    ("miw"  . "min-width")
    ("mih"  . "min-height")
    ;; Position
    ("pos"  . "position")
    ("t"    . "top")
    ("r"    . "right")
    ("b"    . "bottom")
    ("l"    . "left")
    ("z"    . "z-index")
    ;; Display / flex / grid
    ("d"    . "display")
    ("v"    . "visibility")
    ("ov"   . "overflow")
    ("ovx"  . "overflow-x")
    ("ovy"  . "overflow-y")
    ("fl"   . "float")
    ("cl"   . "clear")
    ("fx"   . "flex")
    ("fxd"  . "flex-direction")
    ("fxw"  . "flex-wrap")
    ("fxg"  . "flex-grow")
    ("fxs"  . "flex-shrink")
    ("fxb"  . "flex-basis")
    ("ai"   . "align-items")
    ("ac"   . "align-content")
    ("as"   . "align-self")
    ("jc"   . "justify-content")
    ("ji"   . "justify-items")
    ("js"   . "justify-self")
    ("gap"  . "gap")
    ("ord"  . "order")
    ;; Font
    ("f"    . "font")
    ("fz"   . "font-size")
    ("ff"   . "font-family")
    ("fw"   . "font-weight")
    ("fs"   . "font-style")
    ("fv"   . "font-variant")
    ;; Text
    ("ta"   . "text-align")
    ("td"   . "text-decoration")
    ("tt"   . "text-transform")
    ("ti"   . "text-indent")
    ("te"   . "text-emphasis")
    ("lh"   . "line-height")
    ("ls"   . "letter-spacing")
    ("ws"   . "white-space")
    ("whs"  . "white-space")
    ("va"   . "vertical-align")
    ("wob"  . "word-break")
    ("wow"  . "overflow-wrap")
    ;; Color / background
    ("c"    . "color")
    ("op"   . "opacity")
    ("bg"   . "background")
    ("bgc"  . "background-color")
    ("bgi"  . "background-image")
    ("bgr"  . "background-repeat")
    ("bgp"  . "background-position")
    ("bgs"  . "background-size")
    ;; Border
    ("bd"   . "border")
    ("bdt"  . "border-top")
    ("bdr"  . "border-right")
    ("bdb"  . "border-bottom")
    ("bdl"  . "border-left")
    ("bdw"  . "border-width")
    ("bds"  . "border-style")
    ("bdc"  . "border-color")
    ("bdrs" . "border-radius")
    ("ol"   . "outline")
    ;; Box
    ("bxs"  . "box-shadow")
    ("bxz"  . "box-sizing")
    ;; Transition / animation
    ("trs"  . "transition")
    ("trsd" . "transition-duration")
    ("trsp" . "transition-property")
    ("trstf" . "transition-timing-function")
    ("anim" . "animation")
    ("animn" . "animation-name")
    ("animd" . "animation-duration")
    ;; Cursor / pointer
    ("cur"  . "cursor")
    ("pe"   . "pointer-events")
    ("us"   . "user-select")
    ;; List
    ("lis"  . "list-style")
    ("list" . "list-style-type")
    ("lisp" . "list-style-position")
    ;; Content
    ("ct"   . "content")
    ;; Grid
    ("g"    . "grid")
    ("gtc"  . "grid-template-columns")
    ("gtr"  . "grid-template-rows")
    ("gta"  . "grid-template-areas")
    ("gc"   . "grid-column")
    ("gr"   . "grid-row")
    ("gcs"  . "grid-column-start")
    ("gce"  . "grid-column-end")
    ("grs"  . "grid-row-start")
    ("gre"  . "grid-row-end"))
  "Alist mapping CSS abbreviation prefixes to property names.
Entries earlier in the list take priority for ambiguous prefixes.")

(defconst temme--css-keywords
  '(;; Display
    ("dn"   . "display: none;")
    ("db"   . "display: block;")
    ("dib"  . "display: inline-block;")
    ("di"   . "display: inline;")
    ("df"   . "display: flex;")
    ("dif"  . "display: inline-flex;")
    ("dg"   . "display: grid;")
    ("dig"  . "display: inline-grid;")
    ;; Position
    ("poss" . "position: static;")
    ("posr" . "position: relative;")
    ("posa" . "position: absolute;")
    ("posf" . "position: fixed;")
    ("post" . "position: sticky;")
    ;; Float / clear
    ("fll"  . "float: left;")
    ("flr"  . "float: right;")
    ("fln"  . "float: none;")
    ("clb"  . "clear: both;")
    ("cll"  . "clear: left;")
    ("clr"  . "clear: right;")
    ;; Overflow
    ("ovh"  . "overflow: hidden;")
    ("ovs"  . "overflow: scroll;")
    ("ova"  . "overflow: auto;")
    ("ovv"  . "overflow: visible;")
    ;; Visibility
    ("vh"   . "visibility: hidden;")
    ("vv"   . "visibility: visible;")
    ;; Text
    ("tac"  . "text-align: center;")
    ("tal"  . "text-align: left;")
    ("tar"  . "text-align: right;")
    ("taj"  . "text-align: justify;")
    ("tdn"  . "text-decoration: none;")
    ("tdu"  . "text-decoration: underline;")
    ("tdl"  . "text-decoration: line-through;")
    ("ttu"  . "text-transform: uppercase;")
    ("ttl"  . "text-transform: lowercase;")
    ("ttc"  . "text-transform: capitalize;")
    ("ttn"  . "text-transform: none;")
    ;; Font
    ("fwb"  . "font-weight: bold;")
    ("fwn"  . "font-weight: normal;")
    ("fsi"  . "font-style: italic;")
    ("fsn"  . "font-style: normal;")
    ("ffs"  . "font-family: serif;")
    ("ffss" . "font-family: sans-serif;")
    ("ffm"  . "font-family: monospace;")
    ("ffc"  . "font-family: cursive;")
    ("fff"  . "font-family: fantasy;")
    ("fvsm" . "font-variant: small-caps;")
    ("fvn"  . "font-variant: normal;")
    ;; White space
    ("wsn"  . "white-space: nowrap;")
    ("wsnw" . "white-space: nowrap;")
    ("wsp"  . "white-space: pre;")
    ;; Vertical align
    ("vat"  . "vertical-align: top;")
    ("vam"  . "vertical-align: middle;")
    ("vab"  . "vertical-align: bottom;")
    ;; Flex
    ("fxdc" . "flex-direction: column;")
    ("fxdr" . "flex-direction: row;")
    ("fxdcr" . "flex-direction: column-reverse;")
    ("fxdrr" . "flex-direction: row-reverse;")
    ("fxww" . "flex-wrap: wrap;")
    ("fxwn" . "flex-wrap: nowrap;")
    ;; Align / justify
    ("aic"  . "align-items: center;")
    ("aifs" . "align-items: flex-start;")
    ("aife" . "align-items: flex-end;")
    ("ais"  . "align-items: stretch;")
    ("aib"  . "align-items: baseline;")
    ("acc"  . "align-content: center;")
    ("acfs" . "align-content: flex-start;")
    ("acfe" . "align-content: flex-end;")
    ("acsb" . "align-content: space-between;")
    ("acsa" . "align-content: space-around;")
    ("acs"  . "align-content: stretch;")
    ("asc"  . "align-self: center;")
    ("asfs" . "align-self: flex-start;")
    ("asfe" . "align-self: flex-end;")
    ("ass"  . "align-self: stretch;")
    ("asa"  . "align-self: auto;")
    ("jcc"  . "justify-content: center;")
    ("jcfs" . "justify-content: flex-start;")
    ("jcfe" . "justify-content: flex-end;")
    ("jcsb" . "justify-content: space-between;")
    ("jcsa" . "justify-content: space-around;")
    ("jcse" . "justify-content: space-evenly;")
    ("jic"  . "justify-items: center;")
    ("jis"  . "justify-items: start;")
    ("jie"  . "justify-items: end;")
    ("jist" . "justify-items: stretch;")
    ("jsc"  . "justify-self: center;")
    ("jss"  . "justify-self: start;")
    ("jse"  . "justify-self: end;")
    ("jsst" . "justify-self: stretch;")
    ("jsa"  . "justify-self: auto;")
    ;; Box sizing
    ("bxzbb" . "box-sizing: border-box;")
    ("bxzcb" . "box-sizing: content-box;")
    ;; Cursor
    ("curp" . "cursor: pointer;")
    ("curd" . "cursor: default;")
    ("cura" . "cursor: auto;")
    ;; Pointer events
    ("pen"  . "pointer-events: none;")
    ("pea"  . "pointer-events: auto;")
    ;; User select
    ("usn"  . "user-select: none;")
    ("usa"  . "user-select: auto;")
    ;; Border style
    ("bdsn" . "border-style: none;")
    ("bdss" . "border-style: solid;")
    ("bdsd" . "border-style: dashed;")
    ("bdsdt" . "border-style: dotted;")
    ;; Background
    ("bgrn" . "background-repeat: no-repeat;")
    ("bgrx" . "background-repeat: repeat-x;")
    ("bgry" . "background-repeat: repeat-y;")
    ("bgsc" . "background-size: cover;")
    ("bgsct" . "background-size: contain;")
    ;; Word break / overflow wrap
    ("wobn" . "word-break: normal;")
    ("woba" . "word-break: break-all;")
    ("wobk" . "word-break: keep-all;")
    ("wown" . "overflow-wrap: normal;")
    ("wowbw" . "overflow-wrap: break-word;")
    ;; List
    ("lisn" . "list-style: none;")
    ;; Margin/padding auto
    ("ma"   . "margin: auto;")
    ("mra"  . "margin-right: auto;")
    ("mla"  . "margin-left: auto;"))
  "Alist mapping CSS keyword abbreviations to complete declarations.")

(defconst temme--css-unitless-properties
  '("z-index" "opacity" "order" "flex-grow" "flex-shrink"
    "line-height" "font-weight")
  "CSS properties that should not receive a default unit.")

(defun temme--css-unit-suffix (char)
  "Return the CSS unit string for suffix CHAR, or nil."
  (pcase char
    (?p "%")
    (?e "em")
    (?r "rem")
    (?x "px")
    (_ nil)))

(defconst temme--css-vendor-prefixes
  '((?w . "-webkit-")
    (?m . "-moz-")
    (?s . "-ms-")
    (?o . "-o-"))
  "Alist mapping vendor letter characters to CSS vendor prefix strings.")

(defun temme--css-parse-vendor-prefix (abbrev)
  "Parse vendor prefix specification from ABBREV.
Returns (VENDORS . REST) where VENDORS is a list of vendor prefix
strings and REST is the remaining abbreviation, or nil if ABBREV
does not start with a vendor prefix."
  (when (and (> (length abbrev) 1) (eq (aref abbrev 0) ?-))
    (let* ((after-dash (substring abbrev 1))
           (dash-pos (string-match "-" after-dash)))
      (if dash-pos
          (let ((letters (substring after-dash 0 dash-pos))
                (rest (substring after-dash (1+ dash-pos))))
            (if (and (> (length letters) 0)
                     (string-match-p "\\`[wmso]+\\'" letters))
                ;; Specific vendors selected
                (let (vendors)
                  (dotimes (i (length letters))
                    (let ((prefix (cdr (assq (aref letters i)
                                             temme--css-vendor-prefixes))))
                      (when prefix (push prefix vendors))))
                  (cons (nreverse vendors) rest))
              ;; Not vendor letters — treat whole remainder as abbreviation
              (cons (mapcar #'cdr temme--css-vendor-prefixes) after-dash)))
        ;; No second dash — all vendors, rest is the abbreviation
        (cons (mapcar #'cdr temme--css-vendor-prefixes) after-dash)))))

(defun temme--css-parse-abbrev (abbrev)
  "Parse CSS abbreviation ABBREV into a declaration string or nil.
Returns nil if ABBREV is not a recognized CSS abbreviation.
Handles vendor prefix syntax: -abbrev for all vendors,
-wm-abbrev for specific vendors (w=webkit, m=moz, s=ms, o=opera).
Checks keyword table first, then matches the longest property prefix.
Bare prefixes expand to empty declarations (e.g., \"bg\" => \"background: ;\")."
  (let ((vendor-info (temme--css-parse-vendor-prefix abbrev)))
    (if vendor-info
        (let* ((vendors (car vendor-info))
               (rest (cdr vendor-info))
               (base-decl (temme--css-parse-abbrev-1 rest)))
          (when base-decl
            (let ((colon-pos (string-match ": " base-decl)))
              (when colon-pos
                (let* ((prop (substring base-decl 0 colon-pos))
                       (value-part (substring base-decl colon-pos))
                       lines)
                  (dolist (vendor vendors)
                    (push (concat vendor prop value-part) lines))
                  (push (concat prop value-part) lines)
                  (string-join (nreverse lines) "\n"))))))
      (temme--css-parse-abbrev-1 abbrev))))

(defun temme--css-parse-abbrev-1 (abbrev)
  "Parse CSS abbreviation ABBREV without vendor prefix handling.
Returns a single declaration string or nil.
Supports :VALUE syntax for literal values (e.g., \"trs:all 0.3s ease\")."
  ;; Check for :value syntax first
  (let ((colon-pos (string-match ":" abbrev)))
    (if colon-pos
        (let* ((prop-abbrev (substring abbrev 0 colon-pos))
               (raw-value (substring abbrev (1+ colon-pos)))
               (property (cdr (assoc prop-abbrev temme--css-properties))))
          (when property
            (if (string-empty-p raw-value)
                (format "%s: ;" property)
              (format "%s: %s;" property raw-value))))
      ;; No colon — check keyword table, then property prefixes
      (let ((keyword (cdr (assoc abbrev temme--css-keywords))))
        (if keyword
            keyword
          ;; Find the longest matching property prefix
          (let ((best-prop nil)
                (best-prefix-len 0))
            (dolist (entry temme--css-properties)
              (let ((prefix (car entry)))
                (when (and (string-prefix-p prefix abbrev)
                           (> (length prefix) best-prefix-len)
                           (let ((rest (substring abbrev (length prefix))))
                             (or (string-empty-p rest)
                                 (string-match-p "\\`[-0-9#]" rest))))
                  (setq best-prop (cdr entry)
                        best-prefix-len (length prefix)))))
            (when best-prop
              (let ((rest (substring abbrev best-prefix-len)))
                (if (string-empty-p rest)
                    (format "%s: ;" best-prop)
                  (let ((values (temme--css-parse-values rest best-prop)))
                    (when values
                      (format "%s: %s;" best-prop
                              (string-join values " ")))))))))))))

(defun temme--css-parse-values (str property)
  "Parse value string STR for PROPERTY into a list of formatted values.
Handles hyphen-separated multi-values, negative numbers, units, and colors."
  (let ((parts (temme--css-split-values str))
        result)
    (dolist (part parts)
      (push (temme--css-format-value part property) result))
    (nreverse result)))

(defun temme--css-split-values (str)
  "Split STR on hyphens that separate values (not negative signs).
A hyphen is a separator unless it is at the start or follows another hyphen."
  (let ((parts nil)
        (current "")
        (i 0)
        (len (length str)))
    (while (< i len)
      (let ((ch (aref str i)))
        (if (and (eq ch ?-)
                 (> (length current) 0)
                 ;; Previous char is a digit — this hyphen is a separator
                 (<= ?0 (aref current (1- (length current))))
                 (<= (aref current (1- (length current))) ?9))
            (progn
              (push current parts)
              (setq current ""))
          (setq current (concat current (string ch)))))
      (setq i (1+ i)))
    (when (> (length current) 0)
      (push current parts))
    (nreverse parts)))

(defun temme--css-format-value (val property)
  "Format a single CSS value string VAL for PROPERTY with appropriate units."
  (cond
   ;; Color: #xxx
   ((string-prefix-p "#" val) val)
   ;; Number with optional unit suffix
   ((string-match "\\`\\(-?[0-9]+\\(?:\\.[0-9]+\\)?\\)\\([a-z%]*\\)\\'" val)
    (let* ((num (match-string 1 val))
           (suffix (match-string 2 val))
           (unit (cond
                  ((not (string-empty-p suffix))
                   (or (temme--css-unit-suffix (aref suffix 0))
                       suffix))
                  ((string= num "0") "")
                  ((member property temme--css-unitless-properties) "")
                  (t "px"))))
      (concat num unit)))
   ;; Bare string (pass through)
   (t val)))

(defun temme-css-expand-string (abbrev)
  "Expand CSS abbreviation ABBREV into a declaration string, or nil."
  (temme--css-parse-abbrev abbrev))

;;; Interactive command -------------------------------------------------------

(defun temme-css-expand ()
  "Expand the CSS abbreviation at point."
  (interactive)
  (let* ((end (point))
         (start (save-excursion
                  (skip-chars-backward "a-zA-Z0-9#._%-: ")
                  (point)))
         (base-indent (save-excursion
                        (goto-char start)
                        (current-indentation)))
         (line-start (save-excursion
                       (goto-char start)
                       (line-beginning-position)))
         (insert-start (if (string-match-p
                            "\\`[[:space:]]*\\'"
                            (buffer-substring-no-properties line-start start))
                           line-start
                         start))
         (abbrev (string-trim (buffer-substring-no-properties start end))))
    (when (string-empty-p abbrev)
      (user-error "No abbreviation at point"))
    (let ((expansion (temme-css-expand-string abbrev)))
      (unless expansion
        (user-error "Unknown CSS abbreviation: %s" abbrev))
      (let* ((indent-str (make-string base-indent ?\s))
             (lines (split-string expansion "\n"))
             (indented (string-join
                        (mapcar (lambda (line) (concat indent-str line))
                                lines)
                        "\n")))
        (delete-region insert-start end)
        (goto-char insert-start)
        (insert indented)
        (backward-char)))))

(provide 'temme-css)

;;; temme-css.el ends here
