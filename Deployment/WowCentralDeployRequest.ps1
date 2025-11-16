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

{
  "code": "ApplicationDeploymentFailed",
  "message": "The operation to create application failed. Please check operations of deployment 'TribetechWorkflowsWoWMA' under resource group '/subscriptions/e73859e9-d55e-4b17-8876-95623b64ed13/resourceGroups/TribetechWorkflowsWoWMRG'. Error message: 'At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.'",
  "details": [
    {
      "code": "Conflict",
      "message": "{\r\n  \"status\": \"failed\",\r\n  \"error\": {\r\n    \"code\": \"ResourceDeploymentFailure\",\r\n    \"message\": \"The resource write operation failed to complete successfully, because it reached terminal provisioning state 'failed'.\",\r\n    \"details\": [\r\n      {\r\n        \"code\": \"DeploymentScriptError\",\r\n        \"message\": \"The provided script failed with multiple errors. First error:\\r\\nMicrosoft.PowerShell.Commands.HttpResponseException: Response status code does not indicate success: 401 (Unauthorized).\\n   at System.Management.Automation.MshCommandRuntime.ThrowTerminatingError(ErrorRecord errorRecord)\\r\\nat <ScriptBlock>, /mnt/azscripts/azscriptinput/WowCentralDeployRequest.ps1: line 92\\r\\nat <ScriptBlock>, <No file>: line 1\\r\\nat <ScriptBlock>, /mnt/azscripts/azscriptinput/DeploymentScript.ps1: line 321. Please refer to https://aka.ms/DeploymentScriptsTroubleshoot for more deployment script information.\",\r\n        \"details\": [\r\n          {\r\n            \"code\": \"DeploymentScriptError\",\r\n            \"message\": \"Microsoft.PowerShell.Commands.HttpResponseException: Response status code does not indicate success: 401 (Unauthorized).\\n   at System.Management.Automation.MshCommandRuntime.ThrowTerminatingError(ErrorRecord errorRecord)\\r\\nat <ScriptBlock>, /mnt/azscripts/azscriptinput/WowCentralDeployRequest.ps1: line 92\\r\\nat <ScriptBlock>, <No file>: line 1\\r\\nat <ScriptBlock>, /mnt/azscripts/azscriptinput/DeploymentScript.ps1: line 321\"\r\n          },\r\n          {\r\n            \"code\": \"DeploymentScriptError\",\r\n            \"message\": \"Microsoft.PowerShell.Commands.WriteErrorException: Failed to fetch publishing profile via ARM REST API: Response status code does not indicate success: 401 (Unauthorized).\\r\\nat <ScriptBlock>, /mnt/azscripts/azscriptinput/WowCentralDeployRequest.ps1: line 96\\r\\nat <ScriptBlock>, <No file>: line 1\\r\\nat <ScriptBlock>, /mnt/azscripts/azscriptinput/DeploymentScript.ps1: line 321\"\r\n          }\r\n        ]\r\n      }\r\n    ]\r\n  }\r\n}"
    }
  ]
}

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
