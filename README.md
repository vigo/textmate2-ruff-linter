![Version](https://img.shields.io/badge/version-0.3.1-orange.svg?style=for-the-badge)
![TextMate](https://img.shields.io/badge/textmate-2.0.23-green.svg?style=for-the-badge)
![macOS](https://img.shields.io/badge/macos-ventura-yellow.svg?style=for-the-badge)
![macOS](https://img.shields.io/badge/macos-sonoma-yellow.svg?style=for-the-badge)
![M2](https://img.shields.io/badge/apple-M2-black.svg?style=for-the-badge)
![M3](https://img.shields.io/badge/apple-M3-black.svg?style=for-the-badge)
[![Ruff](https://img.shields.io/endpoint?style=for-the-badge&url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)
![Powered by Rake](https://img.shields.io/badge/powered_by-rake-blue?logo=ruby&style=for-the-badge)


# Python Ruff Linter for TextMate2

[Ruff][01] is an extremely fast Python linter, written in Rust. This is the
TextMate bundle implementation of ruff linter with fantastic features 🎉

![Demo 1](screens/ruff-demo-01.gif)

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

You can set environment variables on a project basis if you prefer. For this,
you can use the `.tm_properties` file under anywhere in your project root:

`.tm_properties` example:

    TM_PYRUFF=/path/to/bin/ruff
    TM_PYRUFF_ENABLE_AUTOFIX=1   # if you want to enable autofix by default

---

## Usage

After setting the `TM_PYRUFF` variable, you need to select the language as **Python Ruff**.

> **IMPORTANT**: Bundle ships with TextMate grammar: **Python Ruff**. You
**must** set your language scope to **Python Ruff** for the bundle to
function/work properly. Scope automatically loads `source.python` and 
`source.python.django` grammars. Due to TextMate’s callback flow, I was forced 
to create a separate scope. Otherwise, it would conflict with all bundles that 
use `source.python`. Due to this situation, previous version was working too
slow.

When you hit <kbd>⌘</kbd> + <kbd>S</kbd> (*save the file*) bundle runs:

- Import sorting
- Code formatting
- Autofixing autofixable errors if `TM_PYRUFF_ENABLE_AUTOFIX` is set.

You don’t need to enable `TM_PYRUFF_ENABLE_AUTOFIX` by default. You can manually
trigger by pressing <kbd>⌥</kbd> + <kbd>A</kbd> (Option + A)

If you have lint errors, you can directly navigate error by pressing
<kbd>⌥</kbd> + <kbd>G</kbd> (Option + G). User cursor keys (Up/Down) and hit
enter to jump related line:column.


## Enable / Disable Bundle or Features

To completely disable the bundle, simply assign a value to `TM_PYRUFF_DISABLE`. 
This allows you to proceed as if the bundle does not exist. Additionally, if 
the first line of your Python file contains comment **TM\_PYRUFF\_DISABLE**:

```python
# TM_PYRUFF_DISABLE
print('ok')
```

If you want to enable autofix set `TM_PYRUFF_ENABLE_AUTOFIX` variable (any value):

    TM_PYRUFF_ENABLE_AUTOFIX=1

---

## TextMate Variables

| Variable | Default Value | Description | 
|:---------|:-----|:-----|
| `ENABLE_LOGGING` |  | Set for development purposes |
| `TM_PYRUFF` |  | Binary path of `ruff` |
| `TM_PYRUFF_DISABLE` |  | Disable bundle |
| `TM_PYRUFF_ENABLE_AUTOFIX` |  | Autofix fixables on save |
| `TM_PYRUFF_OPTIONS` |  | Pass custom options if there is no config file |

---

## Hot Keys and Snippets

| Hot Keys and TAB Completions |   | Description |
|:-----|:-----|:-----|
| <kbd>⌥</kbd> + <kbd>F</kbd> | <small>(option + F)</small> | Trigger autofix manually |
| <kbd>⌥</kbd> + <kbd>A</kbd> | <small>(option + A)</small> | Add `# NOQA` to all problematic lines |
| <kbd>⌥</kbd> + <kbd>G</kbd> | <small>(option + G)</small> | Go to error marked line/column |
| `disable` + <kbd>⇥</kbd> | <small>(type "disable<TAB>")</small> | Adds `# TM_PYRUFF_DISABLE` text |
| `noq` + <kbd>⇥</kbd> | <small>(type "noq<TAB>")</small> | Some noqa options |

![Demo 2](screens/ruff-demo-02.gif)

---

## Bug Report

Please set/enable the logger via setting `ENABLE_LOGGING=1`. Logs are written to
the `/tmp/textmate-ruff.log` file. You can `tail` while running via;
`tail -f /tmp/textmate-ruff.log` in another Terminal tab. You can see
live what’s going on. Please provide the log information for bug reporting.

After you fix the source code (next run) bundle removes those files if there
is no error. According to you bug report, you can `tail` or copy/paste the
contents of error file to issue.

Also, while running bundle script (*which is TextMate’s default ruby 1.8.7*),
if error occurs, TextMate pops up an alert window. Please add that screen shot
or try to copy error text from modal dialog

---

## Personal Notes

I know and unfortunately, this wonderful editor, **TextMate**, is now in its
**final days**. I could not use many of the beauties from the UI library that
it spawned. The built-in `Ruby 1.8.7`, `Ruby 2` have always been compiled
according to the old CPU architecture and when I use `nib` files, TextMate
randomly hangs and crashes at random times. 

I couldn’t use the built-in autocompletion features and similar alert
mechanisms. (*I can generate tooltips in HTML format, but it crashes after a
while*).

If you are still using TextMate like me, I eagerly await your **comments**, **bug
reports**, and **feature requests**.

---

## Change Log

**2024-05-10**

Giga refactoring, improved code, structure and features.

- Improve error handling and alert windows
- Add go to error line feature
- Improve document will/did save error handling

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

