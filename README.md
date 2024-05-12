![Version](https://img.shields.io/badge/version-1.0.1-orange.svg?style=for-the-badge)
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
Set the `TM_PYRUFF` variable to your `ruff` binary. There is a fall-back mechanism,
if you have already installed `ruff`, bundle check the command existance with
`command -v ruff` if `TM_PYRUFF` is not set. If both fails, you need to set the
value of `TM_PYRUFF` by hand :)

```bash
brew install ruff
cd "${HOME}/Library/Application\ Support/TextMate/Bundles/"
git clone https://github.com/vigo/textmate2-ruff-linter.git Python-Ruff-Linter.tmbundle
```

TextMate sometimes doesn’t apply environment variable creation from
command-line. If this doesn’t work, you need to apply/set manually from
**TextMate > Settings > Variables** pull down menu.

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

For older users like myself, you can define the tooltip to make it easier to
read:

```bash
defaults write com.macromates.TextMate NSToolTipsFontSize 24
```

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

You can also pass extra options with using `TM_PYRUFF_OPTIONS` variable. If
you don’t have `.ruff.toml`, you can set `TM_PYRUFF_OPTIONS` for custom format
or custom check operations (via `.tm_properties` or **TextMate > Settings > Variables**):

`.tm_properties` file:

    TM_PYRUFF_OPTIONS="--config \"format.quote-style = 'single'\""

**TextMate > Settings > Variables** (you don’t need to escape quotes):

    TM_PYRUFF_OPTIONS  --config "format.quote-style = 'single'"

Keep in mind, `TM_PYRUFF_OPTIONS` passed on `format` and `check` operations.

---

## Hot Keys and Snippets

| Hot Keys and TAB Completions |   | Description |
|:-----|:-----|:-----|
| <kbd>⌥</kbd> + <kbd>F</kbd> | <small>(option + F)</small> | Trigger autofix manually |
| <kbd>⌥</kbd> + <kbd>A</kbd> | <small>(option + A)</small> | Add `# NOQA` to all problematic lines |
| <kbd>⌥</kbd> + <kbd>G</kbd> | <small>(option + G)</small> | Go to error marked line/column |
| <kbd>⌥</kbd> + <kbd>T</kbd> | <small>(option + T)</small> | `tm_properties` helper |
| <kbd>⌥</kbd> + <kbd>T</kbd> | <small>(option + T)</small> | `.ruff.toml` config helper |
| <kbd>⌥</kbd> + <kbd>D</kbd> | <small>(option + D)</small> | Enable / Disable format for selected lines |
| `disable` + <kbd>⇥</kbd> | <small>(type "disable<TAB>")</small> | Adds `# TM_PYRUFF_DISABLE` text |
| `noq` + <kbd>⇥</kbd> | <small>(type "noq<TAB>")</small> | Some noqa options |
| `envi` + <kbd>⇥</kbd> | <small>(type "envi<TAB>")</small> | Insert environment variables, works in `tm_properties` |

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
or try to copy error text from modal dialog.

Logger output should look like this:

    [2024-05-11 00:49:07][Python-RUFF][WARN][storage.rb->destroy]: storage.destroy not found for 097AA1A0-89C7-4686-A3BC-F0585962E974 - (/tmp/textmate-ruff-097AA1A0-89C7-4686-A3BC-F0585962E974.error)
    [2024-05-11 00:49:07][Python-RUFF][INFO][storage.rb->destroy]: storage.destroy for 097AA1A0-89C7-4686-A3BC-F0585962E974 - (/tmp/textmate-ruff-097AA1A0-89C7-4686-A3BC-F0585962E974.goto)
    [2024-05-11 00:49:07][Python-RUFF][DEBUG][linter.rb->run]: cmd: /opt/homebrew/bin/ruff | nil input: true | args: ["check", "--add-noqa"]
    [2024-05-11 00:49:07][Python-RUFF][WARN][linter.rb->noqalize]: err: "Added 5 noqa directives.\n"
    [2024-05-11 00:49:15][Python-RUFF][WARN][storage.rb->destroy]: storage.destroy not found for 097AA1A0-89C7-4686-A3BC-F0585962E974 - (/tmp/textmate-ruff-097AA1A0-89C7-4686-A3BC-F0585962E974.error)
    [2024-05-11 00:49:15][Python-RUFF][DEBUG][linter.rb->run]: cmd: /opt/homebrew/bin/ruff | nil input: false | args: ["check", "--select", "I", "--fix", "-"]
    [2024-05-11 00:49:15][Python-RUFF][DEBUG][linter.rb->run]: cmd: /opt/homebrew/bin/ruff | nil input: false | args: ["format", "-"]
    [2024-05-11 00:49:15][Python-RUFF][ERROR][ruff_linter.rb->run_document_will_save]: errors_format_code: nil
    [2024-05-11 00:49:15][Python-RUFF][WARN][storage.rb->get]: storage.get not found for 097AA1A0-89C7-4686-A3BC-F0585962E974 (/tmp/textmate-ruff-097AA1A0-89C7-4686-A3BC-F0585962E974.error)
    [2024-05-11 00:49:15][Python-RUFF][DEBUG][linter.rb->run]: cmd: /opt/homebrew/bin/ruff | nil input: true | args: ["check", "--output-format", "grouped"]

Keep in mind that when logging is enabled, there may be some performance
degradation due to *file I/O* operations.

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

**2024-05-12**

- Add toggle format enable/disable with option+D
- Improve README file

---

**2024-05-11**

Small updates, fixes

- Remove `TextMate::UI.tooltip` due to TextMate memory leaks/crashes and M-CPU
  problems. Return back to  basic/safe tool tip.
- Improve error handling
- Improve logging
- Add extra snippets
- Add `tm_properties` helpers
- Add `.ruff.toml` config helper

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

