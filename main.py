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
import traceback
from datetime import datetime
from pathlib import Path

APP_NAME = "USB Swiss Army Knife"
APP_VERSION = "0.2.0"


def local_app_data_dir():
    base = os.environ.get("LOCALAPPDATA") or str(Path.home())
    return Path(base) / "ForensicsByte" / "UsbSwissArmyKnife"


def log_path():
    log_dir = local_app_data_dir() / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    return log_dir / "launcher.log"


def write_log(message):
    try:
        with log_path().open("a", encoding="utf-8") as handle:
            handle.write(f"[{datetime.now().isoformat(timespec='seconds')}] {message}\n")
    except Exception:
        pass


def pause_before_exit(exit_code):
    """Keep double-clicked console windows open long enough to read failures."""
    try:
        print("")
        print(f"Exit code: {exit_code}")
        print(f"Log file: {log_path()}")
        input("Press Enter to close USB Swiss Army Knife...")
    except Exception:
        pass


def resource_path(relative_path):
    base_path = getattr(sys, "_MEIPASS", None)
    if base_path:
        return Path(base_path) / relative_path
    return Path(__file__).resolve().parent / relative_path


def main():
    write_log(f"Starting {APP_NAME} v{APP_VERSION}")
    write_log(f"Executable path: {Path(sys.argv[0]).resolve()}")
    write_log(f"Working directory: {Path.cwd()}")

    if os.name != "nt":
        print(f"{APP_NAME} v{APP_VERSION}")
        print("This launcher is intended for Windows because it runs a bundled PowerShell menu.")
        write_log("Non-Windows launch rejected.")
        return 1

    script = resource_path(Path("resources") / "usak_menu.ps1")
    write_log(f"Resolved menu script: {script}")
    if not script.exists():
        msg = f"Unable to find bundled menu script: {script}"
        print(msg)
        write_log(msg)
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
    write_log("Launching bundled PowerShell menu.")

    try:
        completed = subprocess.run(command, check=False)
        write_log(f"PowerShell menu exited with code {completed.returncode}.")
        return int(completed.returncode or 0)
    except KeyboardInterrupt:
        print("\nExiting.")
        write_log("Interrupted by user.")
        return 130
    except Exception as exc:
        print(f"Failed to start bundled menu: {exc}")
        write_log("Launcher exception:\n" + traceback.format_exc())
        return 1


if __name__ == "__main__":
    code = main()
    # Keep the console visible even on success for now. This is an early console tool,
    # and double-click launches otherwise close too quickly for testers to report issues.
    pause_before_exit(code)
    sys.exit(code)
