;;; test-temme-mode.el --- Tests for temme-mode -*- lexical-binding: t; -*-

(require 'ert)
(load-file "/home/jal/Projects/temme-mode/temme-mode.el")
(load-file "/home/jal/Projects/temme-mode/temme-css.el")

(ert-deftest temme-expand-simple-tag ()
  (should (equal (temme-expand-string "div")
                 "<div></div>")))

(ert-deftest temme-expand-id-and-class ()
  (should (equal (temme-expand-string "main#app.shell")
                 "<main id=\"app\" class=\"shell\"></main>")))

(ert-deftest temme-expand-children-and-repeat ()
  (should (equal (temme-expand-string "ul>li.item*2")
                 "<ul>\n  <li class=\"item\"></li>\n  <li class=\"item\"></li>\n</ul>")))

(ert-deftest temme-expand-siblings-and-text ()
  (should
   (equal (temme-expand-string "h1.title{Hello}+p{World}")
          "<h1 class=\"title\">Hello</h1>\n<p>World</p>")))

(ert-deftest temme-expand-default-tag ()
  (should (equal (temme-expand-string "#root.card")
                 "<div id=\"root\" class=\"card\"></div>")))

(ert-deftest temme-expand-bracket-attributes ()
  (should (equal (temme-expand-string "input[type=text disabled aria-label='Name']")
                 "<input type=\"text\" disabled aria-label=\"Name\" />")))

(ert-deftest temme-expand-explicit-self-closing-tag ()
  (should (equal (temme-expand-string "custom-element.foo[data-x=1]/")
                 "<custom-element class=\"foo\" data-x=\"1\" />")))

(ert-deftest temme-expand-self-closing-child ()
  (should (equal (temme-expand-string "figure>img.hero[src=cover.jpg]/+figcaption{Cover}")
                 "<figure>\n  <img class=\"hero\" src=\"cover.jpg\" />\n  <figcaption>Cover</figcaption>\n</figure>")))

(ert-deftest temme-expand-merges-id-and-class-attributes ()
  (should (equal (temme-expand-string "div#x[id=y].a[class='b c']")
                 "<div id=\"y\" class=\"a b c\"></div>")))

(ert-deftest temme-expand-grouping ()
  (should
   (equal (temme-expand-string "div>(header>h1{Title})+(main>p{Body})")
          "<div>\n  <header>\n    <h1>Title</h1>\n  </header>\n  <main>\n    <p>Body</p>\n  </main>\n</div>")))

(ert-deftest temme-expand-children-after-multi-root-group ()
  (should
   (equal (temme-expand-string "(header+main)>p")
          "<header>\n  <p></p>\n</header>\n<main>\n  <p></p>\n</main>")))

(ert-deftest temme-expand-group-repeat ()
  (should
   (equal (temme-expand-string "ul>(li>a)*2")
          "<ul>\n  <li>\n    <a></a>\n  </li>\n  <li>\n    <a></a>\n  </li>\n</ul>")))

(ert-deftest temme-expand-zero-repeat-produces-no-output ()
  (should (equal (temme-expand-string "li*0") ""))
  (should (equal (temme-expand-string "(li>a)*0") "")))

(ert-deftest temme-expand-climb-up ()
  (should
   (equal (temme-expand-string "div>section>p^aside")
          "<div>\n  <section>\n    <p></p>\n  </section>\n  <aside></aside>\n</div>")))

(ert-deftest temme-expand-escapes-text-and-attribute-values ()
  (should
   (equal (temme-expand-string "p{<x>&}")
          "<p>&lt;x&gt;&amp;</p>"))
  (should
   (equal (temme-expand-string "div[data-x='a&b\"c<d>']")
          "<div data-x=\"a&amp;b&quot;c&lt;d&gt;\"></div>")))

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
                   "<section>\n  <p>Hi</p>\n</section>"))))

(ert-deftest temme-expand-string-honors-base-indentation ()
  (should (equal (temme-expand-string "section>p{Hi}" 4)
                 "    <section>\n      <p>Hi</p>\n    </section>")))

(ert-deftest temme-expand-command-starts-at-current-indentation ()
  (with-temp-buffer
    (insert "    section>p{Hi}")
    (goto-char (point-max))
    (temme-expand)
    (should (equal (buffer-string)
                   "    <section>\n      <p>Hi</p>\n    </section>"))))

;; --- Snippet tests ---

(ert-deftest temme-expand-snippet-btn ()
  (should (equal (temme-expand-string "btn")
                 "<button></button>")))

(ert-deftest temme-expand-snippet-btn-with-class ()
  (should (equal (temme-expand-string "btn.primary{Submit}")
                 "<button class=\"primary\">Submit</button>")))

(ert-deftest temme-expand-snippet-a-link ()
  (should (equal (temme-expand-string "a:link")
                 "<a href=\"https://\"></a>")))

(ert-deftest temme-expand-snippet-a-mail ()
  (should (equal (temme-expand-string "a:mail")
                 "<a href=\"mailto:\"></a>")))

(ert-deftest temme-expand-snippet-link-css ()
  (should (equal (temme-expand-string "link:css")
                 "<link rel=\"stylesheet\" href=\"\" />")))

(ert-deftest temme-expand-snippet-link-favicon ()
  (should (equal (temme-expand-string "link:favicon")
                 "<link rel=\"icon\" type=\"image/x-icon\" href=\"favicon.ico\" />")))

(ert-deftest temme-expand-snippet-script-src ()
  (should (equal (temme-expand-string "script:src")
                 "<script src=\"\"></script>")))

(ert-deftest temme-expand-snippet-input-text ()
  (should (equal (temme-expand-string "input:text")
                 "<input id=\"\" type=\"text\" name=\"\" />")))

(ert-deftest temme-expand-snippet-input-hidden ()
  (should (equal (temme-expand-string "input:h")
                 "<input type=\"hidden\" name=\"\" />")))

(ert-deftest temme-expand-snippet-input-checkbox ()
  (should (equal (temme-expand-string "input:c")
                 "<input id=\"\" type=\"checkbox\" name=\"\" />")))

(ert-deftest temme-expand-snippet-input-submit ()
  (should (equal (temme-expand-string "input:s")
                 "<input type=\"submit\" value=\"\" />")))

(ert-deftest temme-expand-snippet-form-post ()
  (should (equal (temme-expand-string "form:post")
                 "<form action=\"\" method=\"post\"></form>")))

(ert-deftest temme-expand-snippet-meta-vp ()
  (should (equal (temme-expand-string "meta:vp")
                 "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />")))

(ert-deftest temme-expand-snippet-tag-aliases ()
  (should (equal (temme-expand-string "bq") "<blockquote></blockquote>"))
  (should (equal (temme-expand-string "sect") "<section></section>"))
  (should (equal (temme-expand-string "hdr") "<header></header>"))
  (should (equal (temme-expand-string "ftr") "<footer></footer>"))
  (should (equal (temme-expand-string "fig") "<figure></figure>"))
  (should (equal (temme-expand-string "str") "<strong></strong>"))
  (should (equal (temme-expand-string "mn") "<main></main>"))
  (should (equal (temme-expand-string "dlg") "<dialog></dialog>"))
  (should (equal (temme-expand-string "det") "<details></details>")))

(ert-deftest temme-expand-snippet-in-expression ()
  (should (equal (temme-expand-string "div>btn.primary{Go}+a:link")
                 (concat "<div>\n"
                         "  <button class=\"primary\">Go</button>\n"
                         "  <a href=\"https://\"></a>\n"
                         "</div>"))))

(ert-deftest temme-expand-snippet-attr-override ()
  (should (equal (temme-expand-string "a:link[href=https://example.com]")
                 "<a href=\"https://\" href=\"https://example.com\"></a>")))

(ert-deftest temme-expand-snippet-ul-plus ()
  (should (equal (temme-expand-string "ul+")
                 "<ul>\n  <li></li>\n</ul>")))

(ert-deftest temme-expand-snippet-dl-plus ()
  (should (equal (temme-expand-string "dl+")
                 "<dl>\n  <dt></dt>\n  <dd></dd>\n</dl>")))

(ert-deftest temme-expand-snippet-table-plus ()
  (should (equal (temme-expand-string "table+")
                 "<table>\n  <tr>\n    <td></td>\n  </tr>\n</table>")))

(ert-deftest temme-expand-snippet-select-plus ()
  (should (equal (temme-expand-string "select+")
                 "<select>\n  <option value=\"\"></option>\n</select>")))

(ert-deftest temme-expand-raw-snippet-bang ()
  (should (string-prefix-p "<!DOCTYPE html>" (temme-expand-string "!")))
  (should (string-match-p "<html lang=\"en\">" (temme-expand-string "!")))
  (should (string-match-p "<title>|</title>" (temme-expand-string "!"))))

(ert-deftest temme-expand-raw-snippet-triple-bang ()
  (should (equal (temme-expand-string "!!!") "<!DOCTYPE html>")))

;; --- Numbering tests ---

(ert-deftest temme-expand-numbering-class ()
  (should (equal (temme-expand-string "li.item$*3")
                 (concat "<li class=\"item1\"></li>\n"
                         "<li class=\"item2\"></li>\n"
                         "<li class=\"item3\"></li>"))))

(ert-deftest temme-expand-numbering-zero-padded ()
  (should (equal (temme-expand-string "li.item$$*3")
                 (concat "<li class=\"item01\"></li>\n"
                         "<li class=\"item02\"></li>\n"
                         "<li class=\"item03\"></li>"))))

(ert-deftest temme-expand-numbering-id ()
  (should (equal (temme-expand-string "div#sec$*2")
                 (concat "<div id=\"sec1\"></div>\n"
                         "<div id=\"sec2\"></div>"))))

(ert-deftest temme-expand-numbering-text ()
  (should (equal (temme-expand-string "p{Item $}*2")
                 (concat "<p>Item 1</p>\n"
                         "<p>Item 2</p>"))))

(ert-deftest temme-expand-numbering-attr ()
  (should (equal (temme-expand-string "input[name=field$]*2")
                 (concat "<input name=\"field1\" />\n"
                         "<input name=\"field2\" />"))))

(ert-deftest temme-expand-numbering-nested ()
  (should (equal (temme-expand-string "ul>li.item$*2")
                 (concat "<ul>\n"
                         "  <li class=\"item1\"></li>\n"
                         "  <li class=\"item2\"></li>\n"
                         "</ul>"))))

(ert-deftest temme-expand-numbering-no-repeat ()
  "A single $ without repeat still substitutes with index 1."
  (should (equal (temme-expand-string "li.item$")
                 "<li class=\"item1\"></li>")))

(ert-deftest temme-expand-numbering-offset ()
  "$ with @N offset starts numbering at N."
  (should (equal (temme-expand-string "li.item$@3*3")
                 (concat "<li class=\"item3\"></li>\n"
                         "<li class=\"item4\"></li>\n"
                         "<li class=\"item5\"></li>"))))

(ert-deftest temme-expand-numbering-offset-one ()
  "$@1 behaves identically to plain $."
  (should (equal (temme-expand-string "li.item$@1*2")
                 (concat "<li class=\"item1\"></li>\n"
                         "<li class=\"item2\"></li>"))))

(ert-deftest temme-expand-numbering-zero-padded-offset ()
  "$$@N applies zero-padding and offset together."
  (should (equal (temme-expand-string "li.item$$@3*3")
                 (concat "<li class=\"item03\"></li>\n"
                         "<li class=\"item04\"></li>\n"
                         "<li class=\"item05\"></li>"))))

(ert-deftest temme-expand-numbering-reverse ()
  "$@- reverses numbering direction."
  (should (equal (temme-expand-string "li.item$@-*3")
                 (concat "<li class=\"item3\"></li>\n"
                         "<li class=\"item2\"></li>\n"
                         "<li class=\"item1\"></li>"))))

(ert-deftest temme-expand-numbering-reverse-offset ()
  "$@-N reverses numbering starting from N+count-1 down to N."
  (should (equal (temme-expand-string "li.item$@-5*3")
                 (concat "<li class=\"item7\"></li>\n"
                         "<li class=\"item6\"></li>\n"
                         "<li class=\"item5\"></li>"))))

(ert-deftest temme-expand-numbering-reverse-zero-padded ()
  "$$@- applies zero-padding with reverse numbering."
  (should (equal (temme-expand-string "li.item$$@-*3")
                 (concat "<li class=\"item03\"></li>\n"
                         "<li class=\"item02\"></li>\n"
                         "<li class=\"item01\"></li>"))))

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

;; --- Implicit tag tests ---

(ert-deftest temme-implicit-tag-ul ()
  (should (equal (temme-expand-string "ul>.item")
                 "<ul>\n  <li class=\"item\"></li>\n</ul>")))

(ert-deftest temme-implicit-tag-ol ()
  (should (equal (temme-expand-string "ol>.item*2")
                 "<ol>\n  <li class=\"item\"></li>\n  <li class=\"item\"></li>\n</ol>")))

(ert-deftest temme-implicit-tag-table ()
  (should (equal (temme-expand-string "table>.row")
                 "<table>\n  <tr class=\"row\"></tr>\n</table>")))

(ert-deftest temme-implicit-tag-tr ()
  (should (equal (temme-expand-string "tr>.cell")
                 "<tr>\n  <td class=\"cell\"></td>\n</tr>")))

(ert-deftest temme-implicit-tag-select ()
  (should (equal (temme-expand-string "select>.opt")
                 "<select>\n  <option class=\"opt\"></option>\n</select>")))

(ert-deftest temme-implicit-tag-toplevel-defaults-to-div ()
  (should (equal (temme-expand-string ".wrap")
                 "<div class=\"wrap\"></div>"))
  (should (equal (temme-expand-string "#app")
                 "<div id=\"app\"></div>")))

(ert-deftest temme-implicit-tag-nested-in-div ()
  "Inside a non-list parent, implicit tag defaults to div."
  (should (equal (temme-expand-string "div>.inner")
                 "<div>\n  <div class=\"inner\"></div>\n</div>")))

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
    (should (string-suffix-p "." result))
    ;; 30 words
    (should (= 30 (length (split-string (string-trim result)))))))

(ert-deftest temme-lorem-custom-count ()
  "lorem5 should generate exactly 5 words."
  (let ((result (temme-expand-string "lorem5")))
    (should (string-prefix-p "Lorem" result))
    (should (string-suffix-p "." result))
    (should (= 5 (length (split-string (string-trim result)))))))

(ert-deftest temme-lorem-one-word ()
  "lorem1 should generate a single capitalized word with period."
  (should (equal (temme-expand-string "lorem1")
                 "Lorem.")))

(ert-deftest temme-lorem-as-child ()
  "p>lorem5 should render lorem text inside a p element."
  (let ((result (temme-expand-string "p>lorem5")))
    (should (string-prefix-p "<p>\n" result))
    (should (string-suffix-p "</p>" result))
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

;;; Advanced text tests -------------------------------------------------------

(ert-deftest temme-expand-nested-braces-in-text ()
  "Inner {} are preserved literally in text content."
  (should (equal (temme-expand-string "p{Hello {name}}")
                 "<p>Hello {name}</p>"))
  (should (equal (temme-expand-string "span{a{b}c}")
                 "<span>a{b}c</span>"))
  (should (equal (temme-expand-string "p{{nested}}")
                 "<p>{nested}</p>")))

(ert-deftest temme-expand-standalone-text-node ()
  "A bare {text} with no element modifiers renders as raw text."
  (should (equal (temme-expand-string "{Hello}")
                 "Hello"))
  (should (equal (temme-expand-string "{<em>raw</em>}")
                 "&lt;em&gt;raw&lt;/em&gt;")))

(ert-deftest temme-expand-text-node-child ()
  "A {text} child inside a parent renders inline."
  (should (equal (temme-expand-string "div>{Hello}")
                 "<div>Hello</div>"))
  (should (equal (temme-expand-string "p>{Hi}+em{there}")
                 "<p>Hi<em>there</em></p>"))
  (should (equal (temme-expand-string "a>{Click }+em{here}+{ now}")
                 "<a>Click <em>here</em> now</a>")))

(ert-deftest temme-expand-text-node-numbering ()
  "Numbering works in standalone text nodes."
  (should (equal (temme-expand-string "{item $}*3")
                 (concat "item 1\n"
                         "item 2\n"
                         "item 3"))))

(ert-deftest temme-expand-mixed-content-with-repeated-elements ()
  "Repeated elements inside mixed content render correctly inline."
  (should (equal (temme-expand-string "p>{start }+em*2{$}+{ end}")
                 "<p>start <em>1</em><em>2</em> end</p>")))

;;; CSS abbreviation expansion ------------------------------------------------

(ert-deftest temme-css-basic-property-with-value ()
  (should (equal (temme-css-expand-string "m10")
                 "margin: 10px;"))
  (should (equal (temme-css-expand-string "p20")
                 "padding: 20px;"))
  (should (equal (temme-css-expand-string "w100")
                 "width: 100px;"))
  (should (equal (temme-css-expand-string "fz16")
                 "font-size: 16px;")))

(ert-deftest temme-css-zero-has-no-unit ()
  (should (equal (temme-css-expand-string "m0")
                 "margin: 0;"))
  (should (equal (temme-css-expand-string "p0")
                 "padding: 0;")))

(ert-deftest temme-css-unit-suffixes ()
  (should (equal (temme-css-expand-string "m10p")
                 "margin: 10%;"))
  (should (equal (temme-css-expand-string "m10e")
                 "margin: 10em;"))
  (should (equal (temme-css-expand-string "m10r")
                 "margin: 10rem;"))
  (should (equal (temme-css-expand-string "m10x")
                 "margin: 10px;")))

(ert-deftest temme-css-negative-values ()
  (should (equal (temme-css-expand-string "m-10")
                 "margin: -10px;")))

(ert-deftest temme-css-multi-values ()
  (should (equal (temme-css-expand-string "m10-20")
                 "margin: 10px 20px;"))
  (should (equal (temme-css-expand-string "p10-20-30-40")
                 "padding: 10px 20px 30px 40px;")))

(ert-deftest temme-css-keyword-expansions ()
  (should (equal (temme-css-expand-string "dn")
                 "display: none;"))
  (should (equal (temme-css-expand-string "df")
                 "display: flex;"))
  (should (equal (temme-css-expand-string "dib")
                 "display: inline-block;"))
  (should (equal (temme-css-expand-string "tac")
                 "text-align: center;"))
  (should (equal (temme-css-expand-string "fwb")
                 "font-weight: bold;"))
  (should (equal (temme-css-expand-string "posa")
                 "position: absolute;")))

(ert-deftest temme-css-bare-prefix-expands-to-empty-declaration ()
  "Bare property prefixes expand to empty declarations."
  (should (equal (temme-css-expand-string "m")
                 "margin: ;"))
  (should (equal (temme-css-expand-string "p")
                 "padding: ;"))
  (should (equal (temme-css-expand-string "bg")
                 "background: ;"))
  (should (equal (temme-css-expand-string "ff")
                 "font-family: ;"))
  (should (equal (temme-css-expand-string "ai")
                 "align-items: ;")))

(ert-deftest temme-css-unitless-properties ()
  (should (equal (temme-css-expand-string "z10")
                 "z-index: 10;"))
  (should (equal (temme-css-expand-string "op50")
                 "opacity: 50;"))
  (should (equal (temme-css-expand-string "fxg1")
                 "flex-grow: 1;")))

(ert-deftest temme-css-color-values ()
  (should (equal (temme-css-expand-string "c#f00")
                 "color: #f00;"))
  (should (equal (temme-css-expand-string "bgc#e0e0e0")
                 "background-color: #e0e0e0;")))

(ert-deftest temme-css-unknown-abbreviation ()
  (should (null (temme-css-expand-string "zzz123"))))

(ert-deftest temme-css-multi-value-with-negative ()
  (should (equal (temme-css-expand-string "m10--20")
                 "margin: 10px -20px;")))

(ert-deftest temme-css-margin-auto-keyword ()
  (should (equal (temme-css-expand-string "ma")
                 "margin: auto;"))
  (should (equal (temme-css-expand-string "mla")
                 "margin-left: auto;")))

(ert-deftest temme-css-vendor-prefix-all ()
  (should (equal (temme-css-expand-string "-trs")
                 (concat "-webkit-transition: ;\n"
                         "-moz-transition: ;\n"
                         "-ms-transition: ;\n"
                         "-o-transition: ;\n"
                         "transition: ;"))))

(ert-deftest temme-css-vendor-prefix-all-with-value ()
  (should (equal (temme-css-expand-string "-bdrs10")
                 (concat "-webkit-border-radius: 10px;\n"
                         "-moz-border-radius: 10px;\n"
                         "-ms-border-radius: 10px;\n"
                         "-o-border-radius: 10px;\n"
                         "border-radius: 10px;"))))

(ert-deftest temme-css-vendor-prefix-specific ()
  (should (equal (temme-css-expand-string "-wm-trs")
                 (concat "-webkit-transition: ;\n"
                         "-moz-transition: ;\n"
                         "transition: ;"))))

(ert-deftest temme-css-vendor-prefix-single ()
  (should (equal (temme-css-expand-string "-w-bdrs10")
                 (concat "-webkit-border-radius: 10px;\n"
                         "border-radius: 10px;"))))

(ert-deftest temme-css-vendor-prefix-with-keyword ()
  (should (equal (temme-css-expand-string "-df")
                 (concat "-webkit-display: flex;\n"
                         "-moz-display: flex;\n"
                         "-ms-display: flex;\n"
                         "-o-display: flex;\n"
                         "display: flex;"))))

(ert-deftest temme-css-vendor-prefix-unknown ()
  (should (null (temme-css-expand-string "-zzz"))))

(ert-deftest temme-css-literal-value ()
  (should (equal (temme-css-expand-string "trs:all 0.3s ease")
                 "transition: all 0.3s ease;"))
  (should (equal (temme-css-expand-string "d:flex")
                 "display: flex;"))
  (should (equal (temme-css-expand-string "trs:all 0.3s ease-in-out")
                 "transition: all 0.3s ease-in-out;")))

(ert-deftest temme-css-literal-value-empty ()
  (should (equal (temme-css-expand-string "trs:")
                 "transition: ;")))

(ert-deftest temme-css-literal-value-unknown-prefix ()
  (should (null (temme-css-expand-string "zzz:foo"))))

(ert-deftest temme-css-vendor-prefix-with-literal-value ()
  (should (equal (temme-css-expand-string "-trs:all 0.3s ease")
                 (concat "-webkit-transition: all 0.3s ease;\n"
                         "-moz-transition: all 0.3s ease;\n"
                         "-ms-transition: all 0.3s ease;\n"
                         "-o-transition: all 0.3s ease;\n"
                         "transition: all 0.3s ease;"))))

(ert-deftest temme-css-vendor-prefix-specific-with-literal-value ()
  (should (equal (temme-css-expand-string "-wm-trs:all 0.3s ease")
                 (concat "-webkit-transition: all 0.3s ease;\n"
                         "-moz-transition: all 0.3s ease;\n"
                         "transition: all 0.3s ease;"))))

;;; test-temme-mode.el ends here
