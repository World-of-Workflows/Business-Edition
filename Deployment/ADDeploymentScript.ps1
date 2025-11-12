param(
	[Parameter(Mandatory)]
	[string] $ClientappName, 
	[Parameter(Mandatory)]
	[string] $ServerappName,
	[Parameter(Mandatory)]
	[string] $BaseAddress,
    [Parameter(Mandatory)]
    [string] $TenantId,
	# NEW - used to enter into Service: your user’s UPN (e.g. jim@worldofworkflows.com)
    [Parameter(Mandatory)]
    [string] $AdminUserPrincipalName
)
# Setup Variables



$redirectUris = @(
    "$($BaseAddress)/authentication/login-callback",
   "$($BaseAddress)/swagger/oauth-redirect.html"
)

# Assuming $ClientappName and $redirectUris are predefined
$ClientApp = New-AzADApplication -DisplayName $ClientappName -SPARedirectUri $redirectUris -AvailableToOtherTenants $false

$graphSp=Get-AzADServicePrincipal -Filter "displayName eq 'Microsoft Graph'"
$userReadId = $graphSp.Oauth2PermissionScope | Where-Object { $_.Value -eq 'User.Read' } | Select-Object -ExpandProperty Id
$userReadAllId = $graphSp.Oauth2PermissionScope | Where-Object { $_.Value -eq 'User.ReadBasic.All' } | Select-Object -ExpandProperty Id



$ServerApp = New-AzAdApplication -DisplayName $ServerappName -SignInAudience "AzureADMyOrg"
 $ServerSecret = New-AzADAppCredential -ObjectId $ServerApp.Id -EndDate ((Get-Date).AddMonths(12)) 

# Now Creating Identifier URLs
 $identifierUris = @(
    "api://" + $ServerApp.AppId
)
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
Update-AzAdApplication -ObjectId $ServerApp.Id -RequiredResourceAccess $requiredPermissions
                                          
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
Update-AzAdApplication -ObjectId $ServerApp.Id -RequiredResourceAccess $requiredPermissions

# Set the identifier URIs for the application
Update-AzAdApplication -ObjectId $ServerApp.Id -IdentifierUri $identifierUris  

# Now add the Administrator Role

$AdminGuid = new-guid
$appRole = @{
    AllowedMemberTypes = @("User")
    Description = "Administrator of World of Workflows."
    DisplayName = "Administrator"
    Id = $AdminGuid.Guid
    IsEnabled = $true
    Value = "Administrator"
}

update-azadapplication -ObjectId $ServerApp.Id -AppRole @($appRole)

# --- NEW: Ensure a service principal (enterprise app) exists for the server app ---
$ServerSp = Get-AzADServicePrincipal -Filter "appId eq '$($ServerApp.AppId)'"

if (-not $ServerSp) {
    Write-Host "Creating service principal for server app '$ServerappName'..."
    $ServerSp = New-AzADServicePrincipal -ApplicationId $ServerApp.AppId
} else {
    Write-Host "Service principal for server app '$ServerappName' already exists."
}

# Now to add the first 10 Scopes

$scope1Id = new-guid
$scope2Id = new-guid
$scope3Id = new-guid
$scope4Id = new-guid
$scope5Id = New-Guid
$scope6Id = New-Guid
$scope7Id = New-Guid
$scope8Id = New-Guid
$scope9Id = New-Guid
$scope10Id = New-Guid
$scope1 = @{
    Id = $scope1Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to complete or fail any task."
    AdminConsentDisplayName = "Close all tasks"
    Value = "Tasks.Close.All"
}
$scope2 = @{
    Id = $scope2Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to deallocate (unassigned) tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Deallocate assigned task"
    Value = "Tasks.Unassign.AssignedTo"
}

$scope3 = @{
    Id = $scope3Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign unassigned tasks to the signed-in user."
    AdminConsentDisplayName = "Pick available tasks"
    Value = "Tasks.AssignToSelf.Available"
}
$scope4 = @{
    Id = $scope4Id.Guid
    Type = "User"
    AdminConsentDescription = "Allows the app to read all object type definitions."
    AdminConsentDisplayName = "Read object type definitions"
    UserConsentDescription = "Read all table definitions"
    UserConsentDisplayName = "Read object type definitions"
    Value = "ObjectTypes.Read.All"
}
$scope5 = @{
    Id = $scope5Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Read object type definitions"
    Value = "Tasks.Read.AssignedTo"
}
$scope6 = @{
    Id = $scope6Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to complete or fail tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Close assigned tasks"
    Value = "Tasks.Close.AssignedTo"
}
$scope7 = @{
    Id = $scope7Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign all tasks to the currently signed-in user."
    AdminConsentDisplayName = "Pick any tasks"
    Value = "Tasks.AssignToSelf.All"
}
$scope8 = @{
    Id = $scope8Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign unassigned tasks to any user."
    AdminConsentDisplayName = "Assign available tasks to any user"
    Value = "Tasks.Assign.Available"
}
$scope9 = @{
    Id = $scope9Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to reassign tasks assigned to the signed-in user to any other user."
    AdminConsentDisplayName = "Reassign tasks to any user"
    Value = "Tasks.Assign.AssignedTo"
}
$scope10 = @{
    Id = $scope10Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to assign all tasks to any user."
    AdminConsentDisplayName = "Assign tasks to any user"
    Value = "Tasks.Assign.All"
}
#Write Scopes 11-20
#Get the current scopes and prepare to update




$scope11Id = new-guid
$scope12Id = new-guid
$scope13Id = new-guid
$scope14Id = new-guid
$scope15Id = New-Guid
$scope16Id = New-Guid
$scope17Id = New-Guid
$scope18Id = New-Guid
$scope19Id = New-Guid
$scope20Id = New-Guid

$scope11 = @{
    Id = $scope11Id
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read tasks assigned to the signed-in user."
    AdminConsentDisplayName = "Read assigned tasks"
    Value = "Tasks.Read.Assigned"
}
$scope12 = @{
    Id = $scope12Id
    Type = "Admin"
    AdminConsentDescription = "Allows the app to initiate a backup of the database. This permission does not allow the user to download the database."
    AdminConsentDisplayName = "Initiate database backup"
    Value = "Server.Backup"
}

$scope13 = @{
    Id = $scope13Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the permissions of the current user."
    AdminConsentDisplayName = "Read permissions"
    Value = "Identity.Read.Own"
}
$scope14 = @{
    Id = $scope14Id.Guid
    Type = "User"
    AdminConsentDescription = "Allows the app to invoke workflow signals by name."
    AdminConsentDisplayName = "Invoke workflow signals by name"
    UserConsentDescription = "Allows the app to invoke workflow signals by name on your behalf."
    UserConsentDisplayName = "Invoke workflow signals by name"
    Value = "WorkflowSignal.InvokeByName.All"
}
$scope15 = @{
    Id = $scope15Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write workflow secrets."
    AdminConsentDisplayName = "Read and write workflow secrets"
    Value = "WorkflowSecrets.ReadWrite.All"
}
$scope16 = @{
    Id = $scope16Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow instance execution logs."
    AdminConsentDisplayName = "Read workflow instance execution logs"
    Value = "WorkflowInstanceExecutionLog.Read.All"
}
$scope17 = @{
    Id = $scope17Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to retry workflow instances."
    AdminConsentDisplayName = "Retry workflow instances"
    Value = "WorkflowInstance.Retry.All"
}
$scope18 = @{
    Id = $scope18Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow instances."
    AdminConsentDisplayName = "Read workflow instances"
    Value = "WorkflowInstance.Read.All"
}
$scope19 = @{
    Id = $scope19Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete workflow instances."
    AdminConsentDisplayName = "Delete workflow instances"
    Value = "WorkflowInstance.Delete.All"
}
$scope20 = @{
    Id = $scope20Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to cancel workflow instances."
    AdminConsentDisplayName = "Cancel workflow instances"
    Value = "WorkflowInstance.Cancel.All"
}

#Write Scopes 21-30

$scope21Id = new-guid
$scope22Id = new-guid
$scope23Id = new-guid
$scope24Id = new-guid
$scope25Id = New-Guid
$scope26Id = New-Guid
$scope27Id = New-Guid
$scope28Id = New-Guid
$scope29Id = New-Guid
$scope30Id = New-Guid

$scope21 = @{
    Id = $scope21Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the available tasks."
    AdminConsentDisplayName = "Read available tasks"
    Value = "Tasks.Read.Available"
}
$scope22 = @{
    Id = $scope22Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to use the workflow designer."
    AdminConsentDisplayName = "Use workflow designer"
    Value = "WorkflowDesigner.Read.All"
}
$scope23 = @{
    Id = $scope23Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to write workflow definitions."
    AdminConsentDisplayName = "Write workflow definitions"
    Value = "WorkflowDefinition.Write.All"
}
$scope24 = @{
    Id = $scope24Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to test workflow definitions."
    AdminConsentDisplayName = "Test workflow definitions"
    Value = "WorkflowDefinition.Test.All"
}
$scope25 = @{
    Id = $scope25Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write workflow definitions."
    AdminConsentDisplayName = "Read object type definitions"
    Value = "WorkflowDefinition.ReadWrite.All"
}
$scope26 = @{
    Id = $scope26Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow definitions."
    AdminConsentDisplayName = "Read workflow definitions"
    Value = "WorkflowDefinition.Read.All"
}
$scope27 = @{
    Id = $scope27Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to publish workflow definitions."
    AdminConsentDisplayName = "Publish workflow definitions"
    Value = "WorkflowDefinition.Publish.All"
}
$scope28 = @{
    Id = $scope28Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete workflow definitions."
    AdminConsentDisplayName = "Delete workflow definitions"
    Value = "WorkflowDefinition.Delete.All"
}
$scope29 = @{
    Id = $scope29Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke tasks for workflow conductors."
    AdminConsentDisplayName = "Invoke workflow conductor tasks"
    Value = "WorkflowConductor.Invoke.Tasks"
}
$scope30 = @{
    Id = $scope30Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke events for workflow conductors."
    AdminConsentDisplayName = "Invoke workflow conductor events"
    Value = "WorkflowConductor.Invoke.Events"
}

$scope31Id = new-guid
$scope32Id = new-guid
$scope33Id = new-guid
$scope34Id = new-guid
$scope35Id = New-Guid
$scope36Id = New-Guid
$scope37Id = New-Guid
$scope38Id = New-Guid
$scope39Id = New-Guid
$scope40Id = New-Guid

$scope31 = @{
    Id = $scope31Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke workflow conductors."
    AdminConsentDisplayName = "Invoke workflow conductors"
    Value = "WorkflowConductor.Invoke.All"
}
$scope32 = @{
    Id = $scope32Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow activity statistics."
    AdminConsentDisplayName = "Read workflow activity statistics"
    Value = "WorkflowActivityStatistics.Read.All"
}

$scope33 = @{
    Id = $scope33Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read workflow activity definitions."
    AdminConsentDisplayName = "Read workflow activity definitions"
    Value = "WorkflowActivityDefinition.Read.All"
}
$scope34 = @{
    Id = $scope34Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke workflows on behalf of the signed-in user."
    AdminConsentDisplayName = "Invoke workflows"
    Value = "Workflow.Invoke.All"
}
$scope35 = @{
    Id = $scope35Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the data for a view."
    AdminConsentDisplayName = "Read view data"
    Value = "Views.Read.All"
}
$scope36 = @{
    Id = $scope36Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to write view definitions."
    AdminConsentDisplayName = "Write view definitions"
    Value = "ViewDefinitions.Write.All"
}
$scope37 = @{
    Id = $scope37Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write view definitons."
    AdminConsentDisplayName = "Read and write view defintions"
    Value = "ViewDefinitions.ReadWrite.All"
}
$scope38 = @{
    Id = $scope38Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read view defintions."
    AdminConsentDisplayName = "Read view definitions"
    Value = "ViewDefinitions.Read.All"
}
$scope39 = @{
    Id = $scope39Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to write tasks."
    AdminConsentDisplayName = "Write tasks"
    Value = "Tasks.Write.All"
}
$scope40 = @{
    Id = $scope40Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read and write tasks"
    AdminConsentDisplayName = "Read and write tasks"
    Value = "Tasks.ReadWrite.All"
}

$scope41Id = new-guid
$scope42Id = new-guid
$scope43Id = new-guid
$scope44Id = new-guid
$scope45Id = New-Guid
$scope46Id = New-Guid
$scope47Id = New-Guid
$scope48Id = New-Guid
$scope49Id = New-Guid
$scope50Id = New-Guid

$scope41 = @{
    Id = $scope41Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read tasks.."
    AdminConsentDisplayName = "Read all tasks"
    Value = "Tasks.Read.All"
}
$scope42 = @{
    Id = $scope42Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the application to restart the server."
    AdminConsentDisplayName = "Restart the server"
    Value = "Server.Restart"
}

$scope43 = @{
    Id = $scope43Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to trigger the repair of the Elsa HTTP endpoints."
    AdminConsentDisplayName = "Repair Elsa HTTP endpoints"
    Value = "Server.FixElsa"
}
$scope44 = @{
    Id = $scope44Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the installed plugins."
    AdminConsentDisplayName = "Read plugins"
    Value = "Plugins.Read.All"
}
$scope45 = @{
    Id = $scope45Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to add plugins."
    AdminConsentDisplayName = "Add plugins"
    Value = "Plugins.Add"
}
$scope46 = @{
    Id = $scope46Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete object types."
    AdminConsentDisplayName = "Delete object types"
    Value = "ObjectTypes.Delete.All"
}
$scope47 = @{
    Id = $scope47Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to invoke workflows for object instances."
    AdminConsentDisplayName = "Invoke object instance workflows"
    Value = "ObjectInstances.InvokeWorkflow.All"
}
$scope48 = @{
    Id = $scope48Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to delete object instances."
    AdminConsentDisplayName = "Delete object instances"
    Value = "ObjectInstances.Delete.All"
}
$scope49 = @{
    Id = $scope49Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read data types."
    AdminConsentDisplayName = "Read data types"
    Value = "DataTypes.Read.All"
}
$scope50 = @{
    Id = $scope50Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read the statistical counts."
    AdminConsentDisplayName = "Read and count statistical counts"
    Value = "CountStats.Read.All"
}

$scope51Id = new-guid
$scope52Id = new-guid
$scope53Id = new-guid
$scope54Id = new-guid
$scope55Id = New-Guid
$scope56Id = New-Guid
$scope57Id = New-Guid
$scope58Id = New-Guid
$scope59Id = New-Guid
$scope60Id = New-Guid

$scope51 = @{
    Id = $scope51Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to create and update object instances"
    AdminConsentDisplayName = "Create and update object instances"
    Value = "ObjectInstances.Write.All"
}
$scope52 = @{
    Id = $scope52Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read object instances."
    AdminConsentDisplayName = "Read object instances"
    Value = "ObjectInstances.Read.All"
}
$scope53 = @{
    Id = $scope53Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read current object instance data. It does not allow the app to read historical object instance data."
    AdminConsentDisplayName = "Read current object instance data"
    Value = "ObjectInstances.Read.Current"
}
$scope54 = @{
    Id = $scope54Id.Guid
    Type = "User"
    AdminConsentDescription = "Allows the app to read the ID, version, creation date, last modified date and modification reason of object instances."
    AdminConsentDisplayName = "Read basic object instance info"
    Value = "ObjectInstances.Read.Basic"
}
$scope55 = @{
    Id = $scope55Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read historical object instance data. It does not allow the app to read current object instance data."
    AdminConsentDisplayName = "Read object instance history"
    Value = "ObjectInstances.Read.History"
}
$scope56 = @{
    Id = $scope56Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to create and update object instances. It does not allow the app to read or delete object instances."
    AdminConsentDisplayName = "Read and write object instances"
    Value = "ObjectInstances.ReadWrite.All"
}
$scope57 = @{
    Id = $scope57Id.Guid
    Type = "Admin"
    AdminConsentDescription = "Allows the app to read, create, update and delete all object type definitions."
    AdminConsentDisplayName = "Read and write object type definitions"
    Value = "ObjectTypes.ReadWrite.All"
}

Update-AzAdApplication -ObjectId $ServerApp.Id -Api @{ Oauth2PermissionScope = @($scope1, $scope2, $scope3, $scope4, $scope5, $scope6, $scope7, $scope8, $scope9, $scope10, $scope11, $scope12, $scope13, $scope14, $scope15, $scope16, $scope17, $scope18, $scope19, $scope20, $scope21, $scope22, $scope23, $scope24, $scope25, $scope26, $scope27, $scope28, $scope29, $scope30, $scope31, $scope32, $scope33, $scope34, $scope35, $scope36, $scope37, $scope38, $scope39, $scope40, $scope41, $scope42, $scope43, $scope44, $scope45, $scope46, $scope47, $scope48, $scope49, $scope50, $scope51, $scope52, $scope53, $scope54, $scope55, $scope56, $scope57) }
# Preauthcliient



$PreauthApplication = @{
    AppId = $ClientApp.AppId
    DelegatedPermissionIds = @($scope1Id, $scope2Id, $scope3Id, $scope4Id, $scope5Id, $scope6Id, $scope7Id, $scope8Id, $scope9Id, $scope10Id, $scope11Id, $scope12Id, $scope13Id, $scope14Id, $scope15Id, $scope16Id, $scope17Id, $scope18Id, $scope19Id, $scope20Id, $scope21Id, $scope22Id, $scope23Id, $scope24Id, $scope25Id, $scope26Id, $scope27Id, $scope28Id, $scope29Id, $scope30Id, $scope31Id, $scope32Id, $scope33Id, $scope34Id, $scope35Id, $scope36Id, $scope37Id, $scope38Id, $scope39Id, $scope40Id, $scope41Id, $scope42Id, $scope43Id, $scope44Id, $scope45Id, $scope46Id, $scope47Id, $scope48Id, $scope49Id, $scope50Id, $scope51Id, $scope52Id, $scope53Id, $scope54Id, $scope55Id, $scope56Id, $scope57Id)
}

Update-AzAdApplication -ObjectId $ServerApp.Id -Api @{ PreAuthorizedApplication = @($PreauthApplication)}

$domains = get-azdomain -TenantId $TenantId

# --- NEW: Add the admin user as a member of the server enterprise app (Administrator role) ---

Write-Host "Locating admin user '$AdminUserPrincipalName'..."
$AdminUser = Get-AzADUser -Filter "userPrincipalName eq '$AdminUserPrincipalName'"

if (-not $AdminUser) {
    throw "Could not find user with UPN '$AdminUserPrincipalName'"
}

# The Administrator app role ID we created earlier
$adminAppRoleId = $AdminGuid.Guid

Write-Host "Ensuring admin user is assigned to server app with Administrator role..."
# Get token for Microsoft Graph
$token = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

# Graph appRoleAssignment payload: assign user -> server SP -> Administrator app role
$assignmentBody = @{
    principalId = $AdminUser.Id       # user ID
    resourceId  = $ServerSp.Id        # service principal (enterprise app) ID
    appRoleId   = $adminAppRoleId     # Administrator role ID
} | ConvertTo-Json

$assignUrl = "https://graph.microsoft.com/v1.0/users/$($AdminUser.Id)/appRoleAssignments"

try {
    Invoke-RestMethod -Uri $assignUrl -Method Post -Headers $headers -Body $assignmentBody
    Write-Host "Admin user '$AdminUserPrincipalName' assigned to server app '$ServerappName' with Administrator role."
}
catch {
    Write-Warning "Failed to assign admin user to server app: $($_.Exception.Message)"
}

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['ClientClientId'] = $ClientApp.AppId
$DeploymentScriptOutputs['ServerClientId'] = $ServerApp.AppId
$DeploymentScriptOutputs['ServerSecret'] = $ServerSecret.SecretText
$DeploymentScriptOutputs['TenantId'] = $TenantId
$DeploymentScriptOutputs['TenantDomain']= $domains[0].Domains[0]


