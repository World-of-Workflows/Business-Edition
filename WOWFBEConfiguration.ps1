# WOWBE Configuration Script

# Define the application parameters
Write-Host "World of Workflows Business Edition Configuration Tool"
Write-Host "Connecting to MS Graph"
Connect-MgGraph -ContextScope Process -Scopes @("User.Read.All","Application.ReadWrite.All" )
Write-Host "Creating Client Application in AAD"
$ClientappName = Read-Host 'Enter the Client Application Name [World of Workflows Client]'
if([string]::IsNullOrWhiteSpace($ClientappName))
{
$ClientappName = "World of Workflows Client"

}
$ServerappName = Read-Host 'Enter the Server Application Name [World of Workflows Server]'
if([string]::IsNullOrWhiteSpace($ServerappName))
{
$ServerappName = "World of Workflows Server"

}

$BaseAddress = Read-Host 'Enter the Base Address of your instance [https://localhost:7063]'
if([string]::IsNullOrWhiteSpace($BaseAddress))
{
$BaseAddress='https://localhost:7063'
}

$redirectUris = @(
    "$($BaseAddress)/authentication/login-callback",
   "$($BaseAddress)/swagger/oauth-redirect.html"
)
Write-Host $redirectUris

# Create the new application
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

# Add the required permissions to the application
Update-MgApplication -ApplicationId $ClientApp.Id -RequiredResourceAccess $requiredPermissions

# Grant admin consent for the permissions
$tenantId = (Get-MgOrganization).Id
# New-MgOAuth2PermissionGrant -ClientId $ClientApp.AppId -ConsentType "AllPrincipals" -Scope "User.Read User.ReadBasic.All" -ResourceId "00000003-0000-0000-c000-000000000000"
# New-MgOAuth2PermissionGrant -ClientId $ClientApp.AppId -ConsentType "AllPrincipals" -Scope "User.ReadBasic.All" -ResourceId "00000003-0000-0000-c000-000000000000"

## Client Complete
Write-Host 'Client Application Completed with Id: ' + $ClientApp.AppId

Write-Host 'Now Building Server Application'

$ServerApp = New-MgApplication -DisplayName $ServerappName -SignInAudience "AzureADMyOrg"

# Define the client secret parameters
$passwordCred = @{
    displayName = "Automated Secret"
    endDateTime = (Get-Date).AddYears(1)
}
# Create the client secret
$ServerSecret = Add-MgApplicationPassword -ApplicationId $ServerApp.Id -PasswordCredential $passwordCred



Write-Output "Now Establishing API Scopes. Please wait..."
# Define the identifier URIs
$identifierUris = @(
    "api://" + $ServerApp.AppId
)

# Set the identifier URIs for the application
Update-MgApplication -ApplicationId $ServerApp.Id -IdentifierUris $identifierUris

# Now add the App Role

$AdminGuid = new-guid
$appRole = @{
    AllowedMemberTypes = @("User")
    Description = "Administrator of World of Workflows."
    DisplayName = "Administrator"
    Id = $AdminGuid.Guid
    IsEnabled = $true
    Value = "Administrator"
}

# After defining the app role, update the application with the new role
Update-MgApplication -ApplicationId $ServerApp.Id -AppRoles @($appRole)

# Write the first 10 Scopes
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

Update-MgApplication -ApplicationId $ServerApp.Id -Api @{ Oauth2PermissionScopes = @($scope1, $scope2, $scope3, $scope4, $scope5, $scope6, $scope7, $scope8, $scope9, $scope10, $scope11, $scope12, $scope13, $scope14, $scope15, $scope16, $scope17, $scope18, $scope19, $scope20, $scope21, $scope22, $scope23, $scope24, $scope25, $scope26, $scope27, $scope28, $scope29, $scope30, $scope31, $scope32, $scope33, $scope34, $scope35, $scope36, $scope37, $scope38, $scope39, $scope40, $scope41, $scope42, $scope43, $scope44, $scope45, $scope46, $scope47, $scope48, $scope49, $scope50, $scope51, $scope52, $scope53, $scope54, $scope55, $scope56, $scope57) }
Write-Host "Pre-Authorizing Client..."

$PreauthApplication = @{
    AppId = $ClientApp.AppId
    DelegatedPermissionIds = @($scope1Id, $scope2Id, $scope3Id, $scope4Id, $scope5Id, $scope6Id, $scope7Id, $scope8Id, $scope9Id, $scope10Id, $scope11Id, $scope12Id, $scope13Id, $scope14Id, $scope15Id, $scope16Id, $scope17Id, $scope18Id, $scope19Id, $scope20Id, $scope21Id, $scope22Id, $scope23Id, $scope24Id, $scope25Id, $scope26Id, $scope27Id, $scope28Id, $scope29Id, $scope30Id, $scope31Id, $scope32Id, $scope33Id, $scope34Id, $scope35Id, $scope36Id, $scope37Id, $scope38Id, $scope39Id, $scope40Id, $scope41Id, $scope42Id, $scope43Id, $scope44Id, $scope45Id, $scope46Id, $scope47Id, $scope48Id, $scope49Id, $scope50Id, $scope51Id, $scope52Id, $scope53Id, $scope54Id, $scope55Id, $scope56Id, $scope57Id)
}

Update-MgApplication -ApplicationId $ServerApp.Id -Api @{ PreAuthorizedApplications = @($PreauthApplication)}

$org = get-mgorganization

$settings = @{
	"WorldOfWorkflows" =  @{
		"ClientConfiguration" = @{
			"AzureAd" =  @{
				"Authority" = "https://login.microsoftonline.com/" + $org.Id
				"ClientId" = $ClientApp.AppId
				"ValidateAuthority"= $true
			}
			"WorldOfWorkflows"= @{
				"Server"= @{
					"Scopes"= @{
						"Default"= @(
							"api://" + $ServerApp.AppId +"/.default"
						)
					}
				}
			}
		}
	}
    "AzureAd" = @{
        "Instance"="https://login.microsoftonline.com"
        "Domain"=$org.VerifiedDomains[0].Name
        "TenantId"=$org.Id
        "ClientId"=$ServerApp.AppId
        "ClientSecret"=$ServerSecret.SecretText
        "CallbackPath"="/signin.oidc"
        "Roles"= @{
            "DataTypes" = @{
                "Read"= @()
            }
            "Identity" = @{
                "Read"=@()
            }
            "Objects" = @{
                "Types"= @{
                    "Count" = @()
                    "Read" = @()
                    "Write"=@("Administrator")
                    "Delete"=@("Administrator")
                    "Columns"= @{
                        "Read"= @()
                        "Write"=@("Administrator")
                        "Delete"=@("Administrator")
                    }
                }
                "Instances"=@{
                    "Delete"=@("Administrator")
                    "Read"=@{
                        "Basic"=@()
                        "Current"=@("Administrator")
                        "History"=@("Administrator")
                        "Desired"=@("Administrator")
                    }
                    "Write"=@("Administrator")
                    "InvokeWorkflow"=@("Administrator")
                }
            }
            "Plugins"=@{
                "Read"=@("Administrator")
                "Add"=@("Administrator")
            }
            "Server"=@{
            "Backup"=@("Administrator")
            "Restart"=@("Administrator")
            "FixElsa"=@("Administrator")
            }
            "Stats"=@{
                "ReadAllCounts"=@("Administrator")
            }
            "Tasks"=@{
                "Count"=@("Administrator")
                "Read"=@{
                    "All"=@("Administrator")
                    "AssigedTo"=@()
                    "Available"=@()
                }
                "AssignToSelf"=@{
                    "All"=@("Administrator")
                    "Available"=@()
                }
                "Assign"=@{
                    "All"=@("Administrator")
                    "Available"=@("Administrator")
                    "AssignedTo"=@("Administrator")
                }
                "Unassign"=@{
                    "AssignedTo"=@()
                }
                "Close"=@{
                    "All"=@("Administrator")
                    "AssignedTo"=@()
                }
                "Write"=@{
                    "All"=@()
                }
            }
            "Users"=@{
                "Count"= @("Administrator")
            }
            "Views"=@{
                "Definitions"=@{
                    "Count"=@()
                    "Read"=@()
                    "Write"=@("Administrator")
                }
                "Data"=@()
            }
            "Workflows"=@{
                "Activity"=@{
					"Definition:Read"= @( "Administrator" )
					"Statistics:Read"= @( "Administrator" )
				}
				"Scripting:TypeDefinitions:Read"=@()
				"Designer:RuntimeSelectListItems:Read"=@()
				"Features:Read"=@()
				"Definitions"=@{
					"Delete"=@( "Administrator" )
					"Read"=@( "Administrator" )
					"Write"=@( "Administrator" )
					"Publish"=@( "Administrator" )
					"Test"=@( "Administrator" )
				}
				"Invoke"=@("Administrator" )
				"Signal:InvokeByName"=@("Administrator")
				"Conductor"=@{
					"Task:Invoke"=@()
					"Event:Invoke"=@()
				}
				"Instance"=@{
					"ExecutionLog:Read"=@("Administrator")
					"Instance:Cancel"=@("Administrator")
					"Instance:Delete"=@("Administrator")
					"Instance:Retry"=@("Administrator")
					"Instance:Read"=@("Administrator")
				}
				"Secrets:Manage"=@("Administrator")
				"WorkflowStorageProviders:Read"=@()
				"WorkflowProviders:Read"=@()
            }
        }
        "Scopes"=@{
			"DataTypes"=@{
				"Read"="DataTypes.Read.All"
			}
			"Identity"=@{
				"Read"="Identity.Read.Own"
			}
			"Objects"=@{
				"Types"=@{
					"Count"=@("CountStats.Read.All", "ObjectTypes.ReadWrite.All", "ObjectTypes.Read.All" )
					"Read"=@( "ObjectTypes.ReadWrite.All", "ObjectTypes.Read.All", "DataTypes.Read.All" )
					"Write"=@("ObjectTypes.ReadWrite.All", "ObjectTypes.Write.All" )
					"Delete"= "ObjectTypes.Delete.All"
					"Columns"=@{
						"Read"=@( "ObjectTypes.ReadWrite.All", "ObjectTypes.Read.All" )
						"Write"=@( "ObjectTypes.ReadWrite.All", "ObjectTypes.Write.All" )
						"Delete"=@( "ObjectTypes.ReadWrite.All", "ObjectTypes.Write.All" )
					}
				}
				"Instances"=@{
					"Delete"="ObjectInstances.Delete.All"
					"Read"=@{
						"Basic"=@( "ObjectInstances.ReadWrite.All", "ObjectInstances.Read.All", "ObjectInstances.Read.Basic", "ObjectInstances.Read.Current" )
						"Current"=@("ObjectInstances.ReadWrite.All", "ObjectInstances.Read.All", "ObjectInstances.Read.Current" )
						"History"=@( "ObjectInstances.ReadWrite.All", "ObjectInstances.Read.All", "ObjectInstances.Read.History" )
						"Desired"=@("ObjectInstances.ReadWrite.All", "ObjectInstances.Read.All" )
					}
					"Write"=@("ObjectInstances.ReadWrite.All", "ObjectInstances.Write.All")
					"InvokeWorkflow" = "ObjectInstances.InvokeWorkflow.All"
				}
			}
			"Plugins"=@{
				"Read"="Plugins.Read.All"
				"Add"="Plugins.Add"
			}
			"Server"=@{
				"Backup"="Server.Backup"
				"Restart"="Server.Restart"
				"FixElsa"="Server.FixElsa"
			}
			"Stats"=@{
				"ReadAllCounts"="CountStats.Read.All"
			}
			"Tasks"=@{
				"Count"=@("CountStats.Read.All", "Tasks.ReadWrite.All", "Tasks.Read.All" )
				"Read"=@{
					"All"=@( "Tasks.ReadWrite.All", "Tasks.Read.All" )
					"AssignedTo"=@( "Tasks.ReadWrite.All", "Tasks.Read.All", "Tasks.Read.AssignedTo" )
					"Available"=@( "Tasks.ReadWrite.All", "Tasks.Read.All", "Tasks.Read.Available" )
				}
				"AssignToSelf"=@{
					"All"=@( "Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Assign.All", "Tasks.AssignToSelf.All" )
					"Available"=@( "Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Assign.All", "Tasks.Assign.Available", "Tasks.AssignToSelf.All", "Tasks.AssignToSelf.Available" )
				}
				"Assign"=@{
					"All"=@( "Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Assign.All" )
					"Available"=@( "Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Assign.All", "Tasks.Assign.Available" )
					"AssignedTo"=@( "Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Assign.All", "Tasks.Assign.AssignedTo" )
				}
				"Unassign"=@{
					"AssignedTo"=@("Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Assign.All", "Tasks.Unassign.AssignedTo" )
				}
				"Close"= @{
					"All"=@( "Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Close.All" )
					"AssignedTo"=@("Tasks.ReadWrite.All", "Tasks.Write.All", "Tasks.Close.All", "Tasks.Close.AssignedTo" )
				}
				"Write"=@{
					"All"=@("Tasks.ReadWrite.All", "Tasks.Write.All" )
				}
			}
			"Users"=@{
				"Count"="CountStats.Read.All"
			}
			"Views"=@{
				"Definitions"=@{
					"Count"=@( "CountStats.Read.All", "ViewDefinitions.ReadWrite.All", "ViewDefinitions.Read.All" )
					"Read"=@( "ViewDefinitions.ReadWrite.All", "ViewDefinitions.Read.All" )
					"Write"=@( "ViewDefinitions.ReadWrite.All", "ViewDefinitions.Write.All" )
				}
				"Data"=@{
					"Read" = "Views.Read.All"
				}
			}
			"Workflows"=@{
				"Activity"=@{
					"Definition:Read"=@("WorkflowDesigner.Read.All", "WorkflowActivityDefinition.Read.All" )
					"Statistics:Read"=@("WorkflowActivityStatistics.Read.All")
				}
				"Scripting:TypeDefinitions:Read"=@("WorkflowDesigner.Read.All")
				"Designer:RuntimeSelectListItems:Read"=@("WorkflowDesigner.Read.All")
				"Features:Read" =@("WorkflowDesigner.Read.All")
				"Definitions"=@{
					"Delete"=@("WorkflowDefinition.Delete.All")
					"Read"=@("WorkflowDefinition.ReadWrite.All","WorkflowDefinition.Read.All")
					"Write"=@("WorkflowDefinition.ReadWrite.All","WorkflowDefinition.Write.All")
					"Publish"=@("WorkflowDefinition.Publish.All")
					"Test"=@("Workflow.Invoke.All",	"WorkflowDefinition.Test.All")
				}
				"Invoke"=@(	"Workflow.Invoke.All")
				"Signal:InvokeByName"=@("WorkflowSignal.InvokeByName.All")
				"Conductor"=@{
					"Task:Invoke"=@("Workflow.Invoke.All","WorkflowConductor.Invoke.All","WorkflowConductor.Invoke.Tasks")
					"Event:Invoke"=@("Workflow.Invoke.All","WorkflowConductor.Invoke.All","WorkflowConductor.Invoke.Events")
				}
				"Instance"=@{
					"ExecutionLog:Read"=@("WorkflowInstanceExecutionLog.Read.All")
					"Instance:Cancel"=@("WorkflowInstance.Cancel.All")
					"Instance:Delete"=@("WorkflowInstance.Delete.All")
					"Instance:Retry"=@("WorkflowInstance.Retry.All")
					"Instance:Read"=@("WorkflowInstance.Read.All")
				
				}
				"Secrets:Manage"=@("WorkflowSecrets.ReadWrite.All")
				"WorkflowStorageProviders:Read"=@("WorkflowDesigner.Read.All")
                "WorkflowProviders:Read"=@("WorkflowDesigner.Read.All")
			}
		}
        "OpenApi"=@{
			"ClientId"= $ClientApp.AppId
			"Name"="Azure Active Directory"
			"Description"="Azure Active Directory using OAuth2.0"
			"AuthorizationCode"=@{
				"AuthorizationUrl" = "https://login.microsoftonline.com/" + $org.Id + "/oauth2/v2.0/authorize"
				"TokenUrl" = "https://login.microsoftonline.com/" + $org.Id + "/oauth2/v2.0/token"
			}
			"Scopes"=@{
				"CountStats.Read.All"=@{
					"Value"="api://" + $serverapp.AppId + "/CountStats.Read.All"
					"Description"="Read count statistical conuts"
				}
				"DataTypes.Read.All"=@{
					"Value"="api://" + $serverapp.AppId + "/DataTypes.Read.All"
					"Description"="Read data types"
				}
				"Identity.Read.Own"=@{
					"Value" = "api://" + $serverapp.AppId + "/Identity.Read.Own"
					"Description" = "Read permissions"
				}
				"ObjectInstances.Delete.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.Delete.All"
					"Description" = "Delete object instances"
				}
				"ObjectInstances.InvokeWorkflow.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.InvokeWorkflow.All"
					"Description" = "Invoke object instance workflows"
				}
				"ObjectInstances.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.Read.All"
					"Description" = "Read object instances"
				}
				"ObjectInstances.Read.Basic"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.Read.Basic"
					"Description" = "Read basic object instance info"
				}
				"ObjectInstances.Read.Current"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.Read.Current"
					"Description" = "Read current object instance data"
				}
				"ObjectInstances.Read.History"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.Read.History"
					"Description" = "Read object instance history"
				}
				"ObjectInstances.ReadWrite.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.ReadWrite.All"
					"Description" = "Read and write object instances"
				}
				"ObjectInstances.Write.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectInstances.Write.All"
					"Description" = "Create and update object instances"
				}
				"ObjectTypes.Delete.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectTypes.Delete.All"
					"Description" = "Delete object types"
				}
				"ObjectTypes.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectTypes.Read.All"
					"Description" = "Read object type definitions"
				}
				"ObjectTypes.ReadWrite.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectTypes.ReadWrite.All"
					"Description" = "Read and write object type definitions"
				}
				"ObjectTypes.Write.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ObjectTypes.Write.All"
					"Description" = "Write object instances"
				}
				"Plugins.Add"=@{
					"Value" = "api://" + $serverapp.AppId + "/Plugins.Add"
					"Description" = "Add plugins"
				}
				"Plugins.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Plugins.Read.All"
					"Description" = "Read plugins"
				}
				"Server.Backup"=@{
					"Value" = "api://" + $serverapp.AppId + "/Server.Backup"
					"Description" = "Initiate database backup"
				}
				"Server.FixElsa"=@{
					"Value" = "api://" + $serverapp.AppId + "/Server.FixElsa"
					"Description" = "Repair Elsa HTTP endpoints"
				}
				"Server.Restart"=@{
					"Value" = "api://" + $serverapp.AppId + "/Server.Restart"
					"Description" = "Restart the server"
				}
				"Tasks.Assign.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Assign.All"
					"Description" = "Assign tasks to any user"
				}
				"Tasks.Assign.AssignedTo"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Assign.AssignedTo"
					"Description" = "Reassign tasks to any user"
				}
				"Tasks.Assign.Available"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Assign.Available"
					"Description" = "Assign available tasks to any user"
				}
				"Tasks.AssignToSelf.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.AssignToSelf.All"
					"Description" = "Pick any tasks"
				}
				"Tasks.AssignToSelf.Available"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.AssignToSelf.Available"
					"Description" = "Pick available tasks"
				}
				"Tasks.Close.All" = @{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Close.All"
					"Description" = "Close all tasks"
				}
				"Tasks.Close.AssignedTo"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Close.AssignedTo"
					"Description" = "Close assigned tasks"
				}
				"Tasks.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Read.All"
					"Description" = "Read all tasks"
				}
				"Tasks.Read.Assigned"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Read.Assigned"
					"Description" = "Read assigned tasks"
				}
				"Tasks.Read.AssignedTo"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Read.AssignedTo"
					"Description" = "Read assigned tasks"
				}
				"Tasks.Read.Available"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Read.Available"
					"Description" = "Read available tasks"
				}
				"Tasks.ReadWrite.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.ReadWrite.All"
					"Description" = "Read and write tasks"
				}
				"Tasks.Unassign.AssignedTo"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Unassign.AssignedTo"
					"Description" = "Deallocate assigned task"
				}
				"Tasks.Write.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Tasks.Write.All"
					"Description" = "Write tasks"
				}
				"ViewDefinitions.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ViewDefinitions.Read.All"
					"Description" = "Read view definitions"
				}
				"ViewDefinitions.ReadWrite.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ViewDefinitions.ReadWrite.All"
					"Description" = "Read and write view defintions"
				}
				"ViewDefinitions.Write.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/ViewDefinitions.Write.All"
					"Description" = "Write view definitions"
				}
				"Views.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Views.Read.All"
					"Description" = "Read view data"
				}
				"Workflow.Invoke.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/Workflow.Invoke.All"
					"Description" = "Invoke workflows"
				}
				"WorkflowActivityDefinition.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowActivityDefinition.Read.All"
					"Description" = "Read workflow activity definitions"
				}
				"WorkflowActivityStatistics.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowActivityStatistics.Read.All"
					"Description" = "Read workflow activity statistics"
				}
				"WorkflowConductor.Invoke.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowConductor.Invoke.All"
					"Description" = "Invoke workflow conductors"
				}
				"WorkflowConductor.Invoke.Events"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowConductor.Invoke.Events"
					"Description" = "Invoke workflow conductor events"
				}
				"WorkflowConductor.Invoke.Tasks"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowConductor.Invoke.Tasks"
					"Description" = "Invoke workflow conductor tasks"
				}
				"WorkflowDefinition.Delete.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowDefinition.Delete.All"
					"Description" = "Delete workflow definitions"
				}
				"WorkflowDefinition.Publish.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowDefinition.Publish.All"
					"Description" = "Publish workflow definitions"
				}
				"WorkflowDefinition.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowDefinition.Read.All"
					"Description" = "Read workflow definitions"
				}
				"WorkflowDefinition.ReadWrite.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowDefinition.ReadWrite.All"
					"Description" = "Read and write workflow definitions"
				}
				"WorkflowDefinition.Test.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowDefinition.Test.All"
					"Description" = "Test workflow definitions"
				}
				"WorkflowDefinition.Write.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowDefinition.Write.All"
					"Description" = "Write workflow definitions"
				}
				"WorkflowDesigner.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowDesigner.Read.All"
					"Description" = "Use workflow designer"
				}
				"WorkflowInstance.Cancel.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowInstance.Cancel.All"
					"Description" = "Cancel workflow instances"
				}
				"WorkflowInstance.Delete.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowInstance.Delete.All"
					"Description" = "Delete workflow instances"
				}
				"WorkflowInstance.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowInstance.Read.All"
					"Description" = "Read workflow instances"
				}
				"WorkflowInstance.Retry.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowInstance.Retry.All"
					"Description" = "Retry workflow instances"
				}
				"WorkflowInstanceExecutionLog.Read.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowInstanceExecutionLog.Read.All"
					"Description" = "Read workflow instance execution logs"
				}
				"WorkflowSecrets.ReadWrite.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowSecrets.ReadWrite.All"
					"Description" = "Read and write workflow secrets"
				}
				"WorkflowSignal.InvokeByName.All"=@{
					"Value" = "api://" + $serverapp.AppId + "/WorkflowSignal.InvokeByName.All"
					"Description" = "Invoke workflow signals by name"
				}
			}
		}
	}
    "Logging"=@{
        "LogLevel.Disabled"=@{
            "Default"="Warning"
            "Microsoft"="Warning"
            "Microsoft.Hosting.Lifetime"="Warning"
            "Microsoft.EntityFrameworkCore.*"="Warning"
            "HubOneWorkflows.MetaModel.*"="Warning"
        }
    }
    "Plugins"=@{
		"CertificatePath"= "./WorldOfWorkflows.cer"
		"PluginLocation"="/data/plugins"
		"PEDBFolder"="/data/pedb"
		"UntrustedPluginLocation"="/data/plugins-untrusted"
		"UpgradedPluginLocation"="/data/plugins-upgraded"
		"InstalledPluginLocation"= "/data/Plugins/Installed"
		"EnabledPluginLocation"= "/data/Plugins/Enabled"
		"TemporaryPluginLocation"= "/data/Plugins/Temp"
		"PluginConfigurationFile"= "/data/Plugins/PluginConfiguration.json"
		"CommunityCertificateFolder"= "/data/Plugins/Community-Certificates"

    }
    "ConnectionStrings"=@{
        "H1WFSQlite"="Data Source=/data/worldofworkflows.db;Cache=Shared;"
        "H1SQL"="Server=.;Database=WorldOfWorkflows;Trusted_Connection=True;Encrypt=False;"
        "Sqlite"="Data Source=/data/worldofworkflows.db;Cache=Shared;"
    }
    "AllowedHosts"="*"
    "ConnectionType"="SQLite"
    "Elsa"=@{
		"Features"=@{
			"DefaultPersistence"=@{
				"Enabled"=$true
				"Framework"="EntityFrameworkCore"
				"ConnectionStringIdentifier"="Sqlite"
			}
			"DispatcherHangfire"=$false
			"Console"=$true
			"Http"=$true
			"Email"=$true
			"TemporalQuartz"=$true
			"JavaScriptActivities"=$true
			"UserTask"=$true
			"Conductor"=$true
			"Telnyx"=$true
			"File"=$true
			"Azure"=@{
				"ServiceBus"=@{
					"Enabled"=$false
					"ConnectionStringName"="AzureServiceBus"
				}
			}
			"Webhooks"=@{
				"Enabled"=$true
				"Framework"="EntityFrameworkCore"
				"ConnectionStringIdentifier"="Sqlite"
			}
			"WorkflowSettings"=@{
				"Enabled"=$true
				"Framework"= "EntityFrameworkCore"
				"ConnectionStringIdentifier"="Sqlite"
			}
			"RabbitMq"=@{
				"Enabled"=$false
				"ConnectionStringIdentifier"="RabbitMq"
			}
			"Mqtt"=@{
				"Enabled"=$false
			}
			"ExecuteSqlServerQuery"=@{
				"Enabled"=$true
			}
			"Secrets"=@{
				"Http"=$true
				"Enabled"=$true
				"Framework"="EntityFrameworkCore"
				"ConnectionStringIdentifier"="Sqlite"
			}
		}
		"WorkflowChannels"=@{
			"Channels"=@( "High","Normal","Low" )
			"Default"="Normal"
		}
		"Smtp"=@{
			"Host"="localhost"
			"Port"="2525"
			"DefaultSender"="noreply@acme.com"
		}
		"Retention"=@{
			"SweepInterval"="1:00:00:00"
			"TimeToLive"="1:00:00:00"
			"BatchSize"="10"
		}
		"Server"=@{
			"BaseUrl"=$BaseAddress
			"FrontendBaseUrl"="/workflowdashboard"
		}
	}
	"Backup"=$true
	"BackupToAzureStorage"=$false
	"BackupStorageConnectionString"=""
	"Cors"=@{
		"AllowedOrigins"=$BaseAddress
	}
	"Workflows"=@{
		"Info"=@{
			"title"="World of Workflows"
			"description"="This is the API for this implementation of World of Workflows."
			"termsOfService"="https://worldofworkflows.com/terms"
			"contact"=@{
				"name"="API Support"
				"url"="https://worldofworkflows.com/support"
				"email"="support@worldofworkflows.com"
			}
		}
	}
}


    $json = $settings | convertto-json -Depth 10
    $json | Set-Content -Path "appsettings2.json"