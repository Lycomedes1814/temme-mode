;;; test-temme-mode.el --- Tests for temme-mode -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(load-file "/home/jal/Projects/temme-mode/temme-mode.el")

(ert-deftest temme-expand-simple-tag ()
  (should (equal (temme-expand-string "div")
                 "<div></div>\n")))

(ert-deftest temme-expand-id-and-class ()
  (should (equal (temme-expand-string "main#app.shell")
                 "<main id=\"app\" class=\"shell\"></main>\n")))

(ert-deftest temme-expand-children-and-repeat ()
  (should (equal (temme-expand-string "ul>li.item*2")
                 "<ul><li class=\"item\"></li>\n<li class=\"item\"></li>\n</ul>\n")))

(ert-deftest temme-expand-siblings-and-text ()
  (should
   (equal (temme-expand-string "h1.title{Hello}+p{World}")
          "<h1 class=\"title\">Hello</h1>\n<p>World</p>\n")))

(ert-deftest temme-expand-default-tag ()
  (should (equal (temme-expand-string "#root.card")
                 "<div id=\"root\" class=\"card\"></div>\n")))

(ert-deftest temme-expand-command-replaces-region ()
  (with-temp-buffer
    (insert "section>p{Hi}")
    (goto-char (point-max))
    (temme-expand)
    (should (equal (buffer-string)
                   "<section><p>Hi</p>\n</section>\n"))))

(ert-deftest temme-expand-command-indents-inserted-region ()
  (with-temp-buffer
    (insert "section>p{Hi}")
    (goto-char (point-max))
    (let (indent-call)
      (cl-letf (((symbol-function 'indent-region)
                 (lambda (start end &optional _column)
                   (setq indent-call (cons start end)))))
        (temme-expand))
      (should (equal indent-call
                     (cons (point-min) (point-max)))))))

;;; test-temme-mode.el ends here
