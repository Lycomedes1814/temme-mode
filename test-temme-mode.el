;;; test-temme-mode.el --- Tests for temme-mode -*- lexical-binding: t; -*-

(require 'ert)
(load-file "/home/jal/Projects/temme-mode/temme-mode.el")

(ert-deftest temme-expand-simple-tag ()
  (should (equal (temme-expand-string "div")
                 "<div></div>\n")))

(ert-deftest temme-expand-id-and-class ()
  (should (equal (temme-expand-string "main#app.shell")
                 "<main id=\"app\" class=\"shell\"></main>\n")))

(ert-deftest temme-expand-children-and-repeat ()
  (should (equal (temme-expand-string "ul>li.item*2")
                 "<ul>\n  <li class=\"item\"></li>\n  <li class=\"item\"></li>\n</ul>\n")))

(ert-deftest temme-expand-siblings-and-text ()
  (should
   (equal (temme-expand-string "h1.title{Hello}+p{World}")
          "<h1 class=\"title\">Hello</h1>\n<p>World</p>\n")))

(ert-deftest temme-expand-default-tag ()
  (should (equal (temme-expand-string "#root.card")
                 "<div id=\"root\" class=\"card\"></div>\n")))

(ert-deftest temme-expand-bracket-attributes ()
  (should (equal (temme-expand-string "input[type=text disabled aria-label='Name']")
                 "<input type=\"text\" disabled aria-label=\"Name\" />\n")))

(ert-deftest temme-expand-explicit-self-closing-tag ()
  (should (equal (temme-expand-string "custom-element.foo[data-x=1]/")
                 "<custom-element class=\"foo\" data-x=\"1\" />\n")))

(ert-deftest temme-expand-self-closing-child ()
  (should (equal (temme-expand-string "figure>img.hero[src=cover.jpg]/+figcaption{Cover}")
                 "<figure>\n  <img class=\"hero\" src=\"cover.jpg\" />\n  <figcaption>Cover</figcaption>\n</figure>\n")))

(ert-deftest temme-expand-merges-id-and-class-attributes ()
  (should (equal (temme-expand-string "div#x[id=y].a[class='b c']")
                 "<div id=\"y\" class=\"a b c\"></div>\n")))

(ert-deftest temme-expand-grouping ()
  (should
   (equal (temme-expand-string "div>(header>h1{Title})+(main>p{Body})")
          "<div>\n  <header>\n    <h1>Title</h1>\n  </header>\n  <main>\n    <p>Body</p>\n  </main>\n</div>\n")))

(ert-deftest temme-expand-children-after-multi-root-group ()
  (should
   (equal (temme-expand-string "(header+main)>p")
          "<header>\n  <p></p>\n</header>\n<main>\n  <p></p>\n</main>\n")))

(ert-deftest temme-expand-group-repeat ()
  (should
   (equal (temme-expand-string "ul>(li>a)*2")
          "<ul>\n  <li>\n    <a></a>\n  </li>\n  <li>\n    <a></a>\n  </li>\n</ul>\n")))

(ert-deftest temme-expand-climb-up ()
  (should
   (equal (temme-expand-string "div>section>p^aside")
          "<div>\n  <section>\n    <p></p>\n  </section>\n  <aside></aside>\n</div>\n")))

(ert-deftest temme-expand-command-replaces-region ()
  (with-temp-buffer
    (insert "section>p{Hi}")
    (goto-char (point-max))
    (temme-expand)
    (should (equal (buffer-string)
                   "<section>\n  <p>Hi</p>\n</section>\n"))))

(ert-deftest temme-expand-string-honors-base-indentation ()
  (should (equal (temme-expand-string "section>p{Hi}" 4)
                 "    <section>\n      <p>Hi</p>\n    </section>\n")))

(ert-deftest temme-expand-command-starts-at-current-indentation ()
  (with-temp-buffer
    (insert "    section>p{Hi}")
    (goto-char (point-max))
    (temme-expand)
    (should (equal (buffer-string)
                   "    <section>\n      <p>Hi</p>\n    </section>\n"))))

;;; test-temme-mode.el ends here
