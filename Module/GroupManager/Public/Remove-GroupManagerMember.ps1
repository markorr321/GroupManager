function Remove-GroupManagerMember {
    <#
    .SYNOPSIS
        Removes a user from an Entra ID group.
    .DESCRIPTION
        Looks up a user by UPN and removes them from the specified group.
    .PARAMETER GroupId
        The Object ID of the target group.
    .PARAMETER UserPrincipalName
        The UPN (email) of the user to remove.
    .EXAMPLE
        Remove-GroupManagerMember -GroupId "07a94b39-..." -UserPrincipalName "user@contoso.com"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,

        [Parameter(Mandatory)]
        [string]$UserPrincipalName
    )

    $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
    Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $user.Id -ErrorAction Stop

    [PSCustomObject]@{
        Action      = 'Removed'
        DisplayName = $user.DisplayName
        UPN         = $user.UserPrincipalName
        GroupId     = $GroupId
    }
}
