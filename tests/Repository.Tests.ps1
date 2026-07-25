BeforeAll{$r=Split-Path -Parent $PSScriptRoot;$c=Get-Content "$r\config\catalog.json" -Raw|ConvertFrom-Json;$p=Get-Content "$r\config\profiles.json" -Raw|ConvertFrom-Json}
Describe 'Repository configuration'{It 'has unique catalog ids'{($c.items.id|sort -Unique).Count|Should -Be $c.items.id.Count};It 'has unique profile ids'{($p.profiles.id|sort -Unique).Count|Should -Be $p.profiles.id.Count};It 'contains no shipped third-party binary artifacts'{@((Get-ChildItem $r -File -Recurse)|? Extension -in '.exe','.msi','.zip','.7z','.iso','.img','.vhd','.vhdx','.vmdk','.ova').Count|Should -Be 0}

    It 'contains the convenience launchers' {
        Test-Path (Join-Path $RepositoryRoot 'Start-UsbSwissArmyKnife.cmd') | Should -BeTrue
        Test-Path (Join-Path $RepositoryRoot 'Run-ProjectTests.cmd') | Should -BeTrue
    }

    It 'parses the main PowerShell script without syntax errors' {
        $scriptPath = Join-Path $RepositoryRoot 'Usb-SwissArmyKnife.ps1'
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath,
            [ref]$tokens,
            [ref]$parseErrors
        ) | Out-Null

        @($parseErrors).Count | Should -Be 0
    }

}
