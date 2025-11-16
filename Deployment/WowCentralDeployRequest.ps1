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

# Hard-coded WowCentral endpoint
$WowCentralUrl = 'https://wowcentral.azurewebsites.net/deploymentRequest'

Write-Host "Connecting to Azure with managed identity..."
Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
$ctx = Get-AzContext
Write-Host ("Connected. Tenant: {0}" -f $ctx.Tenant.Id)

Write-Host "=== Sending deployment context to WowCentral ==="
Write-Host "Resource group:         $ResourceGroupName"
Write-Host "Web app:               $WebAppName"
Write-Host "Managed RG:            $ManagedResourceGroup"
Write-Host "SubscriptionId:        $SubscriptionId"
Write-Host "App Service Plan:      $AppServicePlanName"
Write-Host "Location:              $Location"
Write-Host "Client App Name:       $ClientAppName"
Write-Host "Server App Name:       $ServerAppName"
Write-Host "Subscription id:       $SubscriptionId"                            x
Write-Host "Storage Account Name:  $StorageAccountName"
Write-Host "WowCentral URL:        $WowCentralUrl"
Write-Host "Company Name (Licence): $CompanyNameForWoWLicence"
Write-Host "Billing Email:          $BillingEmailForWoWLicence"
Write-Host "Admin UPN:   $AdminUserPrincipalName"
Write-Host "Business Edition Solution:   $BusinessEditionSolution"

# Resolve subscription name (now that context is set correctly)
# Write-Host "Fetching Subscription Name..."
# $sub = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
# $subscriptionName = $sub.Name
# Write-Host "Subscription Name:      $subscriptionName"

Write-Host "Fetching publishing profile via ARM REST API..."

# Build the ARM path (no hostname, Invoke-AzRestMethod uses current environment)
$publishProfilePath = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$WebAppName/publishxml?api-version=2023-01-01"

try {
    # Let Az handle tokens & environment
    $response = Invoke-AzRestMethod -Method POST -Path $publishProfilePath

    if (-not $response -or -not $response.Content) {
        throw "Empty response from ARM publishxml for $WebAppName."
    }

    $xmlString = $response.Content
}
catch {
    Write-Error "Failed to fetch publishing profile via ARM REST API: $($_.Exception.Message)"
    throw
}

# Parse the XML and extract Kudu credentials
$xml = [xml]$xmlString

$kuduProfile = $xml.publishData.publishProfile |
    Where-Object { $_.publishMethod -eq 'MSDeploy' }

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
