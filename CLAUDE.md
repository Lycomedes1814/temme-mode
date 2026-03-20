# temme-mode

Single-file Emacs minor mode (`temme-mode.el`) implementing Emmet-style HTML abbreviation expansion from scratch. Emacs Lisp, lexical binding, requires Emacs 27.1+.

## Project layout

- `temme-mode.el` — entire implementation (parsing, rendering, snippets, field navigation)
- `test-temme-mode.el` — ERT test suite
- `TODO.md` — remaining features

## Running tests

```sh
emacs --batch -l test-temme-mode.el -f ert-run-tests-batch-and-exit
```

All tests must pass before committing.

## Architecture

Everything lives in `temme-mode.el`. Key sections in order:

1. **Snippets** — `temme--snippets` (tag aliases + element snippets with default attrs) and `temme--raw-snippets` (full HTML string expansions like `!`, `doc`, `ul+`)
2. **Lorem** — `temme--lorem-words` word pool, `temme--lorem-p` predicate, `temme--lorem-generate` function
3. **Parser** — recursive descent: `temme--parse-expression` → `temme--parse-primary` → `temme--parse-element`. Produces `temme-node` structs assembled into `temme-fragment` structs
4. **Renderer** — `temme-render-node` → `temme--render-once`. Handles numbering (`$`), lorem expansion, indentation
5. **Field navigation** — `temme-field-mode`, a transient minor mode. `temme--collect-fields` finds fillable positions (empty attrs, prefix attrs, empty tag content, explicit `|` markers). TAB/S-TAB cycle fields
6. **Interactive command** — `temme-expand` reads abbreviation from point, expands, inserts, activates fields

## Conventions

- `defconst` for static data (snippets, void tags, word pools)
- Parsing functions return `(value . next-pos)` cons cells
- Rendering functions return strings (no buffer mutation)
- Two-space indent for nested HTML output (`temme-indent-offset`)
- Raw snippets use `|` for explicit field marker positions
- Tests use `temme-expand-string` for pure expansion tests and `temme-test-with-expansion` macro for buffer/field tests
