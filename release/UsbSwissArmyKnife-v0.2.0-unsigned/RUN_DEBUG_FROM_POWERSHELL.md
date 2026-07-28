# Run and Debug USB Swiss Army Knife

If the EXE closes too quickly or appears to fail, run it from PowerShell instead of double-clicking it.

```powershell
.\release\UsbSwissArmyKnife-v0.1.7-unsigned\UsbSwissArmyKnife.exe
```

Or from the build output:

```powershell
.\dist\UsbSwissArmyKnife.exe
```

The launcher now writes a log file here:

```text
%USERPROFILE%\UsbSwissArmyKnife\logs\launcher.log
```

The console also pauses before closing so the exit code and log path remain visible.

## Build location note

Run the build script from the folder that contains `build_release.ps1`.

If you extracted the build kit directly into your repository root, do **not** `cd` into a nested `usb_swiss_army_knife_v0_1_6_powershell_xml_escape_fix_release` folder. Just run:

```powershell
Unblock-File .\build_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build_release.ps1 -Version 0.1.7
```
