;;; temme-mode.el --- Emmet rewrite for Emacs -*- lexical-binding: t; -*-

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

;; `temme-mode' is a rewrite of emmet-mode, aiming for a clean and modern
;; codebase while implementing all the useful features of Emmet (WIP).
;;
;; Supported features include plain tags, `#id' and `.class' shorthands,
;; bracket attributes, text nodes, child/sibling/climb-up operators,
;; grouping, multipliers, item numbering, indentation-aware expansion, self-closing
;; output for void HTML elements or explicit `.../' abbreviations,
;; and built-in snippets for common patterns.
;;
;; Examples:
;;
;;   div                              => <div></div>
;;   main#app.shell                   => <main id="app" class="shell"></main>
;;   #root.card                       => default tag with id/class shorthand
;;   ul>li.item$*3                    => numbered repeated children
;;   h1.title{Hello}+p{World}         => siblings with text nodes
;;   div>section>p^aside              => climb up to add a sibling higher up
;;   div>(header>h1{Title})+p{Body}   => grouped nested layout
;;   (header+main)>p                  => children added to each group root
;;   figure>img.hero[src=cover.jpg]/  => self-closing child
;;   ul>(li>a)*2                      => repeated groups
;;
;; Built-in snippets:
;;
;;   !              => HTML5 boilerplate (doctype, html, head, body)
;;   !!!            => <!DOCTYPE html>
;;   btn            => <button></button>
;;   a:link         => <a href="https://"></a>
;;   link:css       => <link rel="stylesheet" href="" />
;;   script:src     => <script src=""></script>
;;   input:text     => <input type="text" ... />
;;   form:post      => <form action="" method="post"></form>
;;   meta:vp        => <meta name="viewport" ... />
;;   ul+            => <ul> with nested <li>
;;
;; Snippets are composable with classes, ids, attributes, and operators:
;;
;;   btn.primary{Submit}              => <button class="primary">Submit</button>
;;   div>a:link+script:src            => nested snippet siblings
;;
;; The main entry point is `temme-expand'.

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(cl-defstruct temme-node
  tag
  id
  classes
  attrs
  text
  repeat
  self-closing
  children
  group-index)

(cl-defstruct temme-fragment
  roots
  paths)

(defgroup temme nil
  "Emmet-style abbreviation expansion."
  :group 'editing)

(defcustom temme-default-tag "div"
  "Tag name used when an abbreviation starts with `#' or `.'."
  :type 'string
  :group 'temme)

(defcustom temme-indent-offset 2
  "Number of spaces to indent nested elements."
  :type 'integer
  :group 'temme)

(defface temme-preview-face
  '((t :inherit shadow :slant italic))
  "Face for expansion preview overlays."
  :group 'temme)

(defconst temme--snippets
  '(;; Tag aliases
    ("btn"           :tag "button")
    ("bq"            :tag "blockquote")
    ("fig"           :tag "figure")
    ("figc"          :tag "figcaption")
    ("pic"           :tag "picture")
    ("ifr"           :tag "iframe")
    ("emb"           :tag "embed")
    ("obj"           :tag "object")
    ("cap"           :tag "caption")
    ("colg"          :tag "colgroup")
    ("fset"          :tag "fieldset")
    ("fst"           :tag "fieldset")
    ("leg"           :tag "legend")
    ("tarea"         :tag "textarea")
    ("sect"          :tag "section")
    ("art"           :tag "article")
    ("hdr"           :tag "header")
    ("ftr"           :tag "footer")
    ("adr"           :tag "address")
    ("dlg"           :tag "dialog")
    ("str"           :tag "strong")
    ("prog"          :tag "progress")
    ("mn"            :tag "main")
    ("tem"           :tag "template")
    ("out"           :tag "output")
    ("det"           :tag "details")
    ("sum"           :tag "summary")
    ("dat"           :tag "data")
    ;; Links
    ("a:link"        :tag "a"      :attrs (("href" . "https://")))
    ("a:mail"        :tag "a"      :attrs (("href" . "mailto:")))
    ("a:tel"         :tag "a"      :attrs (("href" . "tel:+")))
    ;; Stylesheet and script
    ("link:css"      :tag "link"   :attrs (("rel" . "stylesheet") ("href" . "")))
    ("link:favicon"  :tag "link"   :attrs (("rel" . "icon") ("type" . "image/x-icon") ("href" . "favicon.ico")))
    ("script:src"    :tag "script" :attrs (("src" . "")))
    ;; Input types
    ("inp"           :tag "input"  :attrs (("type" . "text") ("name" . "") ("id" . "")))
    ("input:text"    :tag "input"  :attrs (("type" . "text") ("name" . "") ("id" . "")))
    ("input:t"       :tag "input"  :attrs (("type" . "text") ("name" . "") ("id" . "")))
    ("input:hidden"  :tag "input"  :attrs (("type" . "hidden") ("name" . "")))
    ("input:h"       :tag "input"  :attrs (("type" . "hidden") ("name" . "")))
    ("input:search"  :tag "input"  :attrs (("type" . "search") ("name" . "") ("id" . "")))
    ("input:email"   :tag "input"  :attrs (("type" . "email") ("name" . "") ("id" . "")))
    ("input:url"     :tag "input"  :attrs (("type" . "url") ("name" . "") ("id" . "")))
    ("input:password" :tag "input" :attrs (("type" . "password") ("name" . "") ("id" . "")))
    ("input:p"       :tag "input"  :attrs (("type" . "password") ("name" . "") ("id" . "")))
    ("input:date"    :tag "input"  :attrs (("type" . "date") ("name" . "") ("id" . "")))
    ("input:datetime-local" :tag "input" :attrs (("type" . "datetime-local") ("name" . "") ("id" . "")))
    ("input:month"   :tag "input"  :attrs (("type" . "month") ("name" . "") ("id" . "")))
    ("input:week"    :tag "input"  :attrs (("type" . "week") ("name" . "") ("id" . "")))
    ("input:time"    :tag "input"  :attrs (("type" . "time") ("name" . "") ("id" . "")))
    ("input:tel"     :tag "input"  :attrs (("type" . "tel") ("name" . "") ("id" . "")))
    ("input:number"  :tag "input"  :attrs (("type" . "number") ("name" . "") ("id" . "")))
    ("input:color"   :tag "input"  :attrs (("type" . "color") ("name" . "") ("id" . "")))
    ("input:checkbox" :tag "input" :attrs (("type" . "checkbox") ("name" . "") ("id" . "")))
    ("input:c"       :tag "input"  :attrs (("type" . "checkbox") ("name" . "") ("id" . "")))
    ("input:radio"   :tag "input"  :attrs (("type" . "radio") ("name" . "") ("id" . "")))
    ("input:r"       :tag "input"  :attrs (("type" . "radio") ("name" . "") ("id" . "")))
    ("input:range"   :tag "input"  :attrs (("type" . "range") ("name" . "") ("id" . "")))
    ("input:file"    :tag "input"  :attrs (("type" . "file") ("name" . "") ("id" . "")))
    ("input:submit"  :tag "input"  :attrs (("type" . "submit") ("value" . "")))
    ("input:s"       :tag "input"  :attrs (("type" . "submit") ("value" . "")))
    ("input:image"   :tag "input"  :attrs (("type" . "image") ("src" . "") ("alt" . "")))
    ("input:i"       :tag "input"  :attrs (("type" . "image") ("src" . "") ("alt" . "")))
    ("input:button"  :tag "input"  :attrs (("type" . "button") ("value" . "")))
    ("input:b"       :tag "input"  :attrs (("type" . "button") ("value" . "")))
    ("input:reset"   :tag "input"  :attrs (("type" . "reset") ("value" . "")))
    ;; Form
    ("form:get"      :tag "form"   :attrs (("action" . "") ("method" . "get")))
    ("form:post"     :tag "form"   :attrs (("action" . "") ("method" . "post")))
    ;; Media
    ("video:src"     :tag "video"  :attrs (("src" . "")))
    ("audio:src"     :tag "audio"  :attrs (("src" . "")))
    ;; Meta
    ("meta:utf"      :tag "meta"   :attrs (("http-equiv" . "Content-Type") ("content" . "text/html;charset=UTF-8")))
    ("meta:vp"       :tag "meta"   :attrs (("name" . "viewport") ("content" . "width=device-width, initial-scale=1.0")))
    ("meta:compat"   :tag "meta"   :attrs (("http-equiv" . "X-UA-Compatible") ("content" . "IE=edge")))
    ("meta:desc"     :tag "meta"   :attrs (("name" . "description") ("content" . "")))
    ("meta:kw"       :tag "meta"   :attrs (("name" . "keywords") ("content" . "")))
    )
  "Built-in abbreviation snippets.
Each entry is (NAME . PLIST) where PLIST contains :tag and optionally
:attrs (an alist of default attributes).")

(defconst temme--raw-snippets
  (let ((doc (concat
              "<!DOCTYPE html>\n"
              "<html lang=\"en\">\n"
              "<head>\n"
              "  <meta charset=\"UTF-8\" />\n"
              "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n"
              "  <title>|</title>\n"
              "</head>\n"
              "<body>\n"
              "  |\n"
              "</body>\n"
              "</html>\n")))
    `(("!" . ,doc)
      ("doc" . ,doc)
      ("!!!" . "<!DOCTYPE html>\n")
      ("ul+" . "<ul>\n  <li></li>\n</ul>\n")
      ("ol+" . "<ol>\n  <li></li>\n</ol>\n")
      ("dl+" . "<dl>\n  <dt></dt>\n  <dd></dd>\n</dl>\n")
      ("table+" . "<table>\n  <tr>\n    <td></td>\n  </tr>\n</table>\n")
      ("select+" . "<select>\n  <option value=\"\"></option>\n</select>\n")))
  "Snippets that expand to raw HTML strings.
These are only matched when the entire abbreviation is the snippet name.")

(defun temme--resolve-snippet (name)
  "Look up NAME in the snippet table and return its plist, or nil."
  (cdr (assoc name temme--snippets)))

(defconst temme-void-tags
  '("area" "base" "br" "col" "embed" "hr" "img" "input" "link"
    "meta" "param" "source" "track" "wbr")
  "HTML tags that should render without a closing tag.")

(defconst temme--lorem-words
  ["lorem" "ipsum" "dolor" "sit" "amet" "consectetur"
   "adipisicing" "elit" "ab" "accusantium" "accusamus"
   "ad" "adipisci" "alias" "aliquam" "aliquid" "animi"
   "aperiam" "architecto" "aspernatur" "assumenda" "at"
   "atque" "aut" "autem" "beatae" "blanditiis" "commodi"
   "consequatur" "consequuntur" "corporis" "corrupti"
   "culpa" "cum" "cumque" "cupiditate" "debitis" "delectus"
   "deleniti" "deserunt" "dicta" "dignissimos" "distinctio"
   "dolore" "dolorem" "doloremque" "dolores" "doloribus"
   "dolorum" "ducimus" "ea" "eaque" "earum" "eius"
   "eligendi" "enim" "error" "esse" "est" "et" "eum"
   "eveniet" "ex" "excepturi" "exercitationem" "expedita"
   "explicabo" "facere" "facilis" "fuga" "fugiat" "fugit"
   "harum" "hic" "id" "illo" "impedit" "in" "incidunt"
   "inventore" "ipsa" "ipsam" "iste" "itaque" "iure"
   "iusto" "labore" "laboriosam" "laborum" "laudantium"
   "libero" "magnam" "magni" "maiores" "maxime" "minima"
   "minus" "modi" "molestiae" "molestias" "mollitia" "nam"
   "natus" "necessitatibus" "nemo" "neque" "nesciunt"
   "nihil" "nisi" "nobis" "non" "nostrum" "nulla" "numquam"
   "obcaecati" "occaecati" "odio" "odit" "officia"
   "officiis" "omnis" "optio" "pariatur" "perferendis"
   "perspiciatis" "placeat" "porro" "possimus" "praesentium"
   "provident" "quae" "quaerat" "quam" "quas" "quasi"
   "qui" "quia" "quibusdam" "quidem" "quis" "quisquam"
   "quo" "quod" "quos" "ratione" "recusandae" "reiciendis"
   "rem" "repellat" "repellendus" "reprehenderit"
   "repudiandae" "rerum" "sapiente" "sed" "sequi"
   "similique" "sint" "soluta" "sunt" "suscipit" "tempora"
   "temporibus" "tenetur" "totam" "ullam" "unde" "ut"
   "vel" "velit" "veniam" "veritatis" "vero" "vitae"
   "voluptas" "voluptate" "voluptatem" "voluptates"
   "voluptatibus" "voluptatum"]
  "Word pool for lorem ipsum placeholder text generation.")

(defun temme--lorem-p (tag)
  "Return the word count if TAG is a lorem abbreviation, or nil."
  (when (string-match "\\`lorem\\([0-9]*\\)\\'" tag)
    (let ((n (match-string 1 tag)))
      (if (string-empty-p n) 30 (string-to-number n)))))

(defun temme--lorem-generate (count &optional offset)
  "Generate COUNT words of lorem ipsum text.
OFFSET shifts the starting position in the word pool for variety."
  (let* ((pool temme--lorem-words)
         (len (length pool))
         (start (mod (or offset 0) len))
         (words nil))
    (dotimes (i count)
      (push (aref pool (mod (+ start i) len)) words))
    (setq words (nreverse words))
    (if (= count 1)
        (concat (capitalize (car words)) ".")
      (concat (capitalize (car words))
              " "
              (mapconcat #'identity (cdr words) " ")
              "."))))

(defun temme--alnum-or-symbol-p (char)
  "Return non-nil when CHAR is valid in a tag or attribute name."
  (or (and (>= char ?a) (<= char ?z))
      (and (>= char ?A) (<= char ?Z))
      (and (>= char ?0) (<= char ?9))
      (eq char ?-)
      (eq char ?_)
      (eq char ?:)
      (eq char ?$)))

(defun temme--attr-char-p (char)
  "Return non-nil when CHAR may appear in an unquoted attribute token."
  (and char
       (not (memq char '(?\s ?\t ?\n ?\] ?= ?\" ?\')))))

(defun temme--skip-space (input pos)
  "Advance POS past ASCII whitespace in INPUT and return the new position."
  (while (and (< pos (length input))
              (memq (aref input pos) '(?\s ?\t ?\n)))
    (setq pos (1+ pos)))
  pos)

(defun temme--parse-name (input pos)
  "Parse a tag, class, or attribute name from INPUT starting at POS."
  (let ((start pos))
    (while (and (< pos (length input))
                (temme--alnum-or-symbol-p (aref input pos)))
      (setq pos (1+ pos)))
    (when (= start pos)
      (error "Expected a name"))
    (cons (substring input start pos) pos)))

(defun temme--parse-text (input pos)
  "Parse text between braces.  Nested braces are not supported."
  (let ((start (1+ pos)))
    (setq pos start)
    (while (and (< pos (length input))
                (not (eq (aref input pos) ?})))
      (setq pos (1+ pos)))
    (unless (< pos (length input))
      (error "Unterminated text block"))
    (cons (substring input start pos) (1+ pos))))

(defun temme--parse-number (input pos)
  "Parse a decimal repeat count from INPUT starting at POS."
  (let ((start pos))
    (while (and (< pos (length input))
                (<= ?0 (aref input pos))
                (<= (aref input pos) ?9))
      (setq pos (1+ pos)))
    (when (= start pos)
      (error "Expected a repeat count"))
    (cons (string-to-number (substring input start pos)) pos)))

(defun temme--parse-quoted-string (input pos)
  "Parse a quoted string value.  Escape sequences are not supported."
  (let ((quote-char (aref input pos))
        (start (1+ pos)))
    (setq pos start)
    (while (and (< pos (length input))
                (not (eq (aref input pos) quote-char)))
      (setq pos (1+ pos)))
    (unless (< pos (length input))
      (error "Unterminated quoted attribute value"))
    (cons (substring input start pos) (1+ pos))))

(defun temme--parse-attr-name (input pos)
  "Parse an attribute name from INPUT starting at POS."
  (let ((start pos))
    (while (and (< pos (length input))
                (temme--attr-char-p (aref input pos)))
      (setq pos (1+ pos)))
    (when (= start pos)
      (error "Expected an attribute name"))
    (cons (substring input start pos) pos)))

(defun temme--parse-attr-value (input pos)
  "Parse an attribute value from INPUT starting at POS."
  (setq pos (temme--skip-space input pos))
  (when (>= pos (length input))
    (error "Expected an attribute value"))
  (pcase (aref input pos)
    ((or ?\" ?\')
     (temme--parse-quoted-string input pos))
    (_
     (let ((start pos))
       (while (and (< pos (length input))
                   (temme--attr-char-p (aref input pos)))
         (setq pos (1+ pos)))
       (when (= start pos)
         (error "Expected an attribute value"))
       (cons (substring input start pos) pos)))))

(defun temme--parse-attrs (input pos)
  "Parse a bracketed attribute list from INPUT starting at POS."
  (setq pos (1+ pos))
  (let (attrs
        done)
    (while (not done)
      (setq pos (temme--skip-space input pos))
      (when (>= pos (length input))
        (error "Unterminated attribute list"))
      (when (eq (aref input pos) ?\])
        (setq pos (1+ pos))
        (setq done t))
      (unless done
        (pcase-let ((`(,name . ,next-pos) (temme--parse-attr-name input pos)))
          (setq pos (temme--skip-space input next-pos))
          (if (and (< pos (length input))
                   (eq (aref input pos) ?=))
              (pcase-let ((`(,value . ,value-pos)
                           (temme--parse-attr-value input (1+ pos))))
                (push (cons name value) attrs)
                (setq pos value-pos))
            (push (cons name t) attrs)))))
    (cons (nreverse attrs) pos)))

(defun temme--clone-node (node)
  "Deep-copy NODE and its children."
  (let ((clone (make-temme-node
                :tag (temme-node-tag node)
                :id (temme-node-id node)
                :classes (copy-sequence (temme-node-classes node))
                :attrs (copy-sequence (temme-node-attrs node))
                :text (temme-node-text node)
                :repeat (temme-node-repeat node)
                :self-closing (temme-node-self-closing node)
                :children nil
                :group-index (temme-node-group-index node))))
    (setf (temme-node-children clone)
          (mapcar #'temme--clone-node (temme-node-children node)))
    clone))

(defun temme--clone-fragment (fragment)
  "Deep-copy FRAGMENT, preserving path structure in the clone."
  ;; Clone every node, then map old→new so paths point into the new tree.
  (let ((map (make-hash-table :test #'eq)))
    (make-temme-fragment
     :roots
     (mapcar (lambda (node)
               (let ((clone (temme--clone-node node)))
                 (puthash node clone map)
                 (cl-labels ((record-children (old new)
                               (cl-mapc (lambda (old-child new-child)
                                          (puthash old-child new-child map)
                                          (record-children old-child new-child))
                                        (temme-node-children old)
                                        (temme-node-children new))))
                   (record-children node clone))
                 clone))
             (temme-fragment-roots fragment))
     :paths (mapcar (lambda (path)
                      (mapcar (lambda (node)
                                (gethash node map))
                              path))
                    (temme-fragment-paths fragment)))))

(defun temme--repeat-fragment (fragment count)
  "Return FRAGMENT repeated COUNT times as sibling roots."
  (cond
   ((<= count 0)
    (make-temme-fragment :roots nil :paths nil))
   ((= count 1)
    fragment)
   (t
    (let (roots last-path)
      (dotimes (i count)
        (let ((copy (temme--clone-fragment fragment)))
          (dolist (root (temme-fragment-roots copy))
            (setf (temme-node-group-index root) (1+ i)))
          (setq roots (append roots (temme-fragment-roots copy))
                last-path (temme-fragment-paths copy))))
      (make-temme-fragment :roots roots :paths last-path)))))

(defun temme--group-fragment (fragment)
  "Treat FRAGMENT as a group whose roots become the active paths."
  (make-temme-fragment
   :roots (temme-fragment-roots fragment)
   :paths (mapcar #'list (temme-fragment-roots fragment))))

(defun temme--path-prefix (path length)
  "Return the prefix of PATH with at most LENGTH nodes."
  (cl-subseq path 0 (max 0 (min length (length path)))))

(defun temme--attach-fragment (roots basis-paths fragment)
  "Attach FRAGMENT into ROOTS at BASIS-PATHS, returning a `temme-fragment'."
  (if basis-paths
      (let (new-paths)
        (dolist (basis-path basis-paths)
          (let ((copy (temme--clone-fragment fragment)))
            (if basis-path
                (let ((parent (car (last basis-path))))
                  (setf (temme-node-children parent)
                        (append (temme-node-children parent)
                                (temme-fragment-roots copy)))
                  (setq new-paths
                        (append new-paths
                                (mapcar (lambda (path)
                                          (append (copy-sequence basis-path) path))
                                        (temme-fragment-paths copy)))))
              (setq roots (append roots (temme-fragment-roots copy))
                    new-paths (append new-paths
                                      (temme-fragment-paths copy))))))
        (make-temme-fragment :roots roots :paths new-paths))
    (make-temme-fragment :roots (append roots (temme-fragment-roots fragment))
                         :paths (temme-fragment-paths fragment))))

(defun temme--parse-element (input pos)
  "Parse a single element abbreviation from INPUT starting at POS."
  (setq pos (temme--skip-space input pos))
  (let ((tag nil)
        (id nil)
        (classes nil)
        (attrs nil)
        (text nil)
        (repeat 1)
        (self-closing nil)
        (done nil))
    (when (and (< pos (length input))
               (temme--alnum-or-symbol-p (aref input pos)))
      (pcase-let ((`(,name . ,next-pos) (temme--parse-name input pos)))
        (setq tag name
              pos next-pos)))
    (while (and (< pos (length input)) (not done))
      (pcase (aref input pos)
        (?#
         (pcase-let ((`(,name . ,next-pos)
                      (temme--parse-name input (1+ pos))))
           (setq id name
                 pos next-pos)))
        (?.
         (pcase-let ((`(,name . ,next-pos)
                      (temme--parse-name input (1+ pos))))
           (push name classes)
           (setq pos next-pos)))
        (?\[
         (pcase-let ((`(,parsed-attrs . ,next-pos)
                      (temme--parse-attrs input pos)))
           (setq attrs (append attrs parsed-attrs)
                 pos next-pos)))
        (?{
         (pcase-let ((`(,value . ,next-pos)
                      (temme--parse-text input pos)))
           (setq text value
                 pos next-pos)))
        (?*
         (pcase-let ((`(,value . ,next-pos)
                      (temme--parse-number input (1+ pos))))
           (setq repeat value
                 pos next-pos)))
        (?/
         (setq self-closing t
               pos (1+ pos)
               done t))
        (_
         (setq pos (temme--skip-space input pos))
         (setq done t))))
    (let* ((resolved-tag (or tag temme-default-tag))
           (snippet (and tag (temme--resolve-snippet tag))))
      (when snippet
        (setq resolved-tag (plist-get snippet :tag))
        (let ((snippet-attrs (plist-get snippet :attrs)))
          (when snippet-attrs
            (setq attrs (append snippet-attrs attrs)))))
      (cons (make-temme-node :tag resolved-tag
                             :id id
                             :classes (nreverse classes)
                             :attrs attrs
                             :text text
                             :repeat repeat
                             :self-closing self-closing
                             :children nil)
            pos))))

(defun temme--parse-primary (input pos)
  "Parse a primary expression from INPUT starting at POS."
  (setq pos (temme--skip-space input pos))
  (when (>= pos (length input))
    (error "Unexpected end of abbreviation"))
  (if (eq (aref input pos) ?\()
      (pcase-let* ((`(,fragment . ,next-pos)
                    (temme--parse-expression input (1+ pos)))
                   (group-end (temme--skip-space input next-pos)))
        (unless (and (< group-end (length input))
                     (eq (aref input group-end) ?\)))
          (error "Unterminated group"))
        (setq group-end (1+ group-end))
        (setq group-end (temme--skip-space input group-end))
        (if (and (< group-end (length input))
                 (eq (aref input group-end) ?*))
            (pcase-let ((`(,count . ,repeat-pos)
                         (temme--parse-number input (1+ group-end))))
              (cons (temme--group-fragment
                     (temme--repeat-fragment fragment count))
                    repeat-pos))
          (cons (temme--group-fragment fragment) group-end)))
    (pcase-let ((`(,node . ,next-pos) (temme--parse-element input pos)))
      (cons (make-temme-fragment :roots (list node)
                                 :paths (list (list node)))
            next-pos))))

(defun temme--parse-expression (input &optional pos)
  "Parse an abbreviation expression from INPUT starting at POS."
  (setq pos (or pos 0))
  (pcase-let ((`(,first-fragment . ,next-pos)
               (temme--parse-primary input pos)))
    (let ((roots (temme-fragment-roots first-fragment))
          (current-paths (temme-fragment-paths first-fragment)))
      (setq next-pos (temme--skip-space input next-pos))
      (while (and (< next-pos (length input))
                  (not (eq (aref input next-pos) ?\))))
        (let ((basis-paths nil))
          (pcase (aref input next-pos)
            (?+
             (setq basis-paths (mapcar (lambda (path)
                                         (temme--path-prefix path
                                                             (1- (length path))))
                                       current-paths)
                   next-pos (1+ next-pos)))
            (?>
             (setq basis-paths current-paths
                   next-pos (1+ next-pos)))
            (?^
             (let ((climbs 0))
               (while (and (< next-pos (length input))
                           (eq (aref input next-pos) ?^))
                 (setq climbs (1+ climbs)
                       next-pos (1+ next-pos)))
               (setq basis-paths
                     (mapcar (lambda (path)
                               (temme--path-prefix path
                                                   (- (length path) 1 climbs)))
                             current-paths))))
            (_
             (error "Unexpected token at position %d" next-pos)))
          (pcase-let ((`(,fragment . ,new-pos)
                       (temme--parse-primary input next-pos)))
            (let ((result (temme--attach-fragment roots basis-paths fragment)))
              (setq roots (temme-fragment-roots result)
                    current-paths (temme-fragment-paths result)
                    next-pos (temme--skip-space input new-pos))))))
      (cons (make-temme-fragment :roots roots :paths current-paths)
            next-pos))))

(defun temme-parse (abbrev)
  "Parse ABBREV into a list of `temme-node' values."
  (pcase-let* ((`(,fragment . ,pos) (temme--parse-expression abbrev 0))
               (nodes (temme-fragment-roots fragment)))
    (setq pos (temme--skip-space abbrev pos))
    (unless (= pos (length abbrev))
      (error "Unexpected token at position %d" pos))
    nodes))

(defun temme--render-attrs (node)
  "Render NODE attributes into an HTML attribute string."
  (let ((id (temme-node-id node))
        (classes (copy-sequence (temme-node-classes node)))
        other-attrs)
    (dolist (attr (temme-node-attrs node))
      (pcase (car attr)
        ("id"
         (setq id (unless (eq (cdr attr) t) (cdr attr))))
        ("class"
         (when (and (cdr attr) (not (eq (cdr attr) t)))
           (setq classes
                 (append classes
                         (split-string (cdr attr) "[[:space:]]+" t)))))
        (_
         (push attr other-attrs))))
    (let (attrs)
      (when id
        (push (format " id=\"%s\"" (temme--escape-attr-value id)) attrs))
      (when classes
        (push (format " class=\"%s\""
                      (temme--escape-attr-value (string-join classes " ")))
              attrs))
      (dolist (attr (nreverse other-attrs))
        (push (if (eq (cdr attr) t)
                  (format " %s" (car attr))
                  (format " %s=\"%s\""
                          (car attr)
                          (temme--escape-attr-value (cdr attr))))
              attrs))
      (apply #'concat (nreverse attrs)))))

(defun temme--escape-text (text)
  "Escape TEXT for HTML text content."
  (setq text (string-replace "&" "&amp;" text))
  (setq text (string-replace "<" "&lt;" text))
  (string-replace ">" "&gt;" text))

(defun temme--escape-attr-value (text)
  "Escape TEXT for an HTML attribute value."
  (setq text (temme--escape-text text))
  (string-replace "\"" "&quot;" text))

(defun temme--indent-string (indent)
  "Return a string of INDENT spaces."
  (make-string (max 0 indent) ?\s))

(defun temme--substitute-numbering (string index)
  "Replace runs of `$' in STRING with INDEX, zero-padded to the run length."
  (if (null string)
      nil
    (replace-regexp-in-string
     "\\$+"
     (lambda (match)
       (format (format "%%0%dd" (length match)) index))
     string t)))

(defun temme--number-node (node index)
  "Return a shallow copy of NODE with `$' sequences replaced by INDEX."
  (make-temme-node
   :tag (temme-node-tag node)
   :id (temme--substitute-numbering (temme-node-id node) index)
   :classes (mapcar (lambda (c) (temme--substitute-numbering c index))
                    (temme-node-classes node))
   :attrs (mapcar (lambda (attr)
                    (cons (car attr)
                          (if (eq (cdr attr) t) t
                            (temme--substitute-numbering (cdr attr) index))))
                  (temme-node-attrs node))
   :text (temme--substitute-numbering (temme-node-text node) index)
   :repeat (temme-node-repeat node)
   :self-closing (temme-node-self-closing node)
   :children (temme-node-children node)))

(defun temme--render-once (node indent &optional repeat-index)
  "Render NODE once at INDENT spaces, ignoring its repeat count.
REPEAT-INDEX is the 1-based repetition index, used to vary lorem text."
  (let ((tag (temme-node-tag node))
        (text (temme-node-text node))
        (children (temme-node-children node))
        (self-closing (or (temme-node-self-closing node)
                          (member-ignore-case (temme-node-tag node)
                                              temme-void-tags)))
        (lorem-count (temme--lorem-p (temme-node-tag node))))
    (cond
     (lorem-count
      (format "%s%s\n"
              (temme--indent-string indent)
              (temme--lorem-generate
               lorem-count
               (* (1- (or repeat-index 1)) lorem-count))))
     ((and text children)
      (error "Mixed text and child elements are not supported"))
     (children
        (format "%s<%s%s>\n%s%s</%s>\n"
                (temme--indent-string indent)
                tag
                (temme--render-attrs node)
                (mapconcat
                 (lambda (child)
                   (temme-render-node child (+ indent temme-indent-offset)
                                      repeat-index))
                 children
                 "")
                (temme--indent-string indent)
                tag))
     (self-closing
      (format "%s<%s%s />\n"
              (temme--indent-string indent)
              tag
              (temme--render-attrs node)))
     (t
      (format "%s<%s%s>%s</%s>\n"
              (temme--indent-string indent)
              tag
              (temme--render-attrs node)
              (if text (temme--escape-text text) "")
              tag)))))

(defun temme-render-node (node &optional indent parent-index)
  "Render NODE into an HTML snippet.
PARENT-INDEX, when non-nil, is the repeat index of an ancestor node."
  (let ((ind (or indent 0))
        (count (max 0 (temme-node-repeat node)))
        (effective-index (or parent-index (temme-node-group-index node)))
        (parts nil))
    (dotimes (i count)
      (let ((idx (1+ i)))
        (push (temme--render-once (temme--number-node node idx) ind
                                  (if (> count 1) idx effective-index))
              parts)))
    (apply #'concat (nreverse parts))))

(defun temme-expand-string (abbrev &optional base-indent)
  "Expand ABBREV into HTML.
BASE-INDENT is the number of spaces to prepend to top-level elements."
  (let ((raw (cdr (assoc abbrev temme--raw-snippets))))
    (string-remove-suffix
     "\n"
     (if raw
         (if (and base-indent (> base-indent 0))
             (let ((prefix (temme--indent-string base-indent)))
               (replace-regexp-in-string "^\\(.\\)" (concat prefix "\\1") raw))
           raw)
       (mapconcat
        (lambda (node)
          (temme-render-node node (or base-indent 0)))
        (temme-parse abbrev)
        "")))))

;;; Field navigation ---------------------------------------------------------

(defvar-local temme--fields nil
  "List of markers at fillable positions in the last expansion.")

(defvar-local temme--field-index -1
  "Index of the currently active field.")

(defvar-local temme--field-end nil
  "Marker at the end of the expanded snippet.")

(defvar-local temme--preview-overlay nil
  "Overlay showing the current expansion preview, or nil.")

(defvar temme-field-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "TAB") #'temme-next-field)
    (define-key map (kbd "<tab>") #'temme-next-field)
    (define-key map (kbd "<backtab>") #'temme-prev-field)
    (define-key map (kbd "C-g") #'temme-exit-fields)
    map)
  "Keymap active while navigating snippet fields.")

(define-minor-mode temme-field-mode
  "Transient mode for navigating Temme snippet fields with TAB."
  :lighter " T»"
  :keymap temme-field-mode-map)

(defun temme--clear-fields ()
  "Remove all field markers and exit field mode."
  (dolist (m temme--fields)
    (set-marker m nil))
  (when temme--field-end
    (set-marker temme--field-end nil))
  (setq temme--fields nil
        temme--field-index -1
        temme--field-end nil)
  (when temme-field-mode
    (temme-field-mode -1)))

(defun temme--collect-fields (start end)
  "Find fillable positions between START and END and return markers.
Fillable positions are empty attribute values, attribute values ending
in a prefix like \":\" or \"://\", empty tag content, and explicit
field markers \"|\"."
  (let ((end-marker (copy-marker end))
        markers)
    (save-excursion
      ;; Explicit field markers: |
      (goto-char start)
      (while (search-forward "|" end-marker t)
        (delete-char -1)
        (push (copy-marker (point)) markers))
      ;; Attribute values that are empty or end with a prefix character.
      (goto-char start)
      (while (re-search-forward "=\"\\([^\"]*\\)\"" end-marker t)
        (let ((val (match-string 1)))
          (when (or (string-empty-p val)
                    (string-match-p "[:/+]\\'" val))
            (push (copy-marker (match-end 1)) markers))))
      ;; Empty tag content: ></tag>
      (goto-char start)
      (while (re-search-forward ">\\(\\)</" end-marker t)
        (push (copy-marker (match-beginning 1)) markers)))
    (set-marker end-marker nil)
    ;; Sort and deduplicate markers at the same position.
    (setq markers (sort markers #'<))
    (let ((prev nil)
          (deduped nil))
      (dolist (m markers)
        (if (and prev (= (marker-position prev) (marker-position m)))
            (set-marker m nil)
          (push m deduped)
          (setq prev m)))
      (nreverse deduped))))

(defun temme--activate-fields (start end)
  "Set up field navigation for the region START..END."
  (temme--clear-fields)
  (setq temme--fields (temme--collect-fields start end))
  (when temme--fields
    (setq temme--field-index 0
          temme--field-end (copy-marker end))
    (temme-field-mode 1)
    (goto-char (car temme--fields))))

(defun temme-next-field ()
  "Jump to the next field, or exit if on the last one."
  (interactive)
  (let ((next (1+ temme--field-index)))
    (if (>= next (length temme--fields))
        (progn
          (when temme--field-end
            (goto-char temme--field-end))
          (temme-exit-fields))
      (setq temme--field-index next)
      (goto-char (nth next temme--fields)))))

(defun temme-prev-field ()
  "Jump to the previous field."
  (interactive)
  (let ((prev (1- temme--field-index)))
    (when (>= prev 0)
      (setq temme--field-index prev)
      (goto-char (nth prev temme--fields)))))

(defun temme-exit-fields ()
  "Exit field navigation."
  (interactive)
  (temme--clear-fields))

;;; Expansion ----------------------------------------------------------------

(defun temme--preview-cleanup ()
  "Remove the active preview overlay if any."
  (when (overlayp temme--preview-overlay)
    (delete-overlay temme--preview-overlay))
  (setq temme--preview-overlay nil))

(defun temme-preview-accept ()
  "Accept the previewed expansion."
  (interactive)
  (temme--preview-cleanup)
  (temme-expand))

(defun temme-preview-dismiss ()
  "Dismiss the expansion preview."
  (interactive)
  (temme--preview-cleanup))

(defun temme-preview ()
  "Show a preview of the expansion at point in an overlay.
Press RET or TAB to accept, C-g to dismiss."
  (interactive)
  (temme--preview-cleanup)
  (pcase-let* ((`(,start . ,end)
                (if (use-region-p)
                    (cons (region-beginning) (region-end))
                  (temme--bounds-of-abbrev)))
               (line-start (save-excursion
                             (goto-char start)
                             (line-beginning-position)))
               (base-indent (save-excursion
                              (goto-char start)
                              (current-indentation)))
               (insert-start (if (string-match-p
                                  "\\`[[:space:]]*\\'"
                                  (buffer-substring-no-properties line-start start))
                                 line-start
                               start))
               (abbrev (string-trim (buffer-substring-no-properties start end))))
    (when (string-empty-p abbrev)
      (user-error "No abbreviation at point"))
    (condition-case nil
        (let* ((expansion (temme-expand-string abbrev base-indent))
               (display-text (string-remove-suffix "\n" expansion))
               (ov (make-overlay insert-start end)))
          (overlay-put ov 'display
                       (propertize display-text 'face 'temme-preview-face))
          (setq temme--preview-overlay ov)
          (set-transient-map
           (let ((map (make-sparse-keymap)))
             (define-key map (kbd "RET") #'temme-preview-accept)
             (define-key map (kbd "<return>") #'temme-preview-accept)
             (define-key map (kbd "TAB") #'temme-preview-accept)
             (define-key map (kbd "<tab>") #'temme-preview-accept)
             (define-key map (kbd "C-g") #'temme-preview-dismiss)
             map)
           (lambda () (overlayp temme--preview-overlay))
           #'temme--preview-cleanup))
      (error (message "Invalid abbreviation: %s" abbrev)))))

(defun temme--bounds-of-abbrev ()
  "Return the bounds of the abbreviation around point."
  (save-excursion
    (skip-chars-backward "^ \t\n\r")
    (let ((start (point)))
      (skip-chars-forward "^ \t\n\r")
      (cons start (point)))))

(defun temme-expand ()
  "Expand the abbreviation at point or in the active region."
  (interactive)
  (pcase-let* ((`(,start . ,end)
                (if (use-region-p)
                    (cons (region-beginning) (region-end))
                  (temme--bounds-of-abbrev)))
               (line-start (save-excursion
                             (goto-char start)
                             (line-beginning-position)))
               (base-indent (save-excursion
                              (goto-char start)
                              (current-indentation)))
               (insert-start (if (string-match-p
                                  "\\`[[:space:]]*\\'"
                                  (buffer-substring-no-properties line-start start))
                                 line-start
                               start))
               (abbrev (string-trim (buffer-substring-no-properties start end))))
    (when (string-empty-p abbrev)
      (user-error "No abbreviation at point"))
    (let ((expansion (temme-expand-string abbrev base-indent)))
      (delete-region insert-start end)
      (goto-char insert-start)
      (let ((exp-start (point)))
        (insert expansion)
        (temme--activate-fields exp-start (point))))))

;;;###autoload
(define-minor-mode temme-mode
  "Minor mode for Emmet-style expansion."
  :lighter " Temme"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c ,") #'temme-expand)
            (define-key map (kbd "C-c .") #'temme-preview)
            map))

(provide 'temme-mode)

;;; temme-mode.el ends here
