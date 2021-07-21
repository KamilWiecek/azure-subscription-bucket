param
(
    [parameter(Mandatory = $true)]
    [String] 
    $BillingScope,
    
    [parameter(Mandatory = $true)]
    [String]
    $BucketManagementGroupId,
    
    [parameter(Mandatory = $true)]
    [Int]
    $BucketSize
)

Write-Output -InputObject '------------------------------- START -------------------------------'

Write-Output -InputObject "BillingScope = $BillingScope"
Write-Output -InputObject "BucketManagementGroupId = $BucketManagementGroupId"
Write-Output -InputObject "BucketSize = $BucketSize"

# verify context
$context = Get-AzContext

if (-not $context) {
    Write-Error -Exception "Login to Azure first!"
}

# get subscriptions in bucket
Write-Output -InputObject "Get subscription in bucket - start"

$unassignedSubscriptions = & ./Get-ManagementGroupSubscription.ps1 -ManagementGroupName $BucketManagementGroupId

Write-Output -InputObject "Number of unassigned subscriptions in bucket is $( $unassignedSubscriptions.count )"
Write-Output -InputObject "$( $unassignedSubscriptions | ConvertTo-Json -Depth 100 )"
Write-Output -InputObject "Get subscription in bucket - end"

# create sub if required
Write-Output -InputObject "Create subscriptions if required - start"
$newSubscriptionsCount = $BucketSize - $unassignedSubscriptions.count
if ($newSubscriptionsCount -gt 0) {
    Install-Module Az.Subscription -Scope CurrentUser -AllowPrerelease -Force
    for ($i = 0; $i -lt $newSubscriptionsCount; $i++) {
        $subscriptionName = 'sub-' + ( Get-Date -Format 'yyyyMMddHHmmss' )
        Write-Output -InputObject "New subscription name is $subscriptionName"
        
        New-AzSubscriptionAlias -AliasName $subscriptionName -SubscriptionName $subscriptionName -BillingScope $BillingScope -Workload "Production"
        Write-Output -InputObject "$subscriptionName created"

        $subscription = Get-AzSubscription -SubscriptionName $subscriptionName
        Write-Output -InputObject "Subscription ID is $($subscription.id)"

        New-AzManagementGroupSubscription -GroupId $BucketManagementGroupId -SubscriptionId $subscription.id
        Write-Output -InputObject "$subscriptionName moved to bucket"
    }
} 
else {
    Write-Output -InputObject 'Bucket contains desired number of unassigned subscriptions.'
}

Write-Output -InputObject "Create subscriptions if required - end"

Write-Output -InputObject '------------------------------- END -------------------------------'