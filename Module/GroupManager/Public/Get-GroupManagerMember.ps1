function Get-GroupManagerMember {
    <#
    .SYNOPSIS
        Lists members of an Entra ID group.
    .DESCRIPTION
        Returns all members of the specified group as objects with
        DisplayName, UserPrincipalName, and Id properties.
    .PARAMETER GroupId
        The Object ID of the target group.
    .EXAMPLE
        Get-GroupManagerMember -GroupId "07a94b39-..."
    .EXAMPLE
        Get-GroupManagerMember -GroupId "07a94b39-..." | Format-Table
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId
    )

    $members = Get-MgGroupMember -GroupId $GroupId -All | ForEach-Object {
        Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue
    } | Where-Object { $_ -ne $null } | Sort-Object DisplayName

    foreach ($member in $members) {
        [PSCustomObject]@{
            DisplayName       = $member.DisplayName
            UserPrincipalName = $member.UserPrincipalName
            Id                = $member.Id
        }
    }
}
