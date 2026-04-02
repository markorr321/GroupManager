function Add-GroupManagerMember {
    <#
    .SYNOPSIS
        Adds a user to an Entra ID group.
    .DESCRIPTION
        Looks up a user by UPN and adds them to the specified group.
    .PARAMETER GroupId
        The Object ID of the target group.
    .PARAMETER UserPrincipalName
        The UPN (email) of the user to add.
    .EXAMPLE
        Add-GroupManagerMember -GroupId "07a94b39-..." -UserPrincipalName "user@contoso.com"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,

        [Parameter(Mandatory)]
        [string]$UserPrincipalName
    )

    $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $user.Id -ErrorAction Stop

    [PSCustomObject]@{
        Action      = 'Added'
        DisplayName = $user.DisplayName
        UPN         = $user.UserPrincipalName
        GroupId     = $GroupId
    }
}
