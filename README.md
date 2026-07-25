# USB Swiss Army Knife

> **“If I have seen further, it is by standing on the shoulders of giants.”**  
> — Isaac Newton

USB Swiss Army Knife is a manifest-driven PowerShell builder for creating personalized portable media for IT support, recovery, DFIR, networking, OSINT, and authorized security assessment.

This repository contains **no third-party software**. It provides only the automation, menus, configuration, source metadata, validation logic, documentation, and USB profile definitions needed for each user to build their own toolkit directly from authentic upstream sources.

## Standing on the Shoulders of Giants

USB Swiss Army Knife is built in the spirit of Newton’s famous observation.

This project does not attempt to replace, repackage, or claim credit for the extraordinary tools and knowledge created by open-source developers, security researchers, forensic practitioners, standards organizations, and software vendors represented in its catalog.

Its purpose is narrower:

- Help users discover exceptional projects.
- Route them to official publisher-controlled sources.
- Automate downloads where the upstream project permits it.
- Guide users through forms, accounts, EULAs, or vendor interactions where required.
- Verify, hash, organize, update, and provision the resulting local toolkit.
- Give visible credit to the maintainers whose work makes the toolkit useful.

**USB Swiss Army Knife is connective tissue. The upstream projects provide the capability and deserve the credit.**

Users are strongly encouraged to visit upstream project pages, read their documentation, report issues, contribute code, sponsor development where possible, and recognize the people whose work makes this project possible.

See [UPSTREAM-PROJECTS.md](UPSTREAM-PROJECTS.md) and [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Project boundary

The public repository distributes:

- PowerShell automation
- Interactive console menus
- Catalog and profile metadata
- Official-source URLs and release-resolution logic
- Hash and signature-validation logic
- Documentation and tests
- Attribution and licensing records

It does **not** distribute:

- Executables or installers
- Archives
- Operating-system images
- Virtual machines
- Wordlists
- Payload repositories
- Vendor-gated software
- Mirrored upstream repositories
- Prebuilt USB or SSD images

Every user builds their own local repository from upstream sources and remains responsible for accepting and following each upstream license, EULA, account requirement, export restriction, and usage condition.

## Current capabilities

- Guided initial repository build
- Software and resource updates
- Missing-item and integrity audits
- Interactive browser-assisted vendor downloads
- Official GitHub release and branch-archive retrieval
- SHA-256 inventories
- Authenticode checks where supported
- Segmented USB profiles
- Capacity and free-space validation
- Explicit target-drive confirmation
- Non-destructive provisioning by default
- Offline resource bundles
- Generated `START-HERE.html` dashboard
- Help-desk, network, recovery, DFIR, OSINT, pentest-lab, and full-toolkit profiles

## Quick start

Requires Windows PowerShell 5.1 or PowerShell 7.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Usb-SwissArmyKnife.ps1
```

The script creates the local source repository at:

```text
C:\Users\<current-user>\usb-swiss-army-knife
```

Run without parameters to open the guided menu.

## Main menu

```text
[1] Initial repository build
[2] Update software repository
[3] Audit for missing or changed items
[4] Provision an individual USB
[5] Show USB module profiles
[6] Resources and references
[7] Open the local repository folder
[8] Open START-HERE dashboard
[0] Exit
```

## Safety and authorization

Some catalog entries support memory acquisition, disk imaging, password recovery, packet capture, OSINT, or security assessment. Use them only:

- On systems, networks, accounts, data, and credentials you own; or
- Under explicit authorization defining the permitted scope.

Portable does not mean forensically invisible. Memory acquisition, packet-capture drivers, disk mounting, and hardware access can alter a live system.

This builder does not provide hardware write blocking and does not replace validated forensic procedures.

## Licensing

USB Swiss Army Knife’s original source code and documentation are licensed under the [MIT License](LICENSE).

That license applies only to this project’s original work. It does not relicense any third-party project, tool, documentation set, trademark, or downloaded content.

## Independence statement

USB Swiss Army Knife is an independent community project. It is not affiliated with, endorsed by, sponsored by, or officially supported by any upstream project or vendor referenced in its catalog unless explicitly stated by that upstream organization.

## Status

**v0.1.0-alpha**

The project is under active development. Catalog entries, filenames, release patterns, signer names, and vendor workflows require testing across real Windows environments before a stable release.
