![Version](https://img.shields.io/badge/version-0.0.0-orange.svg?style=for-the-badge)
![TextMate](https://img.shields.io/badge/textmate-2.0.23-green.svg?style=for-the-badge)
![macOS](https://img.shields.io/badge/macos-ventura-yellow.svg?style=for-the-badge)

# Python Ruff Linter for TextMate2

[Ruff][01] is an extremely fast Python linter, written in Rust. This is the
TextMate bundle implementation of ruff linter. 

Bundle calls ruff linter after save operation. Ruff has auto fix feature. If
you set `TM_PYRUFF_ENABLE_AUTOFIX` TextMate environment variable, bundle
applies auto fix first, than lints the code and pops up result!

![Markers](screens/markers.gif)

![Tool Tip Err](screens/tool-tip-err.png)

---

## Installation

You need to install `ruff`. I prefer `brew`. It’s also available via `pip`;

```bash
$ brew install ruff
$ cd ~/Library/Application\ Support/TextMate/Bundles/
$ git clone https://github.com:vigo/textmate2-ruff-linter.git Python-Ruff-Linter.tmbundle
```

### TextMate Environment Variables

| Variable | Description | Default Value |
|:---------|:------------|---------------|
| `TM_PYRUFF` | Path of executable; example: `/opt/homebrew/bin/ruff` | not set |
| `TM_PYRUFF_ENABLE_AUTOFIX` | Enable automatically fix lint violations | `false` |
| `TM_PYRUFF_TOOLTIP_LINE_LENGTH` | TextMate tool tip width in chars | `120` |
| `TM_PYRUFF_TOOLTIP_BORDER_CHAR` | Top and bottom line’s char | `-` |
| `TM_PYRUFF_TOOLTIP_LEFT_PADDING` | Padding value for lines to fit in tool tip window | `20` |
| `TM_PYRUFF_DEBUG` | Enable debug mode | `false` |

TextMate sometimes doesn’t apply environment variable creation from command-line.
If this doesn’t work, you need to app manually from **TextMate > Settings** pull down
menu.

```bash
$ defaults write com.macromates.TextMate environmentVariables \
    -array-add "{enabled = 1; value = \"$(command -v ruff)\"; name = \"TM_PYRUFF\"; }"

# enable auto fix
$ defaults write com.macromates.TextMate environmentVariables \
    -array-add "{enabled = 1; value = \"true\"; name = \"TM_PYRUFF_ENABLE_AUTOFIX\"; }"
```

---

## Contributor(s)

* [Uğur "vigo" Özyılmazel](https://github.com/vigo) - Creator, maintainer

---

## Contribute

All PR’s are welcome!

1. `fork` (https://github.com/vigo/textmate2-ruff-linter/fork)
1. Create your `branch` (`git checkout -b my-features`)
1. `commit` yours (`git commit -am 'implement new features'`)
1. `push` your `branch` (`git push origin my-features`)
1. Than create a new **Pull Request**!

---

## License

This project is licensed under MIT

---

[01]: https://beta.ruff.rs/docs/
