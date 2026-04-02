function Set-GroupManagerGroup {
    <#
    .SYNOPSIS
        Configure groups for GroupManager to manage.
    .DESCRIPTION
        Opens an interactive setup menu, or adds groups directly by Object ID.
    .PARAMETER ObjectId
        One or more Group Object IDs (GUIDs) to add to the configuration.
    .EXAMPLE
        Set-GroupManagerGroup
    .EXAMPLE
        Set-GroupManagerGroup -ObjectId "07a94b39-cfee-41bd-a76f-187b3161696a"
    .EXAMPLE
        Set-GroupManagerGroup -ObjectId "guid1", "guid2"
    #>
    [CmdletBinding()]
    param(
        [string[]]$ObjectId
    )

    if ($ObjectId -and $ObjectId.Count -gt 0) {
        Show-Header -Subtitle "Adding Groups by Object ID"
        Write-Host ""

        $newGroups = @()
        $existingGroups = Get-GroupManagerConfig
        if ($existingGroups) {
            $newGroups = @($existingGroups)
        }

        foreach ($id in $ObjectId) {
            try { $null = [System.Guid]::Parse($id) }
            catch {
                Write-Host "  Invalid GUID format: $id - Skipping" -ForegroundColor Red
                continue
            }

            if ($newGroups | Where-Object { $_.Id -eq $id }) {
                Write-Host "  Group $id already configured - Skipping" -ForegroundColor Yellow
                continue
            }

            $groupName = Read-Host "  Enter friendly name for $id"
            if ([string]::IsNullOrWhiteSpace($groupName)) { $groupName = "Group-$id" }

            $newGroups += @{ Name = $groupName; Id = $id }
            Write-Host "  Added: $groupName" -ForegroundColor Green
        }

        Save-GroupManagerConfig -Groups $newGroups
        Write-Host ""
        Write-Host "  Configuration saved. Total groups: $($newGroups.Count)" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Show-GroupSetupMenu
    }
}
