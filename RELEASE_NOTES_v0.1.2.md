# USB Swiss Army Knife v0.1.2 Release Notes

## Summary

v0.1.2 restores the intended build-plan workflow and removes the manual hash-generator options from the console menu.

## Changes

- Added selectable toolkit build plans:
  - DFIR
  - IT Support
  - OSINT
- Added plan-specific folder layouts.
- Added plan-aware README, checklist, manifest, and source-verification templates.
- Removed manual single-file and recursive hash menu items.
- Added source verification record entry support for documenting source-published hashes and official source URLs.
- Preserved the project boundary: no third-party binaries, installers, ISOs, archives, wordlists, VM images, vendor payloads, or downloaded project content are redistributed.

## Future parking lot

A later release may generate a local tool hash list after the user finishes populating a USB build. That feature should compare local hashes against source-published hashes recorded from official publisher-controlled sources where available. It should remain separate from forensic evidence hashing and should not present itself as third-party tool validation.
