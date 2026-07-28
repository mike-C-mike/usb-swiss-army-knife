# USB Swiss Army Knife v0.2.7

## CI Parse + Drive Mapping Fix

This maintenance release tightens the root `Usb-SwissArmyKnife.ps1` compatibility launcher so repository validation can parse it cleanly and detect the expected removable-drive repository mapping pattern.

## Changes

- Rewrites the root launcher with simpler PowerShell syntax.
- Preserves CI-required helper functions.
- Preserves the selected removable-drive repository mapping under `usb-swiss-army-knife`.
- Keeps the v0.2.x guided menu, source-of-truth CSV, transparency, and download workflow intact.

## Boundary

This project creates toolkit structures, editable lists, source records, controlled downloads, and hash manifests. It does not silently install tools, format drives, erase drives, bundle third-party binaries, or redistribute third-party tools.
