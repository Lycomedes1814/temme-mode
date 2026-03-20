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

(ert-deftest temme-expand-zero-repeat-produces-no-output ()
  (should (equal (temme-expand-string "li*0") ""))
  (should (equal (temme-expand-string "(li>a)*0") "")))

(ert-deftest temme-expand-climb-up ()
  (should
   (equal (temme-expand-string "div>section>p^aside")
          "<div>\n  <section>\n    <p></p>\n  </section>\n  <aside></aside>\n</div>\n")))

(ert-deftest temme-expand-escapes-text-and-attribute-values ()
  (should
   (equal (temme-expand-string "p{<x>&}")
          "<p>&lt;x&gt;&amp;</p>\n"))
  (should
   (equal (temme-expand-string "div[data-x='a&b\"c<d>']")
          "<div data-x=\"a&amp;b&quot;c&lt;d&gt;\"></div>\n")))

(ert-deftest temme-expand-rejects-empty-shorthand-names ()
  (should-error (temme-expand-string "div."))
  (should-error (temme-expand-string "#")))

(ert-deftest temme-expand-rejects-text-on-parent-elements ()
  (should-error (temme-expand-string "div{a}>span")))

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

;; --- Snippet tests ---

(ert-deftest temme-expand-snippet-btn ()
  (should (equal (temme-expand-string "btn")
                 "<button></button>\n")))

(ert-deftest temme-expand-snippet-btn-with-class ()
  (should (equal (temme-expand-string "btn.primary{Submit}")
                 "<button class=\"primary\">Submit</button>\n")))

(ert-deftest temme-expand-snippet-a-link ()
  (should (equal (temme-expand-string "a:link")
                 "<a href=\"https://\"></a>\n")))

(ert-deftest temme-expand-snippet-a-mail ()
  (should (equal (temme-expand-string "a:mail")
                 "<a href=\"mailto:\"></a>\n")))

(ert-deftest temme-expand-snippet-link-css ()
  (should (equal (temme-expand-string "link:css")
                 "<link rel=\"stylesheet\" href=\"\" />\n")))

(ert-deftest temme-expand-snippet-link-favicon ()
  (should (equal (temme-expand-string "link:favicon")
                 "<link rel=\"icon\" type=\"image/x-icon\" href=\"favicon.ico\" />\n")))

(ert-deftest temme-expand-snippet-script-src ()
  (should (equal (temme-expand-string "script:src")
                 "<script src=\"\"></script>\n")))

(ert-deftest temme-expand-snippet-input-text ()
  (should (equal (temme-expand-string "input:text")
                 "<input id=\"\" type=\"text\" name=\"\" />\n")))

(ert-deftest temme-expand-snippet-input-hidden ()
  (should (equal (temme-expand-string "input:h")
                 "<input type=\"hidden\" name=\"\" />\n")))

(ert-deftest temme-expand-snippet-input-checkbox ()
  (should (equal (temme-expand-string "input:c")
                 "<input id=\"\" type=\"checkbox\" name=\"\" />\n")))

(ert-deftest temme-expand-snippet-input-submit ()
  (should (equal (temme-expand-string "input:s")
                 "<input type=\"submit\" value=\"\" />\n")))

(ert-deftest temme-expand-snippet-form-post ()
  (should (equal (temme-expand-string "form:post")
                 "<form action=\"\" method=\"post\"></form>\n")))

(ert-deftest temme-expand-snippet-meta-vp ()
  (should (equal (temme-expand-string "meta:vp")
                 "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n")))

(ert-deftest temme-expand-snippet-tag-aliases ()
  (should (equal (temme-expand-string "bq") "<blockquote></blockquote>\n"))
  (should (equal (temme-expand-string "sect") "<section></section>\n"))
  (should (equal (temme-expand-string "hdr") "<header></header>\n"))
  (should (equal (temme-expand-string "ftr") "<footer></footer>\n"))
  (should (equal (temme-expand-string "fig") "<figure></figure>\n"))
  (should (equal (temme-expand-string "str") "<strong></strong>\n"))
  (should (equal (temme-expand-string "mn") "<main></main>\n"))
  (should (equal (temme-expand-string "dlg") "<dialog></dialog>\n"))
  (should (equal (temme-expand-string "det") "<details></details>\n")))

(ert-deftest temme-expand-snippet-in-expression ()
  (should (equal (temme-expand-string "div>btn.primary{Go}+a:link")
                 (concat "<div>\n"
                         "  <button class=\"primary\">Go</button>\n"
                         "  <a href=\"https://\"></a>\n"
                         "</div>\n"))))

(ert-deftest temme-expand-snippet-attr-override ()
  (should (equal (temme-expand-string "a:link[href=https://example.com]")
                 "<a href=\"https://\" href=\"https://example.com\"></a>\n")))

(ert-deftest temme-expand-snippet-ul-plus ()
  (should (equal (temme-expand-string "ul+")
                 "<ul>\n  <li></li>\n</ul>\n")))

(ert-deftest temme-expand-snippet-dl-plus ()
  (should (equal (temme-expand-string "dl+")
                 "<dl>\n  <dt></dt>\n  <dd></dd>\n</dl>\n")))

(ert-deftest temme-expand-snippet-table-plus ()
  (should (equal (temme-expand-string "table+")
                 "<table>\n  <tr>\n    <td></td>\n  </tr>\n</table>\n")))

(ert-deftest temme-expand-snippet-select-plus ()
  (should (equal (temme-expand-string "select+")
                 "<select>\n  <option value=\"\"></option>\n</select>\n")))

(ert-deftest temme-expand-raw-snippet-bang ()
  (should (string-prefix-p "<!DOCTYPE html>" (temme-expand-string "!")))
  (should (string-match-p "<html lang=\"en\">" (temme-expand-string "!")))
  (should (string-match-p "<title>Document</title>" (temme-expand-string "!"))))

(ert-deftest temme-expand-raw-snippet-triple-bang ()
  (should (equal (temme-expand-string "!!!") "<!DOCTYPE html>\n")))

;; --- Numbering tests ---

(ert-deftest temme-expand-numbering-class ()
  (should (equal (temme-expand-string "li.item$*3")
                 (concat "<li class=\"item1\"></li>\n"
                         "<li class=\"item2\"></li>\n"
                         "<li class=\"item3\"></li>\n"))))

(ert-deftest temme-expand-numbering-zero-padded ()
  (should (equal (temme-expand-string "li.item$$*3")
                 (concat "<li class=\"item01\"></li>\n"
                         "<li class=\"item02\"></li>\n"
                         "<li class=\"item03\"></li>\n"))))

(ert-deftest temme-expand-numbering-id ()
  (should (equal (temme-expand-string "div#sec$*2")
                 (concat "<div id=\"sec1\"></div>\n"
                         "<div id=\"sec2\"></div>\n"))))

(ert-deftest temme-expand-numbering-text ()
  (should (equal (temme-expand-string "p{Item $}*2")
                 (concat "<p>Item 1</p>\n"
                         "<p>Item 2</p>\n"))))

(ert-deftest temme-expand-numbering-attr ()
  (should (equal (temme-expand-string "input[name=field$]*2")
                 (concat "<input name=\"field1\" />\n"
                         "<input name=\"field2\" />\n"))))

(ert-deftest temme-expand-numbering-nested ()
  (should (equal (temme-expand-string "ul>li.item$*2")
                 (concat "<ul>\n"
                         "  <li class=\"item1\"></li>\n"
                         "  <li class=\"item2\"></li>\n"
                         "</ul>\n"))))

(ert-deftest temme-expand-numbering-no-repeat ()
  "A single $ without repeat still substitutes with index 1."
  (should (equal (temme-expand-string "li.item$")
                 "<li class=\"item1\"></li>\n")))

;;; test-temme-mode.el ends here
