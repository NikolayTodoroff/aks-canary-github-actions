param(
    [Parameter(Mandatory = $true)]
    [string]$SpObjectId,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
)

$scope = "/subscriptions/$SubscriptionId"

$roles = @(
    "Contributor",
    "Storage Blob Data Contributor",
    "User Access Administrator",
    "Key Vault Secrets Officer"
)

foreach ($role in $roles) {
    Write-Host "Assigning role: $role"
    az role assignment create `
        --role $role `
        --assignee $SpObjectId `
        --scope $scope
}

Write-Host ""
Write-Host "Role assignments complete for workflow SP"