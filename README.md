# temme-mode

`temme-mode` is a small Emacs minor mode that implements a focused subset of
Emmet-style abbreviations from scratch.

## Features

- Tag expansion: `div`
- `#id` and `.class` parsing: `section#app.shell`
- Arbitrary attributes: `input[type=text disabled]`
- `id` and `class` merging across shorthand and bracket attributes: `div#app.hero[class='wide tall']`
- Self-closing tags, including void HTML elements and explicit `.../`: `input[type=text]`, `custom-element/`
- Child, sibling, and climb-up operators: `>`, `+`, `^`
- Grouping, including multi-root group children: `(header+main)>p`
- Multipliers: `li*3`
- Text nodes: `p{Hello}`
- Indented output starting at the current line indentation
- Interactive expansion command: `M-x temme-expand` or `C-c ,`

## Example

Grouped children:

```text
(header+main)>p
```

Output:

```html
<header>
  <p></p>
</header>
<main>
  <p></p>
</main>
```

Mixed shorthand and bracket attributes:

```text
div#app.hero[class='wide tall'][data-role=card]
```

Output:

```html
<div id="app" class="hero wide tall" data-role="card"></div>
```

Self-closing elements:

```text
figure>img.hero[src=cover.jpg]/+figcaption{Cover}
```

Output:

```html
<figure>
  <img class="hero" src="cover.jpg" />
  <figcaption>Cover</figcaption>
</figure>
```

Nested layout:

```text
div>(header>h1{Title})+(main>p{Done})
```

Output:

```html
<div>
  <header>
    <h1>Title</h1>
  </header>
  <main>
    <p>Done</p>
  </main>
</div>
```

## Running tests

```sh
emacs -Q --batch -l test-temme-mode.el -f ert-run-tests-batch-and-exit
```
