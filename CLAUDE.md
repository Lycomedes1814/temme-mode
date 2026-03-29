# temme-mode

Emacs minor mode — a rewrite of emmet-mode aiming for a clean and modern codebase while implementing all the useful features of Emmet (WIP). Emacs Lisp, lexical binding, requires Emacs 27.1+.

## Project layout

- `temme-mode.el` — HTML and CSS expansion (parsing, rendering, snippets, field navigation)
- `test-temme-mode.el` — ERT test suite
- `TODO.md` — remaining features

## Running tests

```sh
emacs --batch -l test-temme-mode.el -f ert-run-tests-batch-and-exit
```

All tests must pass before committing.

## Architecture

`temme-mode.el` contains everything. Key sections:

1. **Snippets** — `temme--snippets` (tag aliases + element snippets with default attrs) and `temme--raw-snippets` (full HTML string expansions like `!`, `doc`, `ul+`)
2. **Lorem** — `temme--lorem-words` word pool, `temme--lorem-p` predicate, `temme--lorem-generate` function
3. **HTML parser** — recursive descent: `temme--parse-expression` → `temme--parse-primary` → `temme--parse-element`. Produces `temme-node` structs assembled into `temme-fragment` structs. Elements with no explicit tag name get a `nil` tag, resolved by `temme--resolve-implicit-tags` after the full tree is built (called from `temme-parse`)
4. **Renderer** — `temme-render-node` → `temme--render-once`. Handles numbering (`$`, `$$`, `$@N` offset, `$@-` / `$@-N` reverse), lorem expansion, indentation
5. **Field navigation** — `temme-field-mode`, a transient minor mode. `temme--collect-fields` finds fillable positions (empty attrs, prefix attrs, empty tag content, explicit `|` markers). TAB/S-TAB cycle fields. Used by both HTML and CSS expansion
6. **CSS expansion** — `temme--css-properties` (prefix→property alist), `temme--css-keywords` (abbreviation→full declaration alist). `temme--css-parse-abbrev` entry point (delegates to `temme--css-parse-abbrev-1` for base parsing). Handles vendor prefixes (`-abbrev` for all vendors, `-wm-abbrev` for specific vendors via `temme--css-parse-vendor-prefix`), literal value syntax (`prop:value` for arbitrary values, e.g. `trs:all 0.3s ease`), keyword lookup, property prefix matching (with bare prefix support), numeric values with units, multi-values (hyphen-separated), negative numbers, colors, and unitless properties
7. **Interactive commands** — `temme-expand` (C-c ,) reads HTML abbreviation from point, inserts result and activates fields. `temme-css-expand` (C-c .) reads CSS abbreviation from point, inserts the declaration and activates fields for empty values

## Conventions

- `defconst` for static data (snippets, void tags, word pools)
- Parsing functions return `(value . next-pos)` cons cells
- Rendering functions return strings (no buffer mutation)
- Two-space indent for nested HTML output (`temme-indent-offset`)
- Raw snippets use `|` for explicit field marker positions
- Tests use `temme-expand-string` for pure HTML expansion tests, `temme-css-expand-string` for CSS expansion tests, `temme-test-with-expansion` macro for HTML buffer/field tests, and `temme-test-with-css-expansion` macro for CSS buffer/field tests
