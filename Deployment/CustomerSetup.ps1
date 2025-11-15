param(
    [Parameter(Mandatory)]
    [string] $SiteName
)

Write-Host "=== World of Workflows - Customer Pre-Setup ===" -ForegroundColor Cyan
Write-Host "This script will create the client and server Azure AD applications," `
           "configure scopes and roles, and output a JSON blob for the" `
           "Marketplace deployment." -ForegroundColor Cyan
Write-Host ""

# Ensure Az module
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Host "Az module not found. Installing Az..." -ForegroundColor Yellow
    Install-Module Az -Scope CurrentUser -Repository PSGallery -Force
}
Import-Module Az.Accounts      -ErrorAction Stop
Import-Module Az.Resources     -ErrorAction Stop

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module not found. Installing..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
}
 Write-Host "Importing MS Graph - this can take a few minutes for the first time."
Import-Module Microsoft.Graph -ErrorAction Stop
 Write-Host "Done Importing MS Graph"

# Ensure we are logged in
try {

    $ctx = Get-AzContext
    if (-not $ctx) {
        Write-Host "You are not logged in. Calling Connect-AzAccount..." -ForegroundColor Yellow
        Connect-AzAccount -ErrorAction Stop | Out-Null
        $ctx = Get-AzContext
    }
}
catch {
    Write-Error "Failed to get Azure context or login: $($_.Exception.Message)"
    exit 1
}
 Write-Host "Setting up variables"
# Derive values from logged-in context and site name
$TenantId               = $ctx.Tenant.Id
$AdminUserPrincipalName = $ctx.Account.Id
$BaseAddress            = "https://$($SiteName).azurewebsites.net"
$ClientappName          = "$SiteName`Client"
$ServerappName          = "$SiteName`Server"

Write-Host ""
Write-Host "Using values:" -ForegroundColor Green
Write-Host "  TenantId               : $TenantId"
Write-Host "  Admin UPN              : $AdminUserPrincipalName"
Write-Host "  Site Name              : $SiteName"
Write-Host "  BaseAddress            : $BaseAddress"
Write-Host "  Client App DisplayName : $ClientappName"
Write-Host "  Server App DisplayName : $ServerappName"
Write-Host ""

# Make sure we operate in the correct tenant
Set-AzContext -Tenant $TenantId | Out-Null

# =========================
# 1. Create Client App
# =========================

$redirectUris = @(
    "$($BaseAddress)/authentication/login-callback",
    "$($BaseAddress)/swagger/oauth-redirect.html"
)

Write-Host "Creating CLIENT app registration '$ClientappName'..." -ForegroundColor Cyan
$ClientApp = New-AzADApplication `
    -DisplayName $ClientappName `
    -SPARedirectUri $redirectUris `
    -AvailableToOtherTenants:$false

# =========================
# 2. Create Server App
# =========================

Write-Host "Creating SERVER app registration '$ServerappName'..." -ForegroundColor Cyan
$ServerApp = New-AzADApplication `
    -DisplayName $ServerappName `
    -SignInAudience "AzureADMyOrg"

Write-Host "Creating server app client secret (23 months)..." -ForegroundColor Cyan
$ServerSecret = New-AzADAppCredential -ObjectId $ServerApp.Id -EndDate ((Get-Date).AddMonths(23))

# =========================
# 3. Configure Graph permissions for Server app
# =========================

Write-Host "Retrieving Microsoft Graph service principal..." -ForegroundColor Cyan
$graphSp = Get-AzADServicePrincipal -Filter "displayName eq 'Microsoft Graph'"

$userReadId = $graphSp.Oauth2PermissionScope `
    | Where-Object { $_.Value -eq 'User.Read' } `
    | Select-Object -ExpandProperty Id

$userReadAllId = $graphSp.Oauth2PermissionScope `
    | Where-Object { $_.Value -eq 'User.ReadBasic.All' } `
    | Select-Object -ExpandProperty Id

Write-Host "Configuring required resource access on server app..." -ForegroundColor Cyan

$requiredPermissions = @(
    @{
        "ResourceAppId" = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
        "ResourceAccess" = @(
            @{
                "Id"   = $userReadId
                "Type" = "Scope"
            }
        )
    }
)
Update-AzADApplication -ObjectId $ServerApp.Id -RequiredResourceAccess $requiredPermissions

$requiredPermissions = @(
    @{
        "ResourceAppId" = "00000003-0000-0000-c000-000000000000"
        "ResourceAccess" = @(
            @{
                "Id"   = $userReadAllId
                "Type" = "Scope"
            }
        )
    }
)
Update-AzADApplication -ObjectId $ServerApp.Id -RequiredResourceAccess $requiredPermissions

# Set the identifier URIs for the application
$identifierUris = @("api://" + $ServerApp.AppId)
Update-AzADApplication -ObjectId $ServerApp.Id -IdentifierUri $identifierUris

# =========================
# 4. Administrator App Role
# =========================

Write-Host "Adding 'Administrator' app role to server app..." -ForegroundColor Cyan

$AdminGuid = [guid]::NewGuid()
$appRole = @{
    AllowedMemberTypes = @("User")
    Description        = "Administrator of World of Workflows."
    DisplayName        = "Administrator"
    Id                 = $AdminGuid.Guid
    IsEnabled          = $true
    Value              = "Administrator"
}

Update-AzADApplication -ObjectId $ServerApp.Id -AppRole @($appRole)

# Ensure Service Principal for server app
Write-Host "Ensuring server app service principal exists..." -ForegroundColor Cyan
$ServerSp = Get-AzADServicePrincipal -Filter "appId eq '$($ServerApp.AppId)'"
if (-not $ServerSp) {
    $ServerSp = New-AzADServicePrincipal -ApplicationId $ServerApp.AppId
}

# =========================
# 5. Define All API Scopes (1..57)
# =========================

Write-Host "Defining API scopes on server app..." -ForegroundColor Cyan

$scope1Id = [guid]::NewGuid()
$scope2Id = [guid]::NewGuid()
$scope3Id = [guid]::NewGuid()
$scope4Id = [guid]::NewGuid()
$scope5Id = [guid]::NewGuid()
$scope6Id = [guid]::NewGuid()
$scope7Id = [guid]::NewGuid()
$scope8Id = [guid]::NewGuid()
$scope9Id = [guid]::NewGuid()
$scope10Id = [guid]::NewGuid()
$scope1 = @{
    Id   = $scope1Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to complete or fail any task."
    AdminConsentDisplayName = "Close all tasks"
    Value = "Tasks.Close.All"
}
$scope2 = @{
    Id   = $scope2Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to deallocate (unassigned) tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Deallocate assigned task"
    Value = "Tasks.Unassign.AssignedTo"
}
$scope3 = @{
    Id   = $scope3Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign unassigned tasks to the signed-in user."
    AdminConsentDisplayName = "Pick available tasks"
    Value = "Tasks.AssignToSelf.Available"
}
$scope4 = @{
    Id   = $scope4Id.Guid
    Type = "User"
    AdminConsentDescription = "Allows the app to read all object type definitions."
    AdminConsentDisplayName = "Read object type definitions"
    UserConsentDescription   = "Read all table definitions"
    UserConsentDisplayName   = "Read object type definitions"
    Value = "ObjectTypes.Read.All"
}
$scope5 = @{
    Id   = $scope5Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Read object type definitions"
    Value = "Tasks.Read.AssignedTo"
}
$scope6 = @{
    Id   = $scope6Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to complete or fail tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Close assigned tasks"
    Value = "Tasks.Close.AssignedTo"
}
$scope7 = @{
    Id   = $scope7Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign all tasks to the currently signed-in user."
    AdminConsentDisplayName = "Pick any tasks"
    Value = "Tasks.AssignToSelf.All"
}
$scope8 = @{
    Id   = $scope8Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign unassigned tasks to any user."
    AdminConsentDisplayName = "Assign available tasks to any user"
    Value = "Tasks.Assign.Available"
}
$scope9 = @{
    Id   = $scope9Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to reassign tasks assigned to the signed-in user to any other user."
    AdminConsentDisplayName = "Reassign tasks to any user"
    Value = "Tasks.Assign.AssignedTo"
}
$scope10 = @{
    Id   = $scope10Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign all tasks to any user."
    AdminConsentDisplayName = "Assign tasks to any user"
    Value = "Tasks.Assign.All"
}

$scope11Id = [guid]::NewGuid()
$scope12Id = [guid]::NewGuid()
$scope13Id = [guid]::NewGuid()
$scope14Id = [guid]::NewGuid()
$scope15Id = [guid]::NewGuid()
$scope16Id = [guid]::NewGuid()
$scope17Id = [guid]::NewGuid()
$scope18Id = [guid]::NewGuid()
$scope19Id = [guid]::NewGuid()
$scope20Id = [guid]::NewGuid()

$scope11 = @{
    Id   = $scope11Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Read assigned tasks"
    Value = "Tasks.Read.Assigned"
}
$scope12 = @{
    Id   = $scope12Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to initiate a backup of the database. This permission does not allow the user to download the database."
    AdminConsentDisplayName = "Initiate database backup"
    Value = "Server.Backup"
}
$scope13 = @{
    Id   = $scope13Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the permissions of the current user."
    AdminConsentDisplayName = "Read permissions"
    Value = "Identity.Read.Own"
}
$scope14 = @{
    Id   = $scope14Id.Guid
    Type = "User"
    AdminConsentDescription = "Allows the app to invoke workflow signals by name."
    AdminConsentDisplayName = "Invoke workflow signals by name"
    UserConsentDescription   = "Allows the app to invoke workflow signals by name on your behalf."
    UserConsentDisplayName   = "Invoke workflow signals by name"
    Value = "WorkflowSignal.InvokeByName.All"
}
$scope15 = @{
    Id   = $scope15Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write workflow secrets."
    AdminConsentDisplayName = "Read and write workflow secrets"
    Value = "WorkflowSecrets.ReadWrite.All"
}
$scope16 = @{
    Id   = $scope16Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow instance execution logs."
    AdminConsentDisplayName = "Read workflow instance execution logs"
    Value = "WorkflowInstanceExecutionLog.Read.All"
}
$scope17 = @{
    Id   = $scope17Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to retry workflow instances."
    AdminConsentDisplayName = "Retry workflow instances"
    Value = "WorkflowInstance.Retry.All"
}
$scope18 = @{
    Id   = $scope18Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow instances."
    AdminConsentDisplayName = "Read workflow instances"
    Value = "WorkflowInstance.Read.All"
}
$scope19 = @{
    Id   = $scope19Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete workflow instances."
    AdminConsentDisplayName = "Delete workflow instances"
    Value = "WorkflowInstance.Delete.All"
}
$scope20 = @{
    Id   = $scope20Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to cancel workflow instances."
    AdminConsentDisplayName = "Cancel workflow instances"
    Value = "WorkflowInstance.Cancel.All"
}

$scope21Id = [guid]::NewGuid()
$scope22Id = [guid]::NewGuid()
$scope23Id = [guid]::NewGuid()
$scope24Id = [guid]::NewGuid()
$scope25Id = [guid]::NewGuid()
$scope26Id = [guid]::NewGuid()
$scope27Id = [guid]::NewGuid()
$scope28Id = [guid]::NewGuid()
$scope29Id = [guid]::NewGuid()
$scope30Id = [guid]::NewGuid()

$scope21 = @{
    Id   = $scope21Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the available tasks."
    AdminConsentDisplayName = "Read available tasks"
    Value = "Tasks.Read.Available"
}
$scope22 = @{
    Id   = $scope22Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to use the workflow designer."
    AdminConsentDisplayName = "Use workflow designer"
    Value = "WorkflowDesigner.Read.All"
}
$scope23 = @{
    Id   = $scope23Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to write workflow definitions."
    AdminConsentDisplayName = "Write workflow definitions"
    Value = "WorkflowDefinition.Write.All"
}
$scope24 = @{
    Id   = $scope24Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to test workflow definitions."
    AdminConsentDisplayName = "Test workflow definitions"
    Value = "WorkflowDefinition.Test.All"
}
$scope25 = @{
    Id   = $scope25Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write workflow definitions."
    AdminConsentDisplayName = "Read object type definitions"
    Value = "WorkflowDefinition.ReadWrite.All"
}
$scope26 = @{
    Id   = $scope26Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow definitions."
    AdminConsentDisplayName = "Read workflow definitions"
    Value = "WorkflowDefinition.Read.All"
}
$scope27 = @{
    Id   = $scope27Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to publish workflow definitions."
    AdminConsentDisplayName = "Publish workflow definitions"
    Value = "WorkflowDefinition.Publish.All"
}
$scope28 = @{
    Id   = $scope28Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete workflow definitions."
    AdminConsentDisplayName = "Delete workflow definitions"
    Value = "WorkflowDefinition.Delete.All"
}
$scope29 = @{
    Id   = $scope29Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke tasks for workflow conductors."
    AdminConsentDisplayName = "Invoke workflow conductor tasks"
    Value = "WorkflowConductor.Invoke.Tasks"
}
$scope30 = @{
    Id   = $scope30Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke events for workflow conductors."
    AdminConsentDisplayName = "Invoke workflow conductor events"
    Value = "WorkflowConductor.Invoke.Events"
}

$scope31Id = [guid]::NewGuid()
$scope32Id = [guid]::NewGuid()
$scope33Id = [guid]::NewGuid()
$scope34Id = [guid]::NewGuid()
$scope35Id = [guid]::NewGuid()
$scope36Id = [guid]::NewGuid()
$scope37Id = [guid]::NewGuid()
$scope38Id = [guid]::NewGuid()
$scope39Id = [guid]::NewGuid()
$scope40Id = [guid]::NewGuid()

$scope31 = @{
    Id   = $scope31Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke workflow conductors."
    AdminConsentDisplayName = "Invoke workflow conductors"
    Value = "WorkflowConductor.Invoke.All"
}
$scope32 = @{
    Id   = $scope32Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow activity statistics."
    AdminConsentDisplayName = "Read workflow activity statistics"
    Value = "WorkflowActivityStatistics.Read.All"
}
$scope33 = @{
    Id   = $scope33Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow activity definitions."
    AdminConsentDisplayName = "Read workflow activity definitions"
    Value = "WorkflowActivityDefinition.Read.All"
}
$scope34 = @{
    Id   = $scope34Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke workflows on behalf of the signed-in user."
    AdminConsentDisplayName = "Invoke workflows"
    Value = "Workflow.Invoke.All"
}
$scope35 = @{
    Id   = $scope35Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the data for a view."
    AdminConsentDisplayName = "Read view data"
    Value = "Views.Read.All"
}
$scope36 = @{
    Id   = $scope36Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to write view definitions."
    AdminConsentDisplayName = "Write view definitions"
    Value = "ViewDefinitions.Write.All"
}
$scope37 = @{
    Id   = $scope37Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write view definitons."
    AdminConsentDisplayName = "Read and write view defintions"
    Value = "ViewDefinitions.ReadWrite.All"
}
$scope38 = @{
    Id   = $scope38Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read view defintions."
    AdminConsentDisplayName = "Read view definitions"
    Value = "ViewDefinitions.Read.All"
}
$scope39 = @{
    Id   = $scope39Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to write tasks."
    AdminConsentDisplayName = "Write tasks"
    Value = "Tasks.Write.All"
}
$scope40 = @{
    Id   = $scope40Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write tasks"
    AdminConsentDisplayName = "Read and write tasks"
    Value = "Tasks.ReadWrite.All"
}

$scope41Id = [guid]::NewGuid()
$scope42Id = [guid]::NewGuid()
$scope43Id = [guid]::NewGuid()
$scope44Id = [guid]::NewGuid()
$scope45Id = [guid]::NewGuid()
$scope46Id = [guid]::NewGuid()
$scope47Id = [guid]::NewGuid()
$scope48Id = [guid]::NewGuid()
$scope49Id = [guid]::NewGuid()
$scope50Id = [guid]::NewGuid()

$scope41 = @{
    Id   = $scope41Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read tasks.."
    AdminConsentDisplayName = "Read all tasks"
    Value = "Tasks.Read.All"
}
$scope42 = @{
    Id   = $scope42Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the application to restart the server."
    AdminConsentDisplayName = "Restart the server"
    Value = "Server.Restart"
}
$scope43 = @{
    Id   = $scope43Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to trigger the repair of the Elsa HTTP endpoints."
    AdminConsentDisplayName = "Repair Elsa HTTP endpoints"
    Value = "Server.FixElsa"
}
$scope44 = @{
    Id   = $scope44Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the installed plugins."
    AdminConsentDisplayName = "Read plugins"
    Value = "Plugins.Read.All"
}
$scope45 = @{
    Id   = $scope45Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to add plugins."
    AdminConsentDisplayName = "Add plugins"
    Value = "Plugins.Add"
}
$scope46 = @{
    Id   = $scope46Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete object types."
    AdminConsentDisplayName = "Delete object types"
    Value = "ObjectTypes.Delete.All"
}
$scope47 = @{
    Id   = $scope47Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke workflows for object instances."
    AdminConsentDisplayName = "Invoke object instance workflows"
    Value = "ObjectInstances.InvokeWorkflow.All"
}
$scope48 = @{
    Id   = $scope48Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete object instances."
    AdminConsentDisplayName = "Delete object instances"
    Value = "ObjectInstances.Delete.All"
}
$scope49 = @{
    Id   = $scope49Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read data types."
    AdminConsentDisplayName = "Read data types"
    Value = "DataTypes.Read.All"
}
$scope50 = @{
    Id   = $scope50Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the statistical counts."
    AdminConsentDisplayName = "Read and count statistical counts"
    Value = "CountStats.Read.All"
}

$scope51Id = [guid]::NewGuid()
$scope52Id = [guid]::NewGuid()
$scope53Id = [guid]::NewGuid()
$scope54Id = [guid]::NewGuid()
$scope55Id = [guid]::NewGuid()
$scope56Id = [guid]::NewGuid()
$scope57Id = [guid]::NewGuid()

$scope51 = @{
    Id   = $scope51Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to create and update object instances"
    AdminConsentDisplayName = "Create and update object instances"
    Value = "ObjectInstances.Write.All"
}
$scope52 = @{
    Id   = $scope52Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read object instances."
    AdminConsentDisplayName = "Read object instances"
    Value = "ObjectInstances.Read.All"
}
$scope53 = @{
    Id   = $scope53Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read current object instance data. It does not allow the app to read historical object instance data."
    AdminConsentDisplayName = "Read current object instance data"
    Value = "ObjectInstances.Read.Current"
}
$scope54 = @{
    Id   = $scope54Id.Guid
    Type = "User"
    AdminConsentDescription = "Allows the app to read the ID, version, creation date, last modified date and modification reason of object instances."
    AdminConsentDisplayName = "Read basic object instance info"
    Value = "ObjectInstances.Read.Basic"
}
$scope55 = @{
    Id   = $scope55Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read historical object instance data. It does not allow the app to read current object instance data."
    AdminConsentDisplayName = "Read object instance history"
    Value = "ObjectInstances.Read.History"
}
$scope56 = @{
    Id   = $scope56Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read, create, update and delete object type definitions."
    AdminConsentDisplayName = "Read and write object type definitions"
    Value = "ObjectTypes.ReadWrite.All"
}
$scope57 = @{
    Id   = $scope57Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read, create, update and delete object instances."
    AdminConsentDisplayName = "Read and write object instances"
    Value = "ObjectInstances.ReadWrite.All"
}

Update-AzADApplication -ObjectId $ServerApp.Id -Api @{
    Oauth2PermissionScope = @(
        $scope1,$scope2,$scope3,$scope4,$scope5,$scope6,$scope7,$scope8,$scope9,$scope10,
        $scope11,$scope12,$scope13,$scope14,$scope15,$scope16,$scope17,$scope18,$scope19,$scope20,
        $scope21,$scope22,$scope23,$scope24,$scope25,$scope26,$scope27,$scope28,$scope29,$scope30,
        $scope31,$scope32,$scope33,$scope34,$scope35,$scope36,$scope37,$scope38,$scope39,$scope40,
        $scope41,$scope42,$scope43,$scope44,$scope45,$scope46,$scope47,$scope48,$scope49,$scope50,
        $scope51,$scope52,$scope53,$scope54,$scope55,$scope56,$scope57
    )
}

$PreauthApplication = @{
    AppId                = $ClientApp.AppId
    DelegatedPermissionIds = @(
        $scope1Id, $scope2Id, $scope3Id, $scope4Id, $scope5Id, $scope6Id, $scope7Id, $scope8Id, $scope9Id, $scope10Id,
        $scope11Id, $scope12Id, $scope13Id, $scope14Id, $scope15Id, $scope16Id, $scope17Id, $scope18Id, $scope19Id, $scope20Id,
        $scope21Id, $scope22Id, $scope23Id, $scope24Id, $scope25Id, $scope26Id, $scope27Id, $scope28Id, $scope29Id, $scope30Id,
        $scope31Id, $scope32Id, $scope33Id, $scope34Id, $scope35Id, $scope36Id, $scope37Id, $scope38Id, $scope39Id, $scope40Id,
        $scope41Id, $scope42Id, $scope43Id, $scope44Id, $scope45Id, $scope46Id, $scope47Id, $scope48Id, $scope49Id, $scope50Id,
        $scope51Id, $scope52Id, $scope53Id, $scope54Id, $scope55Id, $scope56Id, $scope57Id
    )
}
Update-AzADApplication -ObjectId $ServerApp.Id -Api @{ PreAuthorizedApplication = @($PreauthApplication)}

# =========================
# 6. Assign Administrator Role to Admin User via Graph (Microsoft.Graph)
# =========================

Write-Host "Assigning Administrator app role to '$AdminUserPrincipalName' via Microsoft Graph..." -ForegroundColor Cyan
Read-Host "Press enter when ready."
$domains = Get-AzDomain -TenantId $TenantId

$AdminUser = Get-AzADUser -Filter "userPrincipalName eq '$AdminUserPrincipalName'"
if (-not $AdminUser) {
    throw "Could not find user with UPN '$AdminUserPrincipalName'"
}

# Connect to Graph (user will get a Graph login prompt)
Connect-MgGraph -TenantId $TenantId -Scopes "AppRoleAssignment.ReadWrite.All","Directory.Read.All" | Out-Null

$adminAppRoleId = $AdminGuid.Guid

$maxAttempts = 5
$attempt = 1
$assigned = $false

while (-not $assigned -and $attempt -le $maxAttempts) {
    try {
        Write-Host "Administrator app role #'$attempt' of '$maxAttempts'."

        New-MgUserAppRoleAssignment -UserId $AdminUser.Id -BodyParameter @{
            principalId = $AdminUser.Id
            resourceId  = $ServerSp.Id
            appRoleId   = $adminAppRoleId
        }  -ErrorAction Stop | Out-Null

        Write-Host "Administrator app role assigned to '$AdminUserPrincipalName'." -ForegroundColor Green
        $assigned = $true
    }
    catch {
        # Write-Warning "Attempt ${attempt}: Failed to assign Administrator role: $($_.Exception.Message)"
        Write-Host "Will try again in 10 seconds to wait for Entra ID propagation ..." 
        if ($attempt -lt $maxAttempts) {
            Start-Sleep -Seconds 10
        }
        $attempt++
    }
}

if (-not $assigned) {
    Write-Warning "Could not assign Administrator role automatically after $maxAttempts attempts."
    Write-Host "Please assign the 'Administrator' role manually to '$AdminUserPrincipalName' " -ForegroundColor Yellow
    Write-Host "in the '$( $ServerappName )' enterprise application in Entra ID." -ForegroundColor Yellow
}

# =========================
# 7. Output JSON for Marketplace deployment
# =========================

$result = [PSCustomObject]@{
    tenantId               = $TenantId
    tenantDomain           = $domains[0].Domains[0]
    adminUserPrincipalName = $AdminUserPrincipalName
    clientAppName          = $ClientappName
    clientAppId            = $ClientApp.AppId
    serverAppName          = $ServerappName
    serverAppId            = $ServerApp.AppId
    serverAppSecret        = $ServerSecret.SecretText
    baseAddress            = $BaseAddress
    siteName               = $SiteName
}

Write-Host ""
Write-Host "IMPORTANT: Server application client secret" -ForegroundColor Yellow
Write-Host "Keep this value safe. You will NOT be able to retrieve it from Entra again.   " -ForegroundColor Yellow
Write-Host "If you loose this, you can always create a new secret in $ServerappName.   " -ForegroundColor White
Write-Host ""
Write-Host ("  Server App Secret: {0}" -f $ServerSecret.SecretText) -ForegroundColor Cyan
Write-Host ""
Read-Host "Press enter once you have copied this secret"

Write-Host "=== COPY THE JSON BELOW INTO THE MARKETPLACE DEPLOYMENT SCREEN ===" -ForegroundColor Cyan
$result | ConvertTo-Json -Depth 5
