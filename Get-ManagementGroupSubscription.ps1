[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ManagementGroupName
)

function Get-ManagementGroupChildSubscriptions ($GroupId) {
    $subscriptions = @()

    $children = (Get-AzManagementGroup -GroupId $GroupId -Expand -Recurse).Children
    $subscriptions += ($children | Where-Object -Property Type -eq '/subscriptions' )
    $childManagementGroups =  ($children | Where-Object -Property Type -eq '/providers/Microsoft.Management/managementGroups' )

    foreach ($cmg in $childManagementGroups) {
        $subscriptions += Get-ManagementGroupChildSubscriptions -GroupId $cmg.Name
    }

    return $subscriptions
}

$subscriptions = Get-ManagementGroupChildSubscriptions -GroupId $ManagementGroupName

return $subscriptions