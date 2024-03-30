param(
	[Parameter(Mandatory)]
	[string] $ClientappName, 
	[Parameter(Mandatory)]
	[string] $ServerappName,
	[Paramter(Mandatory)]
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

$ClientApp = New-MgApplication -DisplayName $ClientappName -Spa @{ RedirectUris = $redirectUris } -SignInAudience "AzureADMyOrg"

# Get the Microsoft Graph service principal
$graphSp = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'"

# Get the IDs for the application roles
$userReadId = $graphSp.Oauth2PermissionScopes| Where-Object { $_.Value -eq 'User.Read' } | Select-Object -ExpandProperty Id
$userReadAllId = $graphSp.Oauth2PermissionScopes | Where-Object { $_.Value -eq 'User.ReadBasic.All' } | Select-Object -ExpandProperty Id


# Define the required permissions (User.Read and User.ReadBasic.All)
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

# Add the required permissions to the application
Update-MgApplication -ApplicationId $ClientApp.Id -RequiredResourceAccess $requiredPermissions
$TenantId = (Get-MgOrganization).Id
$ClientClientId = $ClientApp.AppId
$ServerApp = New-MgApplication -DisplayName $ServerappName -SignInAudience "AzureADMyOrg"

# Define the client secret parameters
$passwordCred = @{
    displayName = "Automated Secret"
    endDateTime = (Get-Date).AddYears(1)
}
# Create the client secret
$ServerClientSecret = Add-MgApplicationPassword -ApplicationId $ServerApp.Id -PasswordCredential $passwordCred