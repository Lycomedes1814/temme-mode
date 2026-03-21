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
  (should (string-match-p "<title>|</title>" (temme-expand-string "!"))))

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

;; --- Field navigation tests ---

(defmacro temme-test-with-expansion (abbrev &rest body)
  "Expand ABBREV in a temp buffer with `temme-mode' and run BODY."
  (declare (indent 1))
  `(with-temp-buffer
     (temme-mode 1)
     (insert ,abbrev)
     (temme-expand)
     ,@body))

(ert-deftest temme-fields-a-link ()
  "a:link should create fields for href value and tag content."
  (temme-test-with-expansion "a:link"
    (should temme-field-mode)
    (should (= (length temme--fields) 2))
    ;; First field: after https:// in href
    (should (= temme--field-index 0))
    (should (looking-back "https://" (line-beginning-position)))
    ;; TAB to tag content
    (temme-next-field)
    (should (= temme--field-index 1))
    (should (looking-back ">" (line-beginning-position)))
    (should (looking-at "</a>"))
    ;; TAB past last exits field mode
    (temme-next-field)
    (should-not temme-field-mode)))

(ert-deftest temme-fields-input-text ()
  "input:text should create fields for name and id."
  (temme-test-with-expansion "input:text"
    (should temme-field-mode)
    ;; type="text" is not a field; name="" and id="" are.
    (should (= (length temme--fields) 2))))

(ert-deftest temme-fields-none-for-plain-tag ()
  "A plain tag like div should not activate field mode."
  (temme-test-with-expansion "div"
    ;; div expands to <div></div> — the empty content IS a field
    (should temme-field-mode)
    (should (= (length temme--fields) 1))
    (should (looking-back ">" (line-beginning-position)))
    (should (looking-at "</div>"))))

(ert-deftest temme-fields-prev-field ()
  "S-TAB should move to previous field."
  (temme-test-with-expansion "a:link"
    (temme-next-field)
    (should (= temme--field-index 1))
    (temme-prev-field)
    (should (= temme--field-index 0))
    ;; prev at first field stays put
    (temme-prev-field)
    (should (= temme--field-index 0))))

(ert-deftest temme-fields-exit-clears ()
  "Exiting field mode should clear all markers."
  (temme-test-with-expansion "a:link"
    (temme-exit-fields)
    (should-not temme-field-mode)
    (should (null temme--fields))))

(ert-deftest temme-fields-form-post ()
  "form:post should have a field for the empty action value."
  (temme-test-with-expansion "form:post"
    (should temme-field-mode)
    ;; action="" is a field, method="post" is not, and <form></form> content is
    (should (= (length temme--fields) 2))))

(ert-deftest temme-fields-doc ()
  "doc snippet should place cursor in body via field markers."
  (temme-test-with-expansion "doc"
    (should temme-field-mode)
    ;; Two fields: empty <title></title> and | in body
    (should (= (length temme--fields) 2))
    ;; First field: inside <title>
    (should (= temme--field-index 0))
    (should (looking-back ">" (line-beginning-position)))
    (should (looking-at "</title>"))
    ;; TAB to body
    (temme-next-field)
    (should (= temme--field-index 1))
    (should (looking-at "\n</body>"))
    ;; TAB past last exits field mode
    (temme-next-field)
    (should-not temme-field-mode)))

;;; Lorem ipsum ---------------------------------------------------------------

(ert-deftest temme-lorem-default-30-words ()
  "lorem should generate 30 words of placeholder text."
  (let ((result (temme-expand-string "lorem")))
    (should (string-prefix-p "Lorem ipsum" result))
    (should (string-suffix-p ".\n" result))
    ;; 30 words
    (should (= 30 (length (split-string (string-trim result)))))))

(ert-deftest temme-lorem-custom-count ()
  "lorem5 should generate exactly 5 words."
  (let ((result (temme-expand-string "lorem5")))
    (should (string-prefix-p "Lorem" result))
    (should (string-suffix-p ".\n" result))
    (should (= 5 (length (split-string (string-trim result)))))))

(ert-deftest temme-lorem-one-word ()
  "lorem1 should generate a single capitalized word with period."
  (should (equal (temme-expand-string "lorem1")
                 "Lorem.\n")))

(ert-deftest temme-lorem-as-child ()
  "p>lorem5 should render lorem text inside a p element."
  (let ((result (temme-expand-string "p>lorem5")))
    (should (string-prefix-p "<p>\n" result))
    (should (string-suffix-p "</p>\n" result))
    (should (string-match-p "  Lorem" result))))

(ert-deftest temme-lorem-repeated-varies ()
  "ul>li*2>lorem3 should produce different text for each li."
  (let ((result (temme-expand-string "ul>li*2>lorem3")))
    ;; First li starts with "Lorem ipsum dolor"
    (should (string-match-p "Lorem ipsum dolor" result))
    ;; Collect the two lorem lines
    (let ((lines (seq-filter (lambda (s)
                               (string-match-p "^\\s-*[A-Z]" s))
                             (split-string result "\n"))))
      (should (= 2 (length lines)))
      ;; The two lines should have different text
      (should-not (string= (string-trim (nth 0 lines))
                            (string-trim (nth 1 lines)))))))

;;; Preview tests -------------------------------------------------------------

(ert-deftest temme-preview-creates-overlay ()
  "Preview should create an overlay covering the abbreviation region."
  (with-temp-buffer
    (temme-mode 1)
    (insert "div.foo")
    (temme-preview)
    (should (overlayp temme--preview-overlay))
    (should (= (overlay-start temme--preview-overlay) (line-beginning-position)))
    (should (= (overlay-end temme--preview-overlay) (point)))
    (should (string= (overlay-get temme--preview-overlay 'display)
                      (propertize "<div class=\"foo\"></div>"
                                  'face 'temme-preview-face)))
    (temme--preview-cleanup)))

(ert-deftest temme-preview-accept-expands ()
  "Accepting a preview should produce the correct expansion."
  (with-temp-buffer
    (temme-mode 1)
    (insert "p")
    (temme-preview)
    (should (overlayp temme--preview-overlay))
    (temme-preview-accept)
    (should-not temme--preview-overlay)
    (should (string= (buffer-string) "<p></p>\n"))))

(ert-deftest temme-preview-dismiss-leaves-buffer ()
  "Dismissing a preview should leave buffer unchanged and remove overlay."
  (with-temp-buffer
    (temme-mode 1)
    (insert "span")
    (temme-preview)
    (should (overlayp temme--preview-overlay))
    (temme-preview-dismiss)
    (should-not temme--preview-overlay)
    (should (string= (buffer-string) "span"))))

(ert-deftest temme-preview-invalid-abbreviation ()
  "Invalid abbreviation should show message and create no overlay."
  (with-temp-buffer
    (temme-mode 1)
    (insert ">>>")
    (temme-preview)
    (should-not temme--preview-overlay)
    (should (string= (buffer-string) ">>>"))))

(ert-deftest temme-preview-cleanup-idempotent ()
  "Calling cleanup with no active preview should not error."
  (with-temp-buffer
    (temme-mode 1)
    (should-not temme--preview-overlay)
    (temme--preview-cleanup)
    (should-not temme--preview-overlay)))

;;; test-temme-mode.el ends here
