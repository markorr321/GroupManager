function Clear-GroupManagerAuth {
    <#
    .SYNOPSIS
        Removes the saved app registration configuration.
    .DESCRIPTION
        Clears the GROUPMANAGER_CLIENTID and GROUPMANAGER_TENANTID environment
        variables, reverting to the default Microsoft Graph authentication.
    .EXAMPLE
        Clear-GroupManagerAuth
    #>
    [CmdletBinding()]
    param()

    try {
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_CLIENTID', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('GROUPMANAGER_TENANTID', $null, 'User')

        $env:GROUPMANAGER_CLIENTID = $null
        $env:GROUPMANAGER_TENANTID = $null

        Write-Host ""
        Write-Host "  Configuration cleared successfully." -ForegroundColor Green
        Write-Host "  GroupManager will use the default Microsoft Graph authentication." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  Failed to clear configuration: $_" -ForegroundColor Red
    }
}
