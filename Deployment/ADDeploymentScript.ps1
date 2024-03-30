param(
	[Parameter(Mandatory)]
	[string] $ClientappName, 
	[Parameter(Mandatory)]
	[string] $ServerappName,
	[Parameter(Mandatory)]
	[string] $BaseAddress
)
# Setup Variables

$ClientClientId = "5b4d46db-91cb-4b8f-8d72-24c77cf1745f"
$ServerClientSecret = "SECRET"
$ServerClientId = "a3243665-fc94-47d0-9f6a-5c300ff246d"
$TenantId = "d15db61c-9b7a-472e-8f75-b38630bb554c"

$redirectUris = @(
    "$($BaseAddress)/authentication/login-callback",
   "$($BaseAddress)/swagger/oauth-redirect.html"
)

# Assuming $ClientappName and $redirectUris are predefined
$ClientApp = New-AzADApplication -DisplayName $ClientappName -ReplyUrls $redirectUris -AvailableToOtherTenants $false

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['ClientClientId'] = $ClientApp.AppId



