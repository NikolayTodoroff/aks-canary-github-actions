param(
    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$GitHubOrg,

    [Parameter(Mandatory = $true)]
    [string]$RepoName
)

$environments = @("dev", "prod")

# Repo validation before creating credentials
try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubOrg/$RepoName" -ErrorAction Stop | Out-Null
    Write-Host "Repository $GitHubOrg/$RepoName found."
} catch {
    Write-Error "Repository $GitHubOrg/$RepoName not found. Check the name and try again."
    return
}

$ownerData = Invoke-RestMethod -Uri "https://api.github.com/users/$GitHubOrg"
$ownerId = $ownerData.id

$repoData = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubOrg/$RepoName"
$repoId = $repoData.id

Write-Host "Owner ID: $ownerId, Repo ID: $repoId"

foreach ($env in $environments) {
    $credential = @{
        name      = "github-actions-$env"
        issuer    = "https://token.actions.githubusercontent.com"
        subject   = "repo:$GitHubOrg@$ownerId/$RepoName@$repoId`:environment:$env"
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Depth 5

    $tempFile = New-TemporaryFile
    Set-Content -Path $tempFile -Value $credential -Encoding utf8

    Write-Host "Creating federated credential for $env..."

    az ad app federated-credential create `
        --id $AppId `
        --parameters "@$tempFile"

    Remove-Item $tempFile
}