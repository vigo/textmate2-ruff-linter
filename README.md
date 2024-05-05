![Version](https://img.shields.io/badge/version-0.3.1-orange.svg?style=for-the-badge)
![TextMate](https://img.shields.io/badge/textmate-2.0.23-green.svg?style=for-the-badge)
![macOS](https://img.shields.io/badge/macos-ventura-yellow.svg?style=for-the-badge)
![macOS](https://img.shields.io/badge/macos-sonoma-yellow.svg?style=for-the-badge)
[![Ruff](https://img.shields.io/endpoint?style=for-the-badge&url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)
![Powered by Rake](https://img.shields.io/badge/powered_by-rake-blue?logo=ruby&style=for-the-badge)


# Python Ruff Linter for TextMate2

[Ruff][01] is an extremely fast Python linter, written in Rust. This is the
TextMate bundle implementation of ruff linter. 

demo.gif

---

## Installation

You need to install `ruff`. I prefer `brew`. It’s also available via `pip`.
Set the `TM_PYRUFF` variable to your `ruff` binary.

```bash
brew install ruff
cd "${HOME}/Library/Application\ Support/TextMate/Bundles/"
git clone https://github.com/vigo/textmate2-ruff-linter.git Python-Ruff-Linter.tmbundle
```

TextMate sometimes doesn’t apply environment variable creation from
command-line. If this doesn’t work, you need to apply/set manually from
**TextMate > Settings** pull down menu.

```bash
$ defaults write com.macromates.TextMate environmentVariables \
    -array-add "{enabled = 1; value = \"$(command -v ruff)\"; name = \"TM_PYRUFF\"; }"

# enable auto fix
$ defaults write com.macromates.TextMate environmentVariables \
    -array-add "{enabled = 1; value = \"true\"; name = \"TM_PYRUFF_ENABLE_AUTOFIX\"; }"
```

> **IMPORTANT**: Bundle ships with TextMate grammar: **Python Ruff**. You
**must** set your language scope to **Python Ruff** for the bundle to
function/work properly. Scope automatically loads `source.python` and 
`source.python.django` grammars. Due to TextMate’s callback flow, I was forced 
to create a separate scope. Otherwise, it would conflict with all bundles that 
use `source.python`. Due to this situation, previous version was working too
slow.

---

## Enable / Disable Bundle or Features

To completely disable the bundle, simply assign a value to `TM_PYRUFF_DISABLE`. 
This allows you to proceed as if the bundle does not exist. Additionally, if 
the first line of your Python file contains comment **TM\_PYRUFF\_DISABLE**:

```python
# TM_PYRUFF_DISABLE
print('ok')
```

---

## TextMate Variables

| Variable | Default Value | Description | 
|:---------|:-----|:-----|
| `ENABLE_LOGGING` |  | Set for development purposes |
| `TOOLTIP_LINE_LENGTH` | `100` | Width of pop-up window |
| `TOOLTIP_LEFT_PADDING` | `2` | Alignment value |
| `TOOLTIP_BORDER_CHAR` | `-` | Border value |
| `TM_PYRUFF` |  | Binary path of `ruff` |
| `TM_PYRUFF_DISABLE` |  | Disable bundle |
| `TM_PYRUFF_ENABLE_AUTOFIX` |  | Autofix fixables on save |
| `TM_PYRUFF_OPTIONS` |  | Pass custom options if there is no config file |

---

## Hot Keys and Snippets

| Hot Keys and TAB Completions |   | Description |
|:-----|:-----|:-----|
| <kbd>⌃</kbd> + <kbd>⇧</kbd> + <kbd>F</kbd> | <small>(control + shift + F)</small> | Trigger autofix manually |
| <kbd>⌃</kbd> + <kbd>⇧</kbd> + <kbd>N</kbd> | <small>(control + shift + N)</small> | Add `# NOQA` to all problematic lines |
| `disable` + <kbd>⇥</kbd> | <small>(type "disable<TAB>")</small> | Adds `# TM_PYRUFF_DISABLE` text |

---

## Bug Report

Please set/enable the logger via setting `ENABLE_LOGGING=1`. Logs are written to
the `/tmp/textmate-python-ruff.log` file. You can `tail` while running via;
`tail -f /tmp/textmate-python-ruff.log` in another Terminal tab. You can see
live what’s going on. Please provide the log information for bug reporting.

After you fix the source code (next run) bundle removes those files if there
is no error. According to you bug report, you can `tail` or copy/paste the
contents of error file to issue.

Also, while running bundle script (which is TextMate’s default ruby 1.8.7),
if error occurs, TextMate pops up an alert window. Please add that screen shot
or try to copy error text from modal dialog

---

## Change Log

**2024-05-06**

Mega refactoring, improved code structure and speed.

- Remove `TM_PYRUFF_DEBUG` TextMate variable.
- Add logging mechanism
- Speed improvements, integrated and tested on `ruff` version `0.4.2`

You can read the whole story [here][changelog].

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

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [code of conduct][coc].

---

## License

This project is licensed under MIT

---

[01]: https://docs.astral.sh/ruff/
[changelog]: https://github.com/vigo/textmate2-ruff-linter/blob/main/CHANGELOG.md
[coc]: https://github.com/vigo/textmate2-ruff-linter/blob/main/CODE_OF_CONDUCT.md









