function Show-Header {
    param([string]$Subtitle)

    $version = $script:ModuleVersion

    Clear-Host
    Write-Host ""
    Write-Host "[ E N T R A   I D   G R O U P   M A N A G E R ]  " -ForegroundColor DarkCyan -NoNewline
    Write-Host "v$version" -ForegroundColor White
    Write-Host ""
    if ($Subtitle) {
        Write-Host "$Subtitle" -ForegroundColor DarkGray
    } elseif ($script:GroupName) {
        Write-Host "Manage Group Membership - Target: $script:GroupName" -ForegroundColor DarkGray
    }
}
