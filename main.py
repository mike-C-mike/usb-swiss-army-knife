"""USB Swiss Army Knife console launcher.

Starts a bundled PowerShell menu so Windows users can run the utility from an
.exe without manually executing a .ps1 file.

Boundary: this project does not redistribute third-party binaries, installers,
ISOs, archives, wordlists, vendor tools, VM images, or downloaded tool content.
"""
from __future__ import print_function

import os
import subprocess
import sys
from pathlib import Path

APP_NAME = "USB Swiss Army Knife"
APP_VERSION = "0.1.4"


def resource_path(relative_path):
    base_path = getattr(sys, "_MEIPASS", None)
    if base_path:
        return Path(base_path) / relative_path
    return Path(__file__).resolve().parent / relative_path


def main():
    if os.name != "nt":
        print(f"{APP_NAME} v{APP_VERSION}")
        print("This launcher is intended for Windows because it runs a bundled PowerShell menu.")
        return 1

    script = resource_path(Path("resources") / "usak_menu.ps1")
    if not script.exists():
        print(f"Unable to find bundled menu script: {script}")
        return 1

    command = [
        "powershell.exe",
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(script),
    ]

    try:
        return subprocess.call(command)
    except KeyboardInterrupt:
        print("\nExiting.")
        return 130
    except Exception as exc:
        print(f"Failed to start bundled menu: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
