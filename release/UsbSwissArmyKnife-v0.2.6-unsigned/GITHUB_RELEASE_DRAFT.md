# USB Swiss Army Knife v0.2.6 Unsigned Pre-Release

This patch fixes CI/test-runner compatibility after the v0.2.x download transparency work.

## Highlights

- Fixes `Run-ProjectTests.cmd` path resolution.
- Avoids `$PSScriptRoot` inside parameter defaults.
- Preserves root convenience launchers.
- Preserves the v0.2.x source-of-truth CSV, download transparency, download manifest, and local hash workflow.

## Boundary

This release does not install software, format drives, erase drives, redistribute third-party binaries, or silently execute downloaded tools.
