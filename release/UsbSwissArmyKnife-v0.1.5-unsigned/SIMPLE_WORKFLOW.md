# Simple Workflow

1. Run `UsbSwissArmyKnife.exe`.
2. Resume a saved session or start a new guided build.
3. Choose interaction level.
4. Choose toolkit purpose: IT Support, DFIR, OSINT, or Everything.
5. Choose package level: Minimal, Solid, or Overkill.
6. Choose CSV or CSV plus XLSX output.
7. Review/edit the generated planning files.
8. Set drive exclusions. `C:` is excluded by default.
9. Select the target drive/path for each recommended drive role.
10. Confirm before writing folders and source records.

The builder uses `FolderStructure.csv` and `ToolList.csv` as the current editable source of truth.
