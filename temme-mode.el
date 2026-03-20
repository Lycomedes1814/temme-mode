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
  text
  repeat
  children)

(defgroup temme nil
  "Tiny Emmet-like expansions."
  :group 'editing)

(defcustom temme-default-tag "div"
  "Tag name used when an abbreviation starts with `#' or `.'."
  :type 'string
  :group 'temme)

(defun temme--alnum-or-symbol-p (char)
  (or (and (>= char ?a) (<= char ?z))
      (and (>= char ?A) (<= char ?Z))
      (and (>= char ?0) (<= char ?9))
      (eq char ?-)
      (eq char ?_)
      (eq char ?:)))

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

(defun temme--parse-element (input pos)
  (setq pos (temme--skip-space input pos))
 (let ((tag nil)
        (id nil)
        (classes nil)
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
                           :text text
                           :repeat repeat
                           :children nil)
          pos)))

(defun temme--parse-expression (input &optional pos)
  (setq pos (or pos 0))
  (pcase-let ((`(,node . ,next-pos) (temme--parse-element input pos)))
    (setq next-pos (temme--skip-space input next-pos))
    (let ((siblings (list node)))
      (while (and (< next-pos (length input))
                  (eq (aref input next-pos) ?+))
        (pcase-let ((`(,sibling . ,new-pos)
                     (temme--parse-element input (1+ next-pos))))
          (push sibling siblings)
          (setq next-pos (temme--skip-space input new-pos))))
      (setq siblings (nreverse siblings))
      (let ((cursor (car siblings)))
        (while (and (< next-pos (length input))
                    (eq (aref input next-pos) ?>))
          (pcase-let ((`(,children . ,new-pos)
                       (temme--parse-expression input (1+ next-pos))))
            (setf (temme-node-children cursor) children)
            (setq next-pos (temme--skip-space input new-pos)
                  cursor (car (last children))))))
      (cons siblings next-pos))))

(defun temme-parse (abbrev)
  "Parse ABBREV into a list of `temme-node' values."
  (pcase-let ((`(,nodes . ,pos) (temme--parse-expression abbrev 0)))
    (setq pos (temme--skip-space abbrev pos))
    (unless (= pos (length abbrev))
      (error "Unexpected token at position %d" pos))
    nodes))

(defun temme--attrs (node)
  (let (attrs)
    (when-let ((id (temme-node-id node)))
      (push (format " id=\"%s\"" id) attrs))
    (when-let ((classes (temme-node-classes node)))
      (push (format " class=\"%s\"" (string-join classes " ")) attrs))
    (apply #'concat (nreverse attrs))))

(defun temme--render-once (node)
  (let ((tag (temme-node-tag node))
        (text (temme-node-text node))
        (children (temme-node-children node)))
    (format "<%s%s>%s</%s>\n"
            tag
            (temme--attrs node)
            (concat (or text "")
                    (mapconcat #'temme-render-node children ""))
            tag)))

(defun temme-render-node (node)
  "Render NODE into an HTML snippet."
  (mapconcat
   (lambda (_index)
     (temme--render-once node))
   (number-sequence 1 (max 1 (temme-node-repeat node)))
   ""))

(defun temme-expand-string (abbrev)
  "Expand ABBREV into HTML."
  (mapconcat #'temme-render-node (temme-parse abbrev) ""))

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
               (abbrev (string-trim (buffer-substring-no-properties start end))))
    (when (string-empty-p abbrev)
      (user-error "No abbreviation at point"))
    (let ((expansion (temme-expand-string abbrev)))
      (delete-region start end)
      (goto-char start)
      (insert expansion)
      (indent-region start (point)))))

;;;###autoload
(define-minor-mode temme-mode
  "Minor mode for basic Emmet-style expansion."
  :lighter " Temme"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c ,") #'temme-expand)
            map))

(provide 'temme-mode)

;;; temme-mode.el ends here
