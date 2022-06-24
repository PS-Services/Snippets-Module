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
