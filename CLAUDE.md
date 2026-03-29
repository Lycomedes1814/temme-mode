# temme-mode

Emacs minor mode — a rewrite of emmet-mode aiming for a clean and modern codebase while implementing all the useful features of Emmet (WIP). Emacs Lisp, lexical binding, requires Emacs 27.1+.

## Project layout

- `temme-mode.el` — HTML expansion (parsing, rendering, snippets, field navigation)
- `temme-css.el` — CSS abbreviation expansion
- `test-temme-mode.el` — ERT test suite
- `TODO.md` — remaining features

## Running tests

```sh
emacs --batch -l test-temme-mode.el -f ert-run-tests-batch-and-exit
```

All tests must pass before committing.

## Architecture

`temme-mode.el` contains HTML expansion. `temme-css.el` contains CSS expansion. Key sections:

### temme-mode.el

1. **Snippets** — `temme--snippets` (tag aliases + element snippets with default attrs) and `temme--raw-snippets` (full HTML string expansions like `!`, `doc`, `ul+`)
2. **Lorem** — `temme--lorem-words` word pool, `temme--lorem-p` predicate, `temme--lorem-generate` function
3. **Parser** — recursive descent: `temme--parse-expression` → `temme--parse-primary` → `temme--parse-element`. Produces `temme-node` structs assembled into `temme-fragment` structs. Elements with no explicit tag name get a `nil` tag, resolved by `temme--resolve-implicit-tags` after the full tree is built (called from `temme-parse`)
4. **Renderer** — `temme-render-node` → `temme--render-once`. Handles numbering (`$`, `$$`, `$@N` offset, `$@-` / `$@-N` reverse), lorem expansion, indentation
5. **Field navigation** — `temme-field-mode`, a transient minor mode. `temme--collect-fields` finds fillable positions (empty attrs, prefix attrs, empty tag content, explicit `|` markers). TAB/S-TAB cycle fields
6. **Interactive command** — `temme-expand` (C-c ,) reads HTML abbreviation from point, inserts result and activates fields

### temme-css.el

1. **Data tables** — `temme--css-properties` (prefix→property alist), `temme--css-keywords` (abbreviation→full declaration alist)
2. **Parser** — `temme--css-parse-abbrev` entry point (delegates to `temme--css-parse-abbrev-1` for base parsing). Handles vendor prefixes (`-abbrev` for all vendors, `-wm-abbrev` for specific vendors via `temme--css-parse-vendor-prefix`), literal value syntax (`prop:value` for arbitrary values, e.g. `trs:all 0.3s ease`), keyword lookup, property prefix matching (with bare prefix support), numeric values with units, multi-values (hyphen-separated), negative numbers, colors, and unitless properties
3. **Interactive command** — `temme-css-expand` (C-c .) reads CSS abbreviation from point and inserts the declaration

## Conventions

- `defconst` for static data (snippets, void tags, word pools)
- Parsing functions return `(value . next-pos)` cons cells
- Rendering functions return strings (no buffer mutation)
- Two-space indent for nested HTML output (`temme-indent-offset`)
- Raw snippets use `|` for explicit field marker positions
- Tests use `temme-expand-string` for pure expansion tests, `temme-css-expand-string` for CSS expansion tests, and `temme-test-with-expansion` macro for buffer/field tests
