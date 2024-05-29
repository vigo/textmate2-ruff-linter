# Change Log

**2024-05-29**

- Add `ruff` version to results
- Add **Disable Ruff for file** with `noq`+TAB (adds `# ruff: noqa`)

---

**2024-05-14**

- Improve code structure (modules)
- Add report errors (rule description) preview with option+R
- Add import sort disabler (`noq<TAB>`)

---

**2024-05-12**

- Add toggle format enable/disable with option+D
- Improve README file

---

**2024-05-11**

---

Small updates, fixes

- Remove `TextMate::UI.tooltip` due to TextMate memory leaks/crashes and M-CPU
  problems. Return back to  basic/safe tool tip.
- Improve error handling
- Improve logging
- Add extra snippets
- Add `tm_properties` helpers
- Add `.ruff.toml` config helper

---

**2024-05-10**

Giga refactoring, improved code, structure and features.

- Improve error handling and alert windows
- Add go to error line feature
- Improve document will/did save error handling

---

**2024-05-06**

Mega refactoring, improved code structure and speed.

- Remove `TM_PYRUFF_DEBUG` TextMate variable.
- Add logging mechanism
- Speed improvements, integrated and tested on `ruff` version `0.4.2`
