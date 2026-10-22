# Repository guidance

## Installing locally for testing

- Installing means updating the running desktop, not just the files on disk.
  The installed plugin is `~/.config/omarchy/plugins/elendal.panorama`.
- Inspect its Git status before updating. Preserve local changes and save a
  rollback ref before installing a committed test build. When possible, fetch
  the task checkout locally and fast-forward the installed checkout to the
  intended commit. Keep the user's settings in `shell.json` intact.
- Validate the installed directory with `omarchy plugin validate <path>` and
  verify its commit matches the intended build.
- **Restart Omarchy Shell after installing QML changes**, including changes to
  imported files such as `SettingsView.qml`. File watching and
  `omarchy-shell shell rescanPlugins` can leave cached QML running. A successful
  rescan, matching Git HEAD, or successful IPC call does not prove the new UI
  is loaded.
- Close Panorama with `omarchy-shell panorama close` before running
  `omarchy restart shell`, so its temporary blur changes are restored. Respect
  the restart command's lock-screen safeguards. Wait for the shell and Panorama
  IPC target to become ready, then open `omarchy-shell panorama settings open`.
- **Verify the actual desktop before claiming success.** Capture and inspect
  the running panel, checking a visible feature of the installed change. For
  the settings reorganization, verify all six pages and explanatory text.
  Offscreen test renders are useful validation, but are not installation proof.
  Leave the requested UI open for the user to test. If live verification fails,
  fix the installation or report the remaining blocker explicitly.

## Pull requests from contributors

- In the PR description, include `AI models used: None` if no AI helped create
  or edit the contribution. Otherwise, list every AI model used to create or
  edit the code, tests, or PR text with its most specific available name and
  version, for example
  `AI models used: GPT-6 Astra, Claude Sonnet 4.5`.
- Routine automated review bots do not need to be listed.
- This requirement applies to contributors other than the repository owner.
  Do not guess a model version; check the tool's model setting before opening
  the PR.
- If the tool exposes a reasoning level or effort setting, include it for each
  listed model in the PR description, for example
  `Reasoning levels: GPT-6 Astra: high`. If the tool does not expose it, say
  `Reasoning levels: Unavailable (not exposed by tool)`. Do not guess. An
  unavailable or missing reasoning level must not block the PR.

## Release workflow

- Treat `manifest.json` as the release source of truth and bump its semantic
  version for every published release.
- Validate with `./validate`. It runs the QML unit tests in `tests/`,
  `qmllint`, shell syntax checks for the helper scripts, and
  `omarchy plugin validate .`. The `qmltestrunner` and `qmllint` on PATH are
  Qt 5 builds that silently do nothing useful; the script calls the Qt 6
  binaries in `/usr/lib/qt6/bin` directly.
- The README demo is a GitHub release asset, not a tracked file, so clones stay
  small. Attach replacement media to a release and update the README link.
- Panorama is a fork of `https://github.com/kristofferR/omarchy-expose`; the
  upstream author owns Exposé's plugin catalog entry. Do not edit it from here.
