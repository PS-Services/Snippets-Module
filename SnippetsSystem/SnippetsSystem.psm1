$moduleName = "<%= $PLASTER_PARAM_ModuleName %>"

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
[cmdletbinding()]
param (
    $SourceFolder = $PSScriptRoot
)
#Write-Verbose -Message "Working in $SourceFolder" -verbose
$Module = Get-ChildItem -Path $SourceFolder -Filter *.psd1 -Recurse | Select-Object -First 1

$DestinationModule = "$($Module.Directory.FullName)\$($Module.BaseName).psm1"
#Write-Verbose -Message "Attempting to work with $DestinationModule" -verbose

if (Test-Path -Path $DestinationModule ) {
    Remove-Item -Path $DestinationModule -Confirm:$False -force
}

$PublicFunctions = Get-ChildItem -Path $SourceFolder -Include 'Public', 'External','Functions' -Recurse -Directory | Get-ChildItem -Include *.ps1 -File
$PrivateFunctions = Get-ChildItem -Path $SourceFolder -Include 'Private', 'Internal' -Recurse -Directory | Get-ChildItem -Include *.ps1 -File

if ($PublicFunctions -or $PrivateFunctions) {
    Write-Verbose -message "Found Private or Public functions. Will compile these into the psm1 and only export public functions."

    Foreach ($PrivateFunction in $PrivateFunctions) {
        Get-Content -Path $PrivateFunction.FullName | Add-Content -Path $DestinationModule
    }
    Write-Verbose -Message "Found $($PrivateFunctions.Count) Private functions and added them to the psm1."
}
else {
    Write-Verbose -Message "Didnt' find any Private or Public functions, will assume all functions should be made public."

    $PublicFunctions = Get-ChildItem -Path $SourceFolder -Include *.ps1 -Recurse -File
}

Foreach ($PublicFunction in $PublicFunctions) {
    Get-Content -Path $PublicFunction.FullName | Add-Content -Path $DestinationModule
}
Write-Verbose -Message "Found $($PublicFunctions.Count) Public functions and added them to the psm1."

$PublicFunctionNames = $PublicFunctions |
    Select-String -Pattern 'Function (\w+-\w+)$' -AllMatches |
    Foreach-Object {
    $_.Matches.Groups[1].Value
}
Write-Verbose -Message "Making $($PublicFunctionNames.Count) functions available via Export-ModuleMember"

"Export-ModuleMember -Function {0}" -f ($PublicFunctionNames -join ',') | Add-Content $DestinationModule

$var = Invoke-Pester -Script $SourceFolder -Show Fails #-CodeCoverage $DestinationModule -CodeCoverageOutputFile "$SourceFolder\..\$($Module.Basename)CodeCoverage.xml" -CodeCoverageOutputFileFormat JaCoCo -PassThru -Show Fails

Invoke-ScriptAnalyzer -Path $DestinationModule
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
function Set-Root {
    $name = (Split-Path $PWD.Path -Leaf)
    if ($name -imatch 'tools') {
        Write-Host "In tools folder."
        $root = Get-Item $PWD/..
    }
    if ($name -imatch 'ps-template') {
        Write-Host 'In root folder.'
        $root = Get-Item $PWD
    }
    if (-not (Test-Path $root/ps-template.sln)) {
        $sln = Get-ChildItem "ps-template.sln" -rec;

        if (-not $sln) {
            throw "Unknown `$root: $root.  Cannot locate ``ps-template.sln`` from $PWD."
        }

        $root = $sln.Directory;
    }

    Set-Location $root;

    return $root;
}

Push-Location
try{
$root = Set-Root

Set-Location $root

git clone https://github.com/MatthewJDavis/PowerShell-module-templates.git

Invoke-Plaster -DestinationPath $root -TemplatePath $root\PowerShell-module-templates\ModuleTemplate
} finally {
    Pop-Location
}
param(
    [string]$Command = $null
)

function Set-Root {
    $tools = $PSScriptRoot
    $root = Get-Item $tools/..

    if (-not (Test-Path $root/ps-template.sln)) {
        $sln = Get-ChildItem ps-template.sln -rec;

        if (-not $sln) {
            throw "Unknown `$root: $root.  Cannot locate ``ps-template.sln``."
        }

        $root = $sln.Directory;
    }

    Set-Location $root;

    return $root;
}

function Set-Tools {
    try {
        if (-not (Test-Path $root/.config/dotnet-tools.json)) {
            dotnet new tool-manifest > $output
            dotnet tool install powershell >> $output
            dotnet tool install gitversion.tool >> $output
        }
        else {
            dotnet tool restore > $output;
        }

        if ($Command -imatch 'update') {
            dotnet tool list --local `
            | Select-Object -Skip 2 `
            | ForEach-Object -Process {
                $tool = $_.Split(' ')[0];
                & dotnet tool update --local $tool >> $output
            };
        }
    }
    catch {
        throw @{ "Error"=$_; "Log"=$output }
    }

    return (Get-Item $root/.config/dotnet-tools.json);
}

function Get-NewestModule {
    param([string]$Name)
    return Get-Module $name -ErrorAction SilentlyContinue -ListAvailable `
    | Sort-Object Version -Descending `
    | Select-Object -First 1;
}

function Set-Plaster {
    $plaster = Get-Module plaster -ErrorAction SilentlyContinue -ListAvailable;

    if (-not $plaster) {
        Write-Information 'Plaster not installed.'
        Install-Module plaster -ErrorAction SilentlyContinue -Verbose;
        $plaster = Get-NewestModule plaster;
    }
    elseif ($Command -imatch 'upgrade') {
        Install-Module plaster -ErrorAction SilentlyContinue -Force;
        $plaster = Get-NewestModule plaster;
    }

    if (-not $plaster) {
        throw 'Could not install plaster.'
    }

    Import-Module plaster
    return $plaster
}

function Set-Pester {
    $pester = Get-Module pester -ErrorAction SilentlyContinue -ListAvailable;

    if (-not $pester) {
        Write-Information 'Pester not installed.'
        Install-Module pester -ErrorAction SilentlyContinue;
        $pester = Get-NewestModule pester;
    } elseif($Command -imatch "upgrade"){
        Install-Module pester -ErrorAction SilentlyContinue -Force;
        $pester = Get-NewestModule pester;
    }

    if (-not $pester) {
        throw 'Could not install pester.'
    }

    Import-Module pester
    return $pester
}

try {
    Push-Location
    $root = Set-Root;
    if ($root) {
        $tools = Set-Tools; 
    }
    $plaster = Set-Plaster;
    $pester = Set-Pester;

    Write-Host "`$root: $root";
    Write-Host "`$tools: $tools";
    Write-Host "`$plaster: $plaster";
    Write-Host "`$pester: $pester";
}
finally {
    Pop-Location
}
[cmdletbinding()]
param (
    $SourceFolder = $PSScriptRoot
)
#Write-Verbose -Message "Working in $SourceFolder" -verbose
$Module = Get-ChildItem -Path $SourceFolder -Filter *.psd1 -Recurse | Select-Object -First 1

$DestinationModule = "$($Module.Directory.FullName)\$($Module.BaseName).psm1"
#Write-Verbose -Message "Attempting to work with $DestinationModule" -verbose

if (Test-Path -Path $DestinationModule ) {
    Remove-Item -Path $DestinationModule -Confirm:$False -force
}

$PublicFunctions = Get-ChildItem -Path $SourceFolder -Include 'Public', 'External','Functions' -Recurse -Directory | Get-ChildItem -Include *.ps1 -File
$PrivateFunctions = Get-ChildItem -Path $SourceFolder -Include 'Private', 'Internal' -Recurse -Directory | Get-ChildItem -Include *.ps1 -File

if ($PublicFunctions -or $PrivateFunctions) {
    Write-Verbose -message "Found Private or Public functions. Will compile these into the psm1 and only export public functions."

    Foreach ($PrivateFunction in $PrivateFunctions) {
        Get-Content -Path $PrivateFunction.FullName | Add-Content -Path $DestinationModule
    }
    Write-Verbose -Message "Found $($PrivateFunctions.Count) Private functions and added them to the psm1."
}
else {
    Write-Verbose -Message "Didnt' find any Private or Public functions, will assume all functions should be made public."

    $PublicFunctions = Get-ChildItem -Path $SourceFolder -Include *.ps1 -Recurse -File
}

Foreach ($PublicFunction in $PublicFunctions) {
    Get-Content -Path $PublicFunction.FullName | Add-Content -Path $DestinationModule
}
Write-Verbose -Message "Found $($PublicFunctions.Count) Public functions and added them to the psm1."

$PublicFunctionNames = $PublicFunctions |
    Select-String -Pattern 'Function (\w+-\w+)$' -AllMatches |
    Foreach-Object {
    $_.Matches.Groups[1].Value
}
Write-Verbose -Message "Making $($PublicFunctionNames.Count) functions available via Export-ModuleMember"

"Export-ModuleMember -Function {0}" -f ($PublicFunctionNames -join ',') | Add-Content $DestinationModule

$var = Invoke-Pester -Script $SourceFolder -Show Fails #-CodeCoverage $DestinationModule -CodeCoverageOutputFile "$SourceFolder\..\$($Module.Basename)CodeCoverage.xml" -CodeCoverageOutputFileFormat JaCoCo -PassThru -Show Fails

Invoke-ScriptAnalyzer -Path $DestinationModule
Export-ModuleMember -Function 
