param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$WebAppName,

    [Parameter(Mandatory = $true)]
    [string]$ManagedResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$AppServicePlanName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$ClientAppName,

    [Parameter(Mandatory = $true)]
    [string]$ServerAppName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$CompanyNameForWoWLicence,
    
    [Parameter(Mandatory = $true)]
    [string]$BillingEmailForWoWLicence,

    [Parameter(Mandatory = $false)]
    [string]$AdminUserPrincipalName,

    [Parameter(Mandatory = $false)]
    [string]$BusinessEditionSolution

    
)

$ErrorActionPreference = 'Stop'

# ----- Connect using the deployment script's managed identity -----
Write-Host "Connecting to Azure with managed identity..."
try {
    # No parameters needed: deploymentScripts inject the correct identity
    Connect-AzAccount -Identity -ErrorAction Stop

    $ctx = Get-AzContext
    if ($ctx) {
        Write-Host ("Connected. Subscription: {0}  Tenant: {1}" -f `
            $ctx.Subscription.Id, $ctx.Tenant.Id)
    } else {
        Write-Warning "Connect-AzAccount -Identity returned no context (unexpected)."
    }
}
catch {
    Write-Error "Failed to connect with managed identity: $($_.Exception.Message)"
    throw
}

# Hard-coded WowCentral endpoint
$WowCentralUrl = 'https://wowcentral.azurewebsites.net/deploymentRequest'

Write-Host "=== Sending deployment context to WowCentral ==="
Write-Host "Resource group:         $ResourceGroupName"
Write-Host "Web app:               $WebAppName"
Write-Host "Managed RG:            $ManagedResourceGroup"
Write-Host "SubscriptionId:        $SubscriptionId"
Write-Host "App Service Plan:      $AppServicePlanName"
Write-Host "Location:              $Location"
Write-Host "Client App Name:       $ClientAppName"
Write-Host "Server App Name:       $ServerAppName"
Write-Host "Storage Account Name:  $StorageAccountName"
Write-Host "WowCentral URL:        $WowCentralUrl"
Write-Host "Company Name (Licence): $CompanyNameForWoWLicence"
Write-Host "Billing Email:          $BillingEmailForWoWLicence"
Write-Host "Admin UPN:   $AdminUserPrincipalName"
Write-Host "Business Edition Solution:   $BusinessEditionSolution"

# Resolve subscription name (best-effort, no hard dependency)
$subscriptionName = $SubscriptionId  # default/fallback

try {
    $ctx = Get-AzContext
    if ($ctx -and $ctx.Subscription -and $ctx.Subscription.Id -eq $SubscriptionId) {
        $subscriptionName = $ctx.Subscription.Name
    }

    Write-Host "Subscription Name:      $subscriptionName"
}
catch {
    Write-Warning "Could not resolve subscription name from context: $($_.Exception.Message)"
    Write-Host "Using subscription ID as name: $subscriptionName"
}

# Get Kudu publish profile for the web app
Write-Host "Fetching publishing profile via ARM REST API..."

# Get an access token for the ARM (management) endpoint
$armToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token

$headers = @{
    Authorization = "Bearer $armToken"
    "Content-Type" = "application/json"
}

# Use the same API family as your ARM template (Web/sites 2023-01-01 is fine here)
$publishUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$WebAppName/publishxml?api-version=2023-01-01"

try {
    # Publish profile endpoint expects POST and returns XML
    $publishXmlString = Invoke-RestMethod -Uri $publishUrl -Headers $headers -Method POST -ErrorAction Stop

    # Parse XML
    [xml]$publishXml = $publishXmlString

    $kuduProfile = $publishXml.publishData.publishProfile |
        Where-Object { $_.publishMethod -eq 'MSDeploy' }

    if (-not $kuduProfile) {
        throw "Could not find MSDeploy publishing profile in publish XML for web app $WebAppName"
    }

    $kuduUsername = $kuduProfile.userName
    $kuduPassword = $kuduProfile.userPWD

    Write-Host "Got Kudu username: $kuduUsername"
}
catch {
    Write-Error "Failed to fetch or parse publishing profile: $($_.Exception.Message)"
    throw
}

Write-Host "Got Kudu username: $kuduUsername"

# Build payload sent to WowCentral
$payload = @{
    managedResourceGroup = $ManagedResourceGroup
    webAppName          = $WebAppName
    subscriptionId      = $SubscriptionId
    subscriptionName    = $subscriptionName
    kuduUsername        = $kuduUsername
    kuduPassword        = $kuduPassword
    appServicePlanName  = $AppServicePlanName
    location            = $Location
    clientAppName       = $ClientAppName
    serverAppName       = $ServerAppName
    storageAccountName  = $StorageAccountName
    companyNameForWoWLicence = $CompanyNameForWoWLicence
    billingEmailForWoWLicence = $BillingEmailForWoWLicence
    adminUserPrincipalName = $AdminUserPrincipalName
    businessEditionSolution  = $BusinessEditionSolution
}

$body = $payload | ConvertTo-Json -Depth 6

Write-Host "Posting payload to WowCentral..."
$null = Invoke-RestMethod -Uri $WowCentralUrl -Method Post -Body $body -ContentType 'application/json'

Write-Host "Payload sent successfully."

# Optional ARM-visible output
$DeploymentScriptOutputs = @{
    status = 'sent'
}
