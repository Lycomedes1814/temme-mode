;;; temme-mode.el --- Tiny Emmet-like expansions -*- lexical-binding: t; -*-

;; Author: Codex
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, editing

;;; Commentary:

;; `temme-mode' implements a small subset of Emmet-style abbreviations.
;; Supported syntax:
;;
;;   div               => <div></div>
;;   div#app.main      => <div id="app" class="main"></div>
;;   ul>li*2           => <ul><li></li><li></li></ul>
;;   h1.title+p{Hello} => <h1 class="title"></h1><p>Hello</p>
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
  children)

(cl-defstruct temme-fragment
  roots
  paths)

(defgroup temme nil
  "Tiny Emmet-like expansions."
  :group 'editing)

(defcustom temme-default-tag "div"
  "Tag name used when an abbreviation starts with `#' or `.'."
  :type 'string
  :group 'temme)

(defcustom temme-indent-offset 2
  "Number of spaces to indent nested elements."
  :type 'integer
  :group 'temme)

(defun temme--alnum-or-symbol-p (char)
  (or (and (>= char ?a) (<= char ?z))
      (and (>= char ?A) (<= char ?Z))
      (and (>= char ?0) (<= char ?9))
      (eq char ?-)
      (eq char ?_)
      (eq char ?:)))

(defun temme--attr-char-p (char)
  (and char
       (not (memq char '(?\s ?\t ?\n ?\] ?= ?\" ?\')))))

(defun temme--skip-space (input pos)
  (while (and (< pos (length input))
              (memq (aref input pos) '(?\s ?\t ?\n)))
    (setq pos (1+ pos)))
  pos)

(defun temme--parse-name (input pos)
  (let ((start pos))
    (while (and (< pos (length input))
                (temme--alnum-or-symbol-p (aref input pos)))
      (setq pos (1+ pos)))
    (cons (substring input start pos) pos)))

(defun temme--parse-text (input pos)
  (let ((start (1+ pos)))
    (setq pos start)
    (while (and (< pos (length input))
                (not (eq (aref input pos) ?})))
      (setq pos (1+ pos)))
    (unless (< pos (length input))
      (error "Unterminated text block"))
    (cons (substring input start pos) (1+ pos))))

(defun temme--parse-number (input pos)
  (let ((start pos))
    (while (and (< pos (length input))
                (<= ?0 (aref input pos))
                (<= (aref input pos) ?9))
      (setq pos (1+ pos)))
    (when (= start pos)
      (error "Expected a repeat count"))
    (cons (string-to-number (substring input start pos)) pos)))

(defun temme--parse-quoted-string (input pos)
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
  (let ((start pos))
    (while (and (< pos (length input))
                (temme--attr-char-p (aref input pos)))
      (setq pos (1+ pos)))
    (when (= start pos)
      (error "Expected an attribute name"))
    (cons (substring input start pos) pos)))

(defun temme--parse-attr-value (input pos)
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
  (let ((clone (make-temme-node
                :tag (temme-node-tag node)
                :id (temme-node-id node)
                :classes (copy-sequence (temme-node-classes node))
                :attrs (mapcar (lambda (attr)
                                 (cons (car attr) (cdr attr)))
                               (temme-node-attrs node))
                :text (temme-node-text node)
                :repeat (temme-node-repeat node)
                :children nil)))
    (setf (temme-node-children clone)
          (mapcar #'temme--clone-node (temme-node-children node)))
    clone))

(defun temme--clone-fragment (fragment)
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
  (if (<= count 1)
      fragment
    (let (roots last-path)
      (dotimes (_ count)
        (let ((copy (temme--clone-fragment fragment)))
          (setq roots (append roots (temme-fragment-roots copy))
                last-path (temme-fragment-paths copy))))
      (make-temme-fragment :roots roots :paths last-path))))

(defun temme--group-fragment (fragment)
  (make-temme-fragment
   :roots (temme-fragment-roots fragment)
   :paths (mapcar #'list (temme-fragment-roots fragment))))

(defun temme--path-prefix (path length)
  (cl-subseq path 0 (max 0 (min length (length path)))))

(defun temme--attach-fragment (roots basis-paths fragment)
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
        (cons roots new-paths))
    (cons (append roots (temme-fragment-roots fragment))
          (temme-fragment-paths fragment))))

(defun temme--parse-element (input pos)
  (setq pos (temme--skip-space input pos))
  (let ((tag nil)
        (id nil)
        (classes nil)
        (attrs nil)
        (text nil)
        (repeat 1)
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
        (_
         (setq pos (temme--skip-space input pos))
         (setq done t))))
    (cons (make-temme-node :tag (if (and tag (not (string-empty-p tag)))
                                    tag
                                  temme-default-tag)
                           :id id
                           :classes (nreverse classes)
                           :attrs attrs
                           :text text
                           :repeat repeat
                           :children nil)
          pos)))

(defun temme--parse-primary (input pos)
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
  (setq pos (or pos 0))
  (pcase-let* ((`(,first-fragment . ,next-pos)
                 (temme--parse-primary input pos))
               (`(,roots . ,current-paths)
                (temme--attach-fragment nil nil first-fragment)))
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
        (pcase-let* ((`(,fragment . ,new-pos)
                       (temme--parse-primary input next-pos))
                     (`(,new-roots . ,new-paths)
                      (temme--attach-fragment roots basis-paths fragment)))
          (setq roots new-roots
                current-paths new-paths
                next-pos (temme--skip-space input new-pos)))))
    (cons (make-temme-fragment :roots roots :paths current-paths)
          next-pos)))

(defun temme-parse (abbrev)
  "Parse ABBREV into a list of `temme-node' values."
  (pcase-let* ((`(,fragment . ,pos) (temme--parse-expression abbrev 0))
               (nodes (temme-fragment-roots fragment)))
    (setq pos (temme--skip-space abbrev pos))
    (unless (= pos (length abbrev))
      (error "Unexpected token at position %d" pos))
    nodes))

(defun temme--attrs (node)
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
        (push (format " id=\"%s\"" id) attrs))
      (when classes
        (push (format " class=\"%s\"" (string-join classes " ")) attrs))
      (dolist (attr (nreverse other-attrs))
        (push (if (eq (cdr attr) t)
                  (format " %s" (car attr))
                (format " %s=\"%s\"" (car attr) (cdr attr)))
              attrs))
      (apply #'concat (nreverse attrs)))))

(defun temme--indent-string (indent)
  (make-string (max 0 indent) ?\s))

(defun temme--render-once (node indent)
  (let ((tag (temme-node-tag node))
        (text (temme-node-text node))
        (children (temme-node-children node)))
    (if children
        (format "%s<%s%s>\n%s%s</%s>\n"
                (temme--indent-string indent)
                tag
                (temme--attrs node)
                (mapconcat
                 (lambda (child)
                   (temme-render-node child (+ indent temme-indent-offset)))
                 children
                 "")
                (temme--indent-string indent)
                tag)
      (format "%s<%s%s>%s</%s>\n"
              (temme--indent-string indent)
              tag
              (temme--attrs node)
              (or text "")
              tag))))

(defun temme-render-node (node &optional indent)
  "Render NODE into an HTML snippet."
  (mapconcat
   (lambda (_index)
     (temme--render-once node (or indent 0)))
   (number-sequence 1 (max 1 (temme-node-repeat node)))
   ""))

(defun temme-expand-string (abbrev &optional base-indent)
  "Expand ABBREV into HTML.
BASE-INDENT is the number of spaces to prepend to top-level elements."
  (mapconcat
   (lambda (node)
     (temme-render-node node (or base-indent 0)))
   (temme-parse abbrev)
   ""))

(defun temme--bounds-of-abbrev ()
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
      (insert expansion))))

;;;###autoload
(define-minor-mode temme-mode
  "Minor mode for basic Emmet-style expansion."
  :lighter " Temme"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c ,") #'temme-expand)
            map))

(provide 'temme-mode)

;;; temme-mode.el ends here
