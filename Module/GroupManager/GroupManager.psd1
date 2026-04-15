@{
    RootModule        = 'GroupManager.psm1'
    ModuleVersion     = '1.4.0'
    GUID              = '343209db-15f3-4371-8b5b-0abbae46e1d0'
    Author            = 'Mark Orr'
    Copyright         = '(c) Mark Orr. All rights reserved.'
    Description       = 'Entra ID Group Manager - Add and remove users from Entra ID security groups via an interactive TUI or individual cmdlets.'
    PowerShellVersion = '5.1'

    RequiredModules   = @(
        @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }
        @{ ModuleName = 'Microsoft.Graph.Groups';         ModuleVersion = '2.0.0' }
        @{ ModuleName = 'Microsoft.Graph.Users';          ModuleVersion = '2.0.0' }
    )

    FunctionsToExport = @(
        'Start-GroupManager'
        'Connect-GroupManager'
        'Set-GroupManagerAuth'
        'Clear-GroupManagerAuth'
        'Set-GroupManagerGroup'
        'Clear-GroupManagerConfig'
        'Get-GroupManagerConfig'
        'Add-GroupManagerMember'
        'Remove-GroupManagerMember'
        'Get-GroupManagerMember'
    )

    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('EntraID', 'AzureAD', 'Groups', 'MicrosoftGraph')
            LicenseUri   = 'https://github.com/markorr321/GroupManager/blob/main/Module/GroupManager/LICENSE'
            ProjectUri   = 'https://github.com/markorr321/GroupManager'
            ReleaseNotes = @'
v1.4.0
- Cross-platform support (Windows, macOS, Linux)
- macOS: PowerShell profile persistence for app registration config
- Fixed config path on macOS/Linux ($HOME/.local/share)
- Updated README for module-only usage
'@
        }
    }
}
