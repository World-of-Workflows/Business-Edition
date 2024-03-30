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
$ClientApp = New-AzADApplication -DisplayName $ClientappName -SPARedirectUri $redirectUris -AvailableToOtherTenants $false

Connect-AzureAd

$graphSp=Get-AzureADServicePrincipal -Filter "displayName eq 'Microsoft Graph'"
$userReadId = $graphSp.Oauth2Permissions| Where-Object { $_.Value -eq 'User.Read' } | Select-Object -ExpandProperty Id
$userReadAllId = $graphSp.Oauth2Permissions | Where-Object { $_.Value -eq 'User.ReadBasic.All' } | Select-Object -ExpandProperty Id

$requiredPermissions = @(
    # User.Read
    @{
        "ResourceAppId" = "00000003-0000-0000-c000-000000000000"
        "ResourceAccess" = @(
            @{
                "Id" = $userReadId 
                "Type" = "Scope"
            }
        )
    }
)
Update-AzAdApplication -ObjectId $ClientApp.Id -RequiredResourceAccess $requiredPermissions

$requiredPermissions = @(
    # User.Read
    @{
        "ResourceAppId" = "00000003-0000-0000-c000-000000000000"
        "ResourceAccess" = @(
            @{
                "Id" = $userReadAllId 
                "Type" = "Scope"
            }
        )
    }
)
Update-AzAdApplication -ApplicationId $ClientApp.Id -RequiredResourceAccess $requiredPermissions

$ServerApp = New-AzAdApplication -DisplayName $ServerappName -SignInAudience "AzureADMyOrg"
$ServerSecret = New-AzureAdApplicationPasswordCreden
tial -ObjectId $ServerApp.Id -CustomKeyIdentifier PrimarySecret -EndDate ((Get-Date).AddMonths(12))


$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['ClientClientId'] = $ClientApp.AppId
$DeploymentScriptOutputs['ServerClientId'] = $ServerApp.AppId
$DeploymentScriptOutputs['ServerSecret'] = $ServerSecret.Value



