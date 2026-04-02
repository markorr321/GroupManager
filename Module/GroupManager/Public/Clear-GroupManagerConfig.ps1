function Clear-GroupManagerConfig {
    <#
    .SYNOPSIS
        Removes the saved group configuration.
    .DESCRIPTION
        Deletes the GroupManager config.json file.
    .EXAMPLE
        Clear-GroupManagerConfig
    #>
    [CmdletBinding()]
    param()

    $configPath = Get-ConfigPath
    if (Test-Path $configPath) {
        Remove-Item $configPath -Force
        Write-Host ""
        Write-Host "  GroupManager configuration cleared." -ForegroundColor Green
        Write-Host "  Run Set-GroupManagerGroup to configure groups." -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "  No configuration file found." -ForegroundColor Yellow
        Write-Host ""
    }
}
