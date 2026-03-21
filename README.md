# temme-mode

`temme-mode` is an Emacs minor mode that expands short CSS-selector-like
abbreviations into full HTML. Type `ul>li.item$*3`, hit `C-c ,`, and get:

```html
<ul>
  <li class="item1"></li>
  <li class="item2"></li>
  <li class="item3"></li>
</ul>
```

It supports nesting, siblings, grouping, multipliers, numbering, text content,
lorem ipsum generation, and a library of built-in snippets — all from a single
compact abbreviation. After expansion, TAB through empty attributes and tag
content to fill them in.

This is a from-scratch rewrite of
[emmet-mode](https://github.com/smihica/emmet-mode) with a clean single-file
codebase, lexical binding, and a straightforward parse → render → insert
pipeline. Work in progress.

## Table of contents

- [Features](#features)
- [Examples](#examples)
- [Snippets](#snippets)
  - [Raw snippets](#raw-snippets)
  - [Tag aliases](#tag-aliases)
  - [Element snippets](#element-snippets)
- [Field navigation](#field-navigation)
- [Running tests](#running-tests)

## Features

- Tag expansion: `div`
- `#id` and `.class` parsing: `section#app.shell`
- Arbitrary attributes: `input[type=text disabled]`
- `id` and `class` merging across shorthand and bracket attributes: `div#app.hero[class='wide tall']`
- Self-closing tags, including void HTML elements and explicit `.../`: `input[type=text]`, `custom-element/`
- Child, sibling, and climb-up operators: `>`, `+`, `^`
- Grouping, including multi-root group children: `(header+main)>p`
- Multipliers: `li*3`
- Item numbering: `li.item$*3` (`$` = sequential, `$$` = zero-padded)
- Text nodes: `p{Hello}`
- Indented output starting at the current line indentation
- Lorem ipsum placeholder text: `lorem`, `lorem10`, `p>lorem5`
- Built-in snippets for common patterns (`!`, `btn`, `a:link`, `link:css`, `input:text`, etc.)
- Interactive expansion command: `M-x temme-expand` or `C-c ,`
- Post-expansion field navigation: TAB through empty attributes and tag content (`temme-field-mode`)

## Examples

Default tag from shorthand-only input:

```text
#root.card
```

Output:

```html
<div id="root" class="card"></div>
```

Repeated children with numbering:

```text
ul>li.item$$*3
```

Output:

```html
<ul>
  <li class="item01"></li>
  <li class="item02"></li>
  <li class="item03"></li>
</ul>
```

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

Text nodes and siblings:

```text
h1.title{Hello}+p{World}
```

Output:

```html
<h1 class="title">Hello</h1>
<p>World</p>
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

Climb-up operator:

```text
div>section>p^aside
```

Output:

```html
<div>
  <section>
    <p></p>
  </section>
  <aside></aside>
</div>
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

Repeated groups:

```text
ul>(li>a)*2
```

Output:

```html
<ul>
  <li>
    <a></a>
  </li>
  <li>
    <a></a>
  </li>
</ul>
```

Lorem ipsum placeholder text:

```text
lorem5
```

Output:

```text
Lorem ipsum dolor sit amet.
```

Custom word count inside an element:

```text
p>lorem10
```

Output:

```html
<p>
  Lorem ipsum dolor sit amet consectetur adipisicing elit ab accusantium.
</p>
```

Repeated elements get varied text automatically:

```text
ul>li*2>lorem3
```

Output:

```html
<ul>
  <li>
    Lorem ipsum dolor.
  </li>
  <li>
    Sit amet consectetur.
  </li>
</ul>
```

## Snippets

Snippets expand common abbreviations into full HTML elements with default
attributes. They are composable with classes, ids, attributes, and operators.

### Raw snippets

These expand when used as the entire abbreviation:

| Abbreviation | Output |
|---|---|
| `!` / `doc` | HTML5 boilerplate (doctype, html, head, body) |
| `!!!` | `<!DOCTYPE html>` |
| `ul+` | `<ul>` with a nested `<li>` |
| `ol+` | `<ol>` with a nested `<li>` |
| `dl+` | `<dl>` with nested `<dt>` and `<dd>` |
| `table+` | `<table>` with nested `<tr>` and `<td>` |
| `select+` | `<select>` with a nested `<option>` |

### Tag aliases

| Abbreviation | Tag |
|---|---|
| `btn` | `button` |
| `bq` | `blockquote` |
| `fig` / `figc` | `figure` / `figcaption` |
| `sect` | `section` |
| `art` | `article` |
| `hdr` / `ftr` | `header` / `footer` |
| `mn` | `main` |
| `str` | `strong` |
| `dlg` | `dialog` |
| `det` / `sum` | `details` / `summary` |
| `pic` | `picture` |
| `ifr` | `iframe` |
| `fset` / `fst` | `fieldset` |
| `leg` | `legend` |
| `tarea` | `textarea` |
| `adr` | `address` |
| `tem` | `template` |
| `prog` | `progress` |
| `out` | `output` |
| `dat` | `data` |
| `emb` / `obj` | `embed` / `object` |
| `cap` / `colg` | `caption` / `colgroup` |

### Element snippets

These can be combined with classes, ids, attributes, and operators:

```text
btn.primary{Submit}
```

```html
<button class="primary">Submit</button>
```

| Abbreviation | Expansion |
|---|---|
| `a:link` | `<a href="https://"></a>` |
| `a:mail` | `<a href="mailto:"></a>` |
| `a:tel` | `<a href="tel:+"></a>` |
| `link:css` | `<link rel="stylesheet" href="" />` |
| `link:favicon` | `<link rel="icon" type="image/x-icon" href="favicon.ico" />` |
| `script:src` | `<script src=""></script>` |
| `inp` / `input:text` / `input:t` | `<input type="text" />` |
| `input:hidden` / `input:h` | `<input type="hidden" />` |
| `input:password` / `input:p` | `<input type="password" />` |
| `input:email` | `<input type="email" />` |
| `input:url` | `<input type="url" />` |
| `input:search` | `<input type="search" />` |
| `input:checkbox` / `input:c` | `<input type="checkbox" />` |
| `input:radio` / `input:r` | `<input type="radio" />` |
| `input:submit` / `input:s` | `<input type="submit" />` |
| `input:button` / `input:b` | `<input type="button" />` |
| `input:reset` | `<input type="reset" />` |
| `input:file` | `<input type="file" />` |
| `input:image` / `input:i` | `<input type="image" />` |
| `input:number` | `<input type="number" />` |
| `input:range` | `<input type="range" />` |
| `input:date` | `<input type="date" />` |
| `input:color` | `<input type="color" />` |
| `form:get` | `<form action="" method="get"></form>` |
| `form:post` | `<form action="" method="post"></form>` |
| `video:src` | `<video src=""></video>` |
| `audio:src` | `<audio src=""></audio>` |
| `meta:utf` | `<meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />` |
| `meta:vp` | `<meta name="viewport" content="width=device-width, initial-scale=1.0" />` |
| `meta:compat` | `<meta http-equiv="X-UA-Compatible" content="IE=edge" />` |
| `meta:desc` | `<meta name="description" content="" />` |
| `meta:kw` | `<meta name="keywords" content="" />` |

## Field navigation

After expanding any abbreviation, `temme-field-mode` activates automatically
and lets you TAB through fillable positions — empty attribute values,
attribute values ending in a prefix (like `https://`), and empty tag content.

| Key | Action |
|---|---|
| `TAB` | Jump to next field (moves past the expansion and exits after last) |
| `S-TAB` | Jump to previous field |
| `C-g` | Exit field navigation |

For example, expanding `a:link` produces:

```html
<a href="https://"></a>
```

The cursor lands at the end of `https://` (first field). Type a URL, press
TAB, and the cursor moves between the tags to enter link text. TAB after the
last field (or `C-g` at any point) exits field mode.

The mode indicator ` T»` appears in the mode line while field navigation is
active.

## Running tests

```sh
emacs -Q --batch -l test-temme-mode.el -f ert-run-tests-batch-and-exit
```
