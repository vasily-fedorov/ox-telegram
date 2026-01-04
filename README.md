# Telegram MarkdownV2 exporter for Org Mode

This package includes `ox-telegram.el` which provides an exporter for
Telegram MarkdownV2 format.

## Telegram MarkdownV2 Features

Telegram MarkdownV2 supports:
- `**bold text**`
- `__italic text__`
- `__underline__` (no support for underline in telegram markdown)
- `~~strikethrough~~`
- `` `inline fixed-width code` ``
- ```` ```pre-formatted fixed-width code block``` ````
- `[inline URL](http://www.example.com/)`

**Important**: Special characters must be escaped: `_ * [ ] ( ) ~ \` > # + - = | { } . !`

## Usage

Exporting to Telegram MarkdownV2 is available through Org mode's export dispatcher
once `ox-telegram` is loaded. Alternatively, use `M-x org-telegram-export-to-markdown`.

To automatically load `ox-telegram` with Org mode:

```emacs-lisp
(eval-after-load "org"
  '(require 'ox-telegram nil t))
```

### Doom Emacs:

packages.el:

``` emacs-lisp
  (package! ox-telegram
    :recipe (:host github :repo "vasily-fedorov/ox-telegram"))
```

config.el:

``` emacs-lisp
(use-package! ox-telegram
  :after org
  :config (push "telegram" org-export-backends))
```

## Configuration

Customize `org-telegram-escape-special-chars` (default: t) to control whether
special characters are automatically escaped.
