$script:ModuleRoot = $PSScriptRoot
$script:ConfigPath = if ($env:LOCALAPPDATA) {
    Join-Path $env:LOCALAPPDATA "GroupManager/config.json"
} else {
    Join-Path "$HOME/.local/share" "GroupManager/config.json"
}
$script:GroupId = $null
$script:GroupName = $null
$script:ModuleVersion = (Import-PowerShellDataFile "$script:ModuleRoot\GroupManager.psd1").ModuleVersion

# Dot-source private functions
foreach ($file in (Get-ChildItem "$script:ModuleRoot\Private\*.ps1" -ErrorAction SilentlyContinue)) {
    . $file.FullName
}

# Dot-source public functions
foreach ($file in (Get-ChildItem "$script:ModuleRoot\Public\*.ps1" -ErrorAction SilentlyContinue)) {
    . $file.FullName
}
