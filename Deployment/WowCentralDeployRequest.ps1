param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$WebAppName,

    [Parameter(Mandatory = $true)]
    [string]$ManagedResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$WowCentralUrl,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Sending Kudu credentials to WowCentral ==="
Write-Host "Resource group:    $ResourceGroupName"
Write-Host "Web app:          $WebAppName"
Write-Host "Managed RG:       $ManagedResourceGroup"
Write-Host "SubscriptionId:   $SubscriptionId"
Write-Host "WowCentral URL:   $WowCentralUrl"

# Get subscription name (for logging & payload)
$sub = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
$subscriptionName = $sub.Name
Write-Host "SubscriptionName:  $subscriptionName"

# Get Kudu publish profile
Write-Host "Fetching publishing profile..."
$xml = [xml](Get-AzWebAppPublishingProfile -ResourceGroupName $ResourceGroupName -Name $WebAppName)

$kuduProfile = $xml.publishData.publishProfile | Where-Object { $_.publishMethod -eq 'MSDeploy' }
if (-not $kuduProfile) {
    throw "Could not find MSDeploy publishing profile for web app $WebAppName"
}

$kuduUsername = $kuduProfile.userName
$kuduPassword = $kuduProfile.userPWD

Write-Host "Got Kudu username: $kuduUsername"

# Build JSON payload
$payload = @{
    managedResourceGroup = $ManagedResourceGroup
    webAppName          = $WebAppName
    subscriptionId      = $SubscriptionId
    subscriptionName    = $subscriptionName
    kuduUsername        = $kuduUsername
    kuduPassword        = $kuduPassword
}

$body = $payload | ConvertTo-Json -Depth 5

Write-Host "Posting payload to WowCentral..."
$null = Invoke-RestMethod -Uri $WowCentralUrl -Method Post -Body $body -ContentType 'application/json'

Write-Host "Payload sent successfully."

# Optional: expose a simple output if you ever want to read it from ARM
$DeploymentScriptOutputs = @{
    status = 'sent'
}
