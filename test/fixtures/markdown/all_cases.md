# ViewIm Markdown Playground

This single file contains all major markdown/html-at-cursor cases.
Move cursor onto each example (or nearby) and run `:ViewImageAtCursor`.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed non sem a sem
congue dictum. Vivamus varius, justo in porttitor ultrices, augue turpis
eleifend nunc, vel facilisis magna sem id justo.

## 1) Inline markdown image

Curabitur at metus id nibh feugiat vulputate.

![inline png](../images/pixel.png)

## 2) Reference-style markdown image

Praesent tincidunt, magna non scelerisque faucibus, erat augue feugiat magna,
vel faucibus magna justo nec velit.

![reference bmp][green-pixel]

[green-pixel]: ../images/pixel.bmp

## 3) Multiline HTML img tag inside markdown

Donec viverra lorem vel lorem bibendum, at gravida massa malesuada.

<img
  alt="multiline gif"
  src="../images/pixel.gif"
  width="24"
/>

## 4) Root-relative path mapping test

When Neovim cwd is the repo root, this should resolve via cwd fallback.

![root relative](/test/fixtures/images/pixel.png)

## 5) Remote URL image

Requires `remote.enabled=true` and `curl` in PATH.

![remote image](https://raw.githubusercontent.com/github/explore/main/topics/neovim/neovim.png)

## 6) Nearest-source fallback

Put cursor on this paragraph and run `:ViewImageAtCursor`.
It should pick the nearest image source from nearby sections.

Mauris non massa luctus, facilisis lectus eget, sodales est. Integer congue
ultricies metus, vitae pellentesque nunc fermentum sed.
