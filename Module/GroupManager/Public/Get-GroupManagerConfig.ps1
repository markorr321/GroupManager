function Get-GroupManagerConfig {
    <#
    .SYNOPSIS
        Gets the current GroupManager group configuration.
    .DESCRIPTION
        Returns the list of configured groups from the GroupManager config file.
    .EXAMPLE
        Get-GroupManagerConfig
    #>
    [CmdletBinding()]
    param()

    $configPath = Get-ConfigPath
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            return $config.Groups
        }
        catch {
            return $null
        }
    }
    return $null
}
