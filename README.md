# temme-mode

`temme-mode` is an Emacs minor mode for writing HTML without typing it all
out by hand. Instead of manually opening and closing every tag, you type a
short abbreviation, hit `C-c ,`, and get the full markup. For example,
`ul>li.item$*3` expands to:

```html
<ul>
  <li class="item1"></li>
  <li class="item2"></li>
  <li class="item3"></li>
</ul>
```

![temme-mode demo](demo.gif)

The abbreviation syntax is compact but expressive: `>` nests tags, `+` adds
siblings, `*3` repeats, `.class` and `#id` set attributes, and `{text}` adds
content — so a single line can describe an entire block of markup. After
expansion, TAB through empty attributes and tag content to fill them in.

Built-in snippets cover common patterns too: `!` expands a full HTML5
boilerplate, `a:link` gives you an `<a>` with an `href`, `input:email`
produces a ready-made email input, and so on.

This is a from-scratch rewrite of
[emmet-mode](https://github.com/smihica/emmet-mode) with a clean single-file
implementation, lexical binding, and a straightforward parse → render →
insert pipeline. Work in progress.

## Table of contents

- [Features](#features)
- [Examples](#examples)
- [CSS abbreviations](#css-abbreviations)
  - [Vendor prefixes](#vendor-prefixes)
  - [Literal values](#literal-values)
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
- Item numbering: `li.item$*3` (`$` = sequential, `$$` = zero-padded, `$@N` = offset start, `$@-` = reverse)
- Implicit tags inferred from parent context: `ul>.item` → `li`, `tr>.cell` → `td`, `select>.opt` → `option`
- Text nodes: `p{Hello}`, with nested braces preserved literally: `p{Hello {name}}`
- Mixed inline content: `a>{Click }+em{here}` — text nodes and elements as siblings, rendered inline
- Standalone text nodes: `{raw text}` outputs the text directly with no wrapping element
- Indented output starting at the current line indentation
- Lorem ipsum placeholder text: `lorem`, `lorem10`, `p>lorem5`
- Built-in snippets for common patterns (`!`, `btn`, `a:link`, `link:css`, `input:text`, etc.)
- CSS property expansion: `m10` → `margin: 10px;`, `df` → `display: flex;`
- CSS vendor prefixes: `-trs` for all vendors, `-wm-trs` for specific vendors
- CSS literal values: `trs:all 0.3s ease` for arbitrary value strings
- Interactive HTML expansion: `M-x temme-expand` or `C-c ,`
- Interactive CSS expansion: `M-x temme-css-expand` or `C-c .`
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

Numbering with offset (`$@N` starts counting from N):

```text
ul>li.item$@3*3
```

Output:

```html
<ul>
  <li class="item3"></li>
  <li class="item4"></li>
  <li class="item5"></li>
</ul>
```

Reverse numbering (`$@-` counts down):

```text
ul>li.item$@-*3
```

Output:

```html
<ul>
  <li class="item3"></li>
  <li class="item2"></li>
  <li class="item1"></li>
</ul>
```

Combined (`$@-N` counts down starting from N+count-1):

```text
ul>li.item$@-5*3
```

Output:

```html
<ul>
  <li class="item7"></li>
  <li class="item6"></li>
  <li class="item5"></li>
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

Mixed inline content — text nodes and elements as siblings inside a parent:

```text
a>{Click }+em{here}+{ to continue}
```

Output:

```html
<a>Click <em>here</em> to continue</a>
```

Nested braces are preserved literally in text content:

```text
p{Hello {name}, welcome!}
```

Output:

```html
<p>Hello {name}, welcome!</p>
```

Standalone text node (no wrapping element):

```text
{Just some text}
```

Output:

```text
Just some text
```

Implicit tags inferred from parent context:

```text
ul>.item$*3
```

Output:

```html
<ul>
  <li class="item1"></li>
  <li class="item2"></li>
  <li class="item3"></li>
</ul>
```

The parent tag determines the implicit child tag: `ul`/`ol` → `li`, `table`/`tbody`/`thead`/`tfoot` → `tr`, `tr` → `td`, `colgroup` → `col`, `select`/`datalist`/`optgroup` → `option`. Any other parent defaults to `div`.

## CSS abbreviations

CSS abbreviations have their own expansion command: `M-x temme-css-expand`
or `C-c .`. When an abbreviation matches a CSS keyword or a property prefix
(with or without a value), it expands to a CSS declaration.

```text
m10
```

Output:

```css
margin: 10px;
```

### Values and units

Numeric values default to `px`. Use suffixes for other units:

| Abbreviation | Output |
|---|---|
| `m10` | `margin: 10px;` |
| `m10p` | `margin: 10%;` |
| `m10e` | `margin: 10em;` |
| `m10r` | `margin: 10rem;` |
| `m0` | `margin: 0;` |

Zero gets no unit. Properties like `z-index`, `opacity`, `flex-grow`,
`flex-shrink`, `order`, `line-height`, and `font-weight` are unitless by
default.

### Multiple values

Separate values with hyphens:

| Abbreviation | Output |
|---|---|
| `m10-20` | `margin: 10px 20px;` |
| `p10-20-30-40` | `padding: 10px 20px 30px 40px;` |

### Negative values

A leading hyphen makes the value negative:

| Abbreviation | Output |
|---|---|
| `m-10` | `margin: -10px;` |
| `m10--20` | `margin: 10px -20px;` |

### Color values

Use `#` for colors:

| Abbreviation | Output |
|---|---|
| `c#f00` | `color: #f00;` |
| `bgc#e0e0e0` | `background-color: #e0e0e0;` |

### Keyword abbreviations

Common property + value combinations have dedicated abbreviations:

| Abbreviation | Output |
|---|---|
| `dn` | `display: none;` |
| `db` | `display: block;` |
| `df` | `display: flex;` |
| `dg` | `display: grid;` |
| `dib` | `display: inline-block;` |
| `posa` | `position: absolute;` |
| `posf` | `position: fixed;` |
| `posr` | `position: relative;` |
| `fll` | `float: left;` |
| `flr` | `float: right;` |
| `ovh` | `overflow: hidden;` |
| `tac` | `text-align: center;` |
| `tar` | `text-align: right;` |
| `tdn` | `text-decoration: none;` |
| `ttu` | `text-transform: uppercase;` |
| `fwb` | `font-weight: bold;` |
| `fsi` | `font-style: italic;` |
| `wsn` | `white-space: nowrap;` |
| `fxdc` | `flex-direction: column;` |
| `fxww` | `flex-wrap: wrap;` |
| `aic` | `align-items: center;` |
| `aifs` / `aife` | `align-items: flex-start;` / `align-items: flex-end;` |
| `acc` / `acs` | `align-content: center;` / `align-content: stretch;` |
| `jcc` | `justify-content: center;` |
| `jcsb` / `jcsa` / `jcse` | `justify-content: space-between;` / `justify-content: space-around;` / `justify-content: space-evenly;` |
| `ffs` / `ffss` / `ffm` | `font-family: serif;` / `font-family: sans-serif;` / `font-family: monospace;` |
| `bdss` / `bdsd` / `bdsn` | `border-style: solid;` / `border-style: dashed;` / `border-style: none;` |
| `bgrn` / `bgsc` | `background-repeat: no-repeat;` / `background-size: cover;` |
| `bxzbb` | `box-sizing: border-box;` |
| `curp` | `cursor: pointer;` |
| `lisn` | `list-style: none;` |
| `ma` | `margin: auto;` |

### Vendor prefixes

Prefix an abbreviation with `-` to generate vendor-prefixed declarations.
All four vendors are included by default (`-webkit-`, `-moz-`, `-ms-`,
`-o-`), followed by the unprefixed declaration:

```text
-trs
```

Output:

```css
-webkit-transition: ;
-moz-transition: ;
-ms-transition: ;
-o-transition: ;
transition: ;
```

To select specific vendors, place vendor letters between two hyphens.
The letters are `w` (webkit), `m` (moz), `s` (ms), `o` (opera):

```text
-wm-bdrs10
```

Output:

```css
-webkit-border-radius: 10px;
-moz-border-radius: 10px;
border-radius: 10px;
```

### Literal values

Use `:` after a property prefix to provide an arbitrary literal value.
This is especially useful with vendor prefixes, where the value is
replicated across all generated lines:

```text
-trs:all 0.3s ease
```

Output:

```css
-webkit-transition: all 0.3s ease;
-moz-transition: all 0.3s ease;
-ms-transition: all 0.3s ease;
-o-transition: all 0.3s ease;
transition: all 0.3s ease;
```

It also works without vendor prefixes for values that aren't purely
numeric:

| Abbreviation | Output |
|---|---|
| `trs:all 0.3s ease` | `transition: all 0.3s ease;` |
| `d:flex` | `display: flex;` |
| `trs:all 0.3s ease-in-out` | `transition: all 0.3s ease-in-out;` |

### Property prefix table

Any property prefix expands to a declaration. With a value (e.g., `bg#f00`
→ `background: #f00;`) or without (e.g., `bg` → `background: ;`). Common
prefixes:

| Prefix | Property |
|---|---|
| `m` / `mt` / `mr` / `mb` / `ml` | `margin` / `-top` / `-right` / `-bottom` / `-left` |
| `p` / `pt` / `pr` / `pb` / `pl` | `padding` / `-top` / `-right` / `-bottom` / `-left` |
| `w` / `h` | `width` / `height` |
| `maw` / `mah` / `miw` / `mih` | `max-width` / `max-height` / `min-width` / `min-height` |
| `d` | `display` |
| `pos` / `t` / `r` / `b` / `l` | `position` / `top` / `right` / `bottom` / `left` |
| `z` | `z-index` |
| `fz` / `fw` / `fs` | `font-size` / `font-weight` / `font-style` |
| `ta` / `td` / `tt` / `ti` | `text-align` / `-decoration` / `-transform` / `-indent` |
| `lh` / `ls` | `line-height` / `letter-spacing` |
| `c` / `op` | `color` / `opacity` |
| `bg` / `bgc` / `bgi` / `bgp` / `bgs` | `background` / `-color` / `-image` / `-position` / `-size` |
| `bd` / `bdw` / `bds` / `bdc` / `bdrs` | `border` / `-width` / `-style` / `-color` / `-radius` |
| `fx` / `fxd` / `fxw` / `fxg` / `fxs` / `fxb` | `flex` / `-direction` / `-wrap` / `-grow` / `-shrink` / `-basis` |
| `ai` / `jc` | `align-items` / `justify-content` |
| `gtc` / `gtr` / `gta` | `grid-template-columns` / `-rows` / `-areas` |
| `trs` / `anim` | `transition` / `animation` |
| `cur` / `pe` / `us` | `cursor` / `pointer-events` / `user-select` |

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
| `inp` / `input:text` / `input:t` | `<input id="" type="text" name="" />` |
| `input:hidden` / `input:h` | `<input type="hidden" name="" />` |
| `input:password` / `input:p` | `<input id="" type="password" name="" />` |
| `input:email` | `<input id="" type="email" name="" />` |
| `input:url` | `<input id="" type="url" name="" />` |
| `input:search` | `<input id="" type="search" name="" />` |
| `input:datetime-local` | `<input id="" type="datetime-local" name="" />` |
| `input:month` | `<input id="" type="month" name="" />` |
| `input:week` | `<input id="" type="week" name="" />` |
| `input:time` | `<input id="" type="time" name="" />` |
| `input:tel` | `<input id="" type="tel" name="" />` |
| `input:checkbox` / `input:c` | `<input id="" type="checkbox" name="" />` |
| `input:radio` / `input:r` | `<input id="" type="radio" name="" />` |
| `input:submit` / `input:s` | `<input type="submit" value="" />` |
| `input:button` / `input:b` | `<input type="button" value="" />` |
| `input:reset` | `<input type="reset" value="" />` |
| `input:file` | `<input id="" type="file" name="" />` |
| `input:image` / `input:i` | `<input type="image" src="" alt="" />` |
| `input:number` | `<input id="" type="number" name="" />` |
| `input:range` | `<input id="" type="range" name="" />` |
| `input:date` | `<input id="" type="date" name="" />` |
| `input:color` | `<input id="" type="color" name="" />` |
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
