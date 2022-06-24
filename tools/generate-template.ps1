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