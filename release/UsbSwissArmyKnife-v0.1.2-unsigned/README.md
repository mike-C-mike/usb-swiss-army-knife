# USB Swiss Army Knife v0.1.2

USB Swiss Army Knife is a console EXE launcher for building and maintaining local USB toolkit folder structures without asking users to manually run a PowerShell script.

## What changed in v0.1.2

- Adds selectable build plans: **DFIR**, **IT Support**, and **OSINT**.
- The selected build plan controls the folder structure and templates created on the USB/toolkit root.
- Removes manual hash-generator menu options.
- Adds a **source verification** record workflow so users can document official source URLs and source-published hashes without presenting this utility as a hash tool.
- Keeps the public project clean: no third-party tools, installers, ISOs, archives, wordlists, VM images, vendor payloads, or downloaded content are redistributed.

## Build plans

### DFIR
Digital forensics and incident-response oriented layout with folders for acquisition, memory, mobile, triage, validation, viewers, incident response, Ventoy, ISOs, and VM notes.

### IT Support
Support-oriented layout with folders for drivers, diagnostics, installers, networking, Windows repair, remote support, scripts, and portable utilities.

### OSINT
OSINT-oriented layout with folders for source capture notes, screenshots, citations, timelines, collection templates, link analysis, media review, maps/geolocation, and offline reference material.

## Build on Windows

```powershell
Unblock-File .uild_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.uild_release.ps1 -Version 0.1.2
```

The build script creates an unsigned release ZIP and checksum files under `release\`.

## Boundary

This project is a structure, menu, documentation, and local record-keeping tool. It does not provide third-party payloads and does not validate third-party tools for the user.
