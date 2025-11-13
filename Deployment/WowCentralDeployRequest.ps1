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

     # NEW
    [Parameter(Mandatory = $true)]
    [string]$CompanyNameForWoWLicence,
    
    [Parameter(Mandatory = $true)]
    [string]$BillingEmailForWoWLicence

    [Parameter(Mandatory = $false)]
    [string]$AdminUserPrincipalName

    
)

$ErrorActionPreference = 'Stop'

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

# ----- Ensure correct subscription context -----
Write-Host "Selecting Azure context for subscription: $SubscriptionId"

try {
    # Fast-path if the current context is already correct
    $ctx = Get-AzContext
    if (-not $ctx -or $ctx.Subscription.Id -ne $SubscriptionId) {
        # This does NOT require an extra login in deployment scripts
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
        $ctx = Get-AzContext
    }

    if ($ctx.Subscription.Id -ne $SubscriptionId) {
        throw "Failed to set Az context to subscription $SubscriptionId. Current: $($ctx.Subscription.Id)"
    }

    Write-Host ("Azure context set. Subscription: {0} ({1})  Tenant: {2}" -f `
        $ctx.Subscription.Name, $ctx.Subscription.Id, $ctx.Tenant.Id)
}
catch {
    Write-Error "Unable to set Azure context: $($_.Exception.Message)"
    throw
}
# ----------------------------------------------

# Resolve subscription name
$sub = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
$subscriptionName = $sub.Name
Write-Host "Subscription Name:      $subscriptionName"

# Get Kudu publish profile for the web app
Write-Host "Fetching publishing profile..."
$xml = [xml](Get-AzWebAppPublishingProfile -ResourceGroupName $ResourceGroupName -Name $WebAppName)

$kuduProfile = $xml.publishData.publishProfile | Where-Object { $_.publishMethod -eq 'MSDeploy' }
if (-not $kuduProfile) {
    throw "Could not find MSDeploy publishing profile for web app $WebAppName"
}

$kuduUsername = $kuduProfile.userName
$kuduPassword = $kuduProfile.userPWD

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
    adminUserPrincipalName = =$AdminUserPrincipalName
}

$body = $payload | ConvertTo-Json -Depth 6

Write-Host "Posting payload to WowCentral..."
$null = Invoke-RestMethod -Uri $WowCentralUrl -Method Post -Body $body -ContentType 'application/json'

Write-Host "Payload sent successfully."

# Optional ARM-visible output
$DeploymentScriptOutputs = @{
    status = 'sent'
}
