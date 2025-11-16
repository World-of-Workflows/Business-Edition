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

# 1. Authenticate using the managed identity that the deploymentScript is running under
Connect-AzAccount -Identity -ErrorAction Stop | Out-Null

# 2. Inspect current context
$ctx = Get-AzContext
Write-Host ("Initial Az context: Sub='{0}'  Tenant='{1}'" -f `
    ($ctx.Subscription.Id  | ForEach-Object { $_ ?? '<none>' }),
    ($ctx.Tenant.Id        | ForEach-Object { $_ ?? '<none>' }))

# 3. Ensure we are on the subscription passed in from ARM
if (-not $ctx.Subscription -or [string]::IsNullOrWhiteSpace($ctx.Subscription.Id)) {
    Write-Host "Context has no subscription; setting context to SubscriptionId from parameters..."
    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
        throw "SubscriptionId parameter is null or empty; cannot set Az context."
    }

    # IMPORTANT: use -SubscriptionId, not -Subscription, and don't pass Tenant
    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
    $ctx = Get-AzContext
}
elseif ($ctx.Subscription.Id -ne $SubscriptionId) {
    Write-Host "Context subscription ($($ctx.Subscription.Id)) != parameter subscription ($SubscriptionId); switching..."

    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
    $ctx = Get-AzContext
}

$tenantId = $ctx.Tenant.Id
Write-Host ("Current Az context: Sub='{0}' Name='{1}' Tenant='{2}'" -f `
    $ctx.Subscription.Id, $ctx.Subscription.Name, $ctx.Tenant.Id)

Write-Host ("Current Az context: Sub='{0}' Name='{1}' Tenant='{2}'" -f `
    $ctx.Subscription.Id, $ctx.Subscription.Name, $ctx.Tenant.Id)

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
$sub = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
$subscriptionName = $sub.Name
Write-Host "Subscription Name:      $subscriptionName"

Write-Host "Fetching publishing profile..."
$xml = [xml](Get-AzWebAppPublishingProfile -ResourceGroupName $ResourceGroupName -Name $WebAppName -ErrorAction Stop)

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
