$moduleName = "SnippetsSystem"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $here
$modRoot = Join-Path -Path $projectRoot -ChildPath $moduleName

Write-Host "Importing module from $script:modRoot" -ForegroundColor magenta

Import-Module $modRoot -Force
$modPath = Get-Module $moduleName | select-object path | Split-Path
Describe PSReleaseTools {
    It "Has exported commands" {
        {Get-Command -Module $moduleName} | Should Be $true
    }

    It "Has a README.md file" {
        $f = Get-Item -Path $(Join-path -path $projectRoot -childpath README.md)
        $f.name | Should Be "readme.md"
    }
    Context Manifest {
        
        It "Has a manifest" {
            Get-Item -Path $modpath\$moduleName.psd1 | Should Be $True
        }

        It "Has a license URI" {
            (Get-Module $moduleName).PrivateData["PSData"]["LicenseUri"] | Should be $True
        }

        It "Has a project URI" {
            (Get-Module $moduleName).PrivateData["PSData"]["ProjectUri"] | Should be $True
        }
    
    } #context
}
