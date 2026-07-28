# USB Swiss Army Knife

USB Swiss Army Knife is a console-based toolkit builder that launches as an EXE and guides a user through creating USB toolkit folder structures and documentation templates.

It is intentionally not a downloader and does not redistribute third-party binaries, installers, ISOs, archives, wordlists, VM images, vendor tools, or downloaded content.

## v0.1.3 focus

This release restores the original guided-build concept:

1. Resume a saved session when one exists.
2. Ask the user for interaction level:
   - Full Guided
   - Intermediate
   - Custom
3. Ask toolkit purpose:
   - IT Support
   - DFIR
   - OSINT
4. Ask package level:
   - Minimal
   - Solid
   - Overkill
5. Generate a drive build path with suggested USB sizes and roles.
6. Ask for a drive exclusion list.
7. Ask which detected or manual drive/path to write to.
8. Write folders and templates.
9. Ask whether to continue to the next sized/role drive.

## Build

```powershell
Unblock-File .uild_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.uild_release.ps1 -Version 0.1.3
```

## Boundary

This project creates structures and records. Users populate tools locally from official publisher-controlled sources and should record license, version, source URL, attribution, and source-published hashes where available.
