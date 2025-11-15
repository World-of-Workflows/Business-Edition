# World of Workflows - Post-Deployment Permission Setup
# =====================================================
# Run this script AFTER deploying World of Workflows from Azure Marketplace
# Requires: Global Administrator role in Azure AD
#
# This script grants the deployment identity permission to complete Azure AD setup

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ManagedResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$SiteName
)

$ErrorActionPreference = 'Stop'

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  World of Workflows - Permission Setup                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "⚠️  Microsoft Graph PowerShell module not found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installing Microsoft.Graph module..."
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
    Write-Host "✅ Module installed" -ForegroundColor Green
}

# Prompt for parameters if not provided
if (-not $ManagedResourceGroupName) {
    Write-Host "Please provide the Managed Resource Group name" -ForegroundColor Yellow
    Write-Host "This is typically: <YourSiteName>MRG" -ForegroundColor Gray
    Write-Host ""
    $ManagedResourceGroupName = Read-Host "Managed Resource Group Name"
}

if (-not $SiteName) {
    Write-Host ""
    Write-Host "Please provide your site name" -ForegroundColor Yellow
    Write-Host "This is the name you chose during deployment" -ForegroundColor Gray
    Write-Host ""
    $SiteName = Read-Host "Site Name"
}

$identityName = "$SiteName-installer-identity"

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Managed Resource Group: $ManagedResourceGroupName" -ForegroundColor Gray
Write-Host "  Site Name: $SiteName" -ForegroundColor Gray
Write-Host "  Identity Name: $identityName" -ForegroundColor Gray
Write-Host ""

# Confirm user wants to proceed
$confirm = Read-Host "Continue? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "❌ Setup cancelled" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 1: Checking Azure Login" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "⚠️  Not logged into Azure" -ForegroundColor Yellow
        Write-Host "Please login..."
        Connect-AzAccount
        $context = Get-AzContext
    }
    Write-Host "✅ Logged in as: $($context.Account.Id)" -ForegroundColor Green
    Write-Host "   Tenant: $($context.Tenant.Id)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to connect to Azure" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 2: Finding Managed Identity" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "Looking for identity: $identityName"
    Write-Host "In resource group: $ManagedResourceGroupName"
    
    $identity = Get-AzUserAssignedIdentity -Name $identityName -ResourceGroupName $ManagedResourceGroupName -ErrorAction Stop
    
    if (-not $identity) {
        throw "Identity not found"
    }
    
    $principalId = $identity.PrincipalId
    $clientId = $identity.ClientId
    
    Write-Host "✅ Found managed identity" -ForegroundColor Green
    Write-Host "   Resource ID: $($identity.Id)" -ForegroundColor Gray
    Write-Host "   Principal ID: $principalId" -ForegroundColor Gray
    Write-Host "   Client ID: $clientId" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Failed to find managed identity" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "  1. The deployment hasn't created the identity yet (wait a few minutes)" -ForegroundColor Gray
    Write-Host "  2. The resource group name is incorrect" -ForegroundColor Gray
    Write-Host "  3. The site name is incorrect" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 3: Connecting to Microsoft Graph" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  You will be prompted to sign in with Global Administrator privileges" -ForegroundColor Yellow
Write-Host ""

try {
    Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All" -NoWelcome
    
    $mgContext = Get-MgContext
    Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green
    Write-Host "   Account: $($mgContext.Account)" -ForegroundColor Gray
    Write-Host "   Tenant ID: $($mgContext.TenantId)" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Failed to connect to Microsoft Graph" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 4: Granting Azure AD Permissions" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

try {
    # Get Microsoft Graph service principal
    Write-Host "Getting Microsoft Graph service principal..."
    $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
    
    if (-not $graphSp) {
        throw "Could not find Microsoft Graph service principal"
    }
    
    Write-Host "✅ Found Microsoft Graph service principal" -ForegroundColor Green
    Write-Host "   Service Principal ID: $($graphSp.Id)" -ForegroundColor Gray
    
    # Get Application.ReadWrite.All app role
    Write-Host ""
    Write-Host "Finding Application.ReadWrite.All permission..."
    $appRole = $graphSp.AppRoles | Where-Object {$_.Value -eq "Application.ReadWrite.All"}
    
    if (-not $appRole) {
        throw "Could not find Application.ReadWrite.All app role"
    }
    
    Write-Host "✅ Found Application.ReadWrite.All permission" -ForegroundColor Green
    Write-Host "   Permission ID: $($appRole.Id)" -ForegroundColor Gray
    
    # Check if permission already granted
    Write-Host ""
    Write-Host "Checking for existing permissions..."
    $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $principalId -ErrorAction SilentlyContinue |
        Where-Object { $_.AppRoleId -eq $appRole.Id -and $_.ResourceId -eq $graphSp.Id }
    
    if ($existingAssignment) {
        Write-Host "✅ Permission already granted!" -ForegroundColor Green
        Write-Host "   No action needed - the managed identity already has the required permissions" -ForegroundColor Gray
    } else {
        # Grant the permission
        Write-Host "Granting Application.ReadWrite.All permission..."
        
        $params = @{
            ServicePrincipalId = $principalId
            PrincipalId = $principalId
            ResourceId = $graphSp.Id
            AppRoleId = $appRole.Id
        }
        
        New-MgServicePrincipalAppRoleAssignment @params | Out-Null
        
        Write-Host "✅ Permission granted successfully!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "❌ Failed to grant permissions" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Message -like "*Insufficient privileges*") {
        Write-Host "⚠️  Your account does not have sufficient privileges" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Requirements:" -ForegroundColor Yellow
        Write-Host "  • Global Administrator role" -ForegroundColor Gray
        Write-Host "  OR" -ForegroundColor Gray
        Write-Host "  • Privileged Role Administrator role" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Please ask your Global Administrator to run this script" -ForegroundColor Yellow
    } else {
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 5: Verifying Permissions" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

try {
    $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $principalId
    
    Write-Host "Current permissions for $identityName" ":" -ForegroundColor Cyan
    Write-Host ""
    
    $hasRequiredPermission = $false
    
    foreach ($assignment in $assignments) {
        $resource = Get-MgServicePrincipal -ServicePrincipalId $assignment.ResourceId
        $role = $resource.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }
        
        $status = if ($role.Value -eq "Application.ReadWrite.All") {
            $hasRequiredPermission = $true
            "✅"
        } else {
            "  "
        }
        
        Write-Host "  $status $($resource.DisplayName) - $($role.Value)" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    if ($hasRequiredPermission) {
        Write-Host "✅ Verification complete - all required permissions are in place" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning: Could not verify Application.ReadWrite.All permission" -ForegroundColor Yellow
        Write-Host "   The deployment may still work if the permission is propagating" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "⚠️  Could not verify permissions (this is not critical)" -ForegroundColor Yellow
    Write-Host "   The permission was granted but verification failed" -ForegroundColor Gray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Setup Complete! 🎉" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 2-3 minutes for permissions to propagate" -ForegroundColor Gray
Write-Host "  2. The deployment will automatically continue" -ForegroundColor Gray
Write-Host "  3. Check the deployment status in Azure Portal" -ForegroundColor Gray
Write-Host ""
Write-Host "Your World of Workflows instance will be available at:" -ForegroundColor Cyan
Write-Host "  https://$SiteName.azurewebsites.net" -ForegroundColor White
Write-Host ""

# Disconnect from Graph
Disconnect-MgGraph | Out-Null
