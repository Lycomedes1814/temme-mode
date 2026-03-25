# temme-mode TODO

## Numbering
- [x] `$` item numbering in repeated elements (`ul>li.item$*3` → `item1`, `item2`, `item3`)
- [x] `$$` zero-padded numbering
- [x] `$@N` numbering with offset
- [x] `@-` reverse numbering direction

## Implicit tag resolution
- [x] Context-aware implicit tags (`ul>.item` → `li`, `table>.row` → `tr`, `select>.opt` → `option`, etc.)

## CSS abbreviations
- [ ] CSS property expansion (`m10` → `margin: 10px;`, `p10-20` → `padding: 10px 20px;`)
- [ ] CSS vendor prefixes (`-webkit-`, `-moz-`, etc.)

## Lorem ipsum
- [x] `lorem` / `lorem10` placeholder text generation

## Wrap with abbreviation
- [ ] Wrapping selected text/lines with an abbreviation

## Filters
- [ ] `|e` escape
- [ ] `|c` comment
- [ ] `|s` single-line
- [ ] `|t` trim

## Snippets / aliases
- [x] Built-in snippets: `!` (HTML5 boilerplate), `a:link`, `input:text`, `btn`, `link:css`, `script:src`, etc.
- [ ] Custom user-defined snippets

## Advanced text
- [ ] Nested `{}` braces in text nodes
- [ ] Text mixed with child elements on the same node
- [ ] Implicit `div` for standalone `{just text}` nodes
