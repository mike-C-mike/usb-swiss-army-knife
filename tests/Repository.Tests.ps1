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


    It 'uses unique build preset identifiers' {
        $ids = @($BuildPresets.presets.id)
        @($ids | Sort-Object -Unique).Count | Should -Be $ids.Count
    }

    It 'uses only known catalog ids in build presets' {
        $catalogIds = @($Catalog.items.id)
        foreach ($preset in $BuildPresets.presets) {
            foreach ($itemId in @($preset.itemIds)) {
                $itemId | Should -BeIn $catalogIds
            }
        }
    }



    It 'does not use strict-mode-unsafe Measure-Object Sum access for content sizes' {
        $scriptPath = Join-Path $RepositoryRoot 'Usb-SwissArmyKnife.ps1'
        $content = Get-Content $scriptPath -Raw

        $content | Should -Not -Match 'Measure-Object\s+-Property\s+Length\s+-Sum'
        $content | Should -Not -Match 'Measure-Object\s+-Property\s+SizeBytes\s+-Sum'
        $content | Should -Match 'function Get-PathContentSize'
        $content | Should -Match 'function Get-ObjectSizeTotal'
    }


    It 'supports changing the active repository during interactive use' {
        $scriptPath = Join-Path $RepositoryRoot 'Usb-SwissArmyKnife.ps1'
        $content = Get-Content $scriptPath -Raw

        $content | Should -Match 'function Invoke-RepositoryLocationMenu'
        $content | Should -Match 'function Confirm-ActiveRepositoryForOperation'
        $content | Should -Match 'Change active toolkit repository'
        $content | Should -Match '\$script:RootPath'
    }

    It 'maps a selected removable drive to a toolkit repository subfolder' {
        $scriptPath = Join-Path $RepositoryRoot 'Usb-SwissArmyKnife.ps1'
        $content = Get-Content $scriptPath -Raw

        $content | Should -Match "Join-Path .*'usb-swiss-army-knife'"
        $content | Should -Match "USE \\$\\(\\$drive\\.DeviceID\\)"
    }

}
