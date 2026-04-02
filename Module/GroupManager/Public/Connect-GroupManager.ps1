function Connect-GroupManager {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph for GroupManager operations.
    .DESCRIPTION
        Establishes a connection to Microsoft Graph with the required scopes.
        Uses custom app registration if configured via Set-GroupManagerAuth.
    .PARAMETER Force
        Disconnect and reconnect even if already connected.
    .EXAMPLE
        Connect-GroupManager
    .EXAMPLE
        Connect-GroupManager -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    $env:AZURE_CLIENT_DISABLE_WAM = "true"

    $customClientId = if ($env:GROUPMANAGER_CLIENTID) { $env:GROUPMANAGER_CLIENTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_CLIENTID', 'User') }
    $customTenantId = if ($env:GROUPMANAGER_TENANTID) { $env:GROUPMANAGER_TENANTID } else { [System.Environment]::GetEnvironmentVariable('GROUPMANAGER_TENANTID', 'User') }

    $GraphContext = Get-MgContext

    if ($Force -and $GraphContext) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        $GraphContext = $null
    }

    if (-not $GraphContext) {
        Write-Host ""
        Write-Host "  Connecting to Microsoft Graph..." -ForegroundColor Cyan

        if ($customClientId -and $customTenantId) {
            Write-Host "  Using custom app registration" -ForegroundColor DarkGray
            Connect-MgGraph -ClientId $customClientId -TenantId $customTenantId -Scopes "GroupMember.ReadWrite.All", "User.Read.All" -NoWelcome -WarningAction SilentlyContinue
        }
        else {
            Connect-MgGraph -Scopes "GroupMember.ReadWrite.All", "User.Read.All" -NoWelcome -WarningAction SilentlyContinue
        }
    }
    else {
        Write-Host "  Already connected as $($GraphContext.Account)" -ForegroundColor Green
    }
}
