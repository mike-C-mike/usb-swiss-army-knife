# Release Checklist

- [ ] Build on Windows using `build_release.ps1`.
- [ ] Launch `UsbSwissArmyKnife.exe`.
- [ ] Start a new guided build.
- [ ] Test IT Support, DFIR, OSINT, and Everything purpose selections.
- [ ] Generate CSV planning files.
- [ ] Generate CSV plus XLSX planning files.
- [ ] Edit `ToolList_SOURCE_OF_TRUTH.csv`, remove or set at least one item to `No`, then build to a test folder.
- [ ] Confirm excluded/removed tool entries are not written to the target.
- [ ] Confirm no third-party binaries are included.
- [ ] Confirm release ZIP and SHA256 files are created.
