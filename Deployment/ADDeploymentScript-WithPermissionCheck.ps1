# World of Workflows - Azure AD Setup Script with Permission Checking
# This script wraps the main AD deployment script and checks permissions first

param(
    [string]$TenantId,
    [string]$ServerappName,
    [string]$ClientappName,
    [string]$BaseAddress,
    [string]$AdminUserPrincipalName
)

$ErrorActionPreference = 'Stop'

Write-Host "═══════════════════════════════════════════════════════════"
Write-Host "World of Workflows - Azure AD Application Setup"
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host ""

# Get current identity information
$identity = Get-AzUserAssignedIdentity -ResourceGroupName $env:AZURE_RESOURCE_GROUP -Name "$($env:SITE_NAME)-installer-identity"
$principalId = $identity.PrincipalId

Write-Host "Configuration:"
Write-Host "  Tenant ID: $TenantId"
Write-Host "  Server App: $ServerappName"
Write-Host "  Client App: $ClientappName"
Write-Host "  Base Address: $BaseAddress"
Write-Host "  Admin UPN: $AdminUserPrincipalName"
Write-Host "  Identity Principal ID: $principalId"
Write-Host ""

# Check if managed identity has required permissions
Write-Host "Checking Azure AD permissions..."
Write-Host ""

try {
    # Try to connect to Graph using managed identity
    $token = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }
    
    # Try to read applications (requires at least Application.Read.All)
    Write-Host "Testing Graph API access..."
    $testUri = "https://graph.microsoft.com/v1.0/applications?`$top=1"
    $testResponse = Invoke-RestMethod -Uri $testUri -Headers $headers -Method Get -ErrorAction Stop
    
    Write-Host "✅ Can read applications" -ForegroundColor Green
    
    # Try to create a test application
    Write-Host "Testing application creation permission..."
    $testAppBody = @{
        displayName = "WoW-PermissionTest-$(Get-Random)"
    } | ConvertTo-Json
    
    try {
        $testApp = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/applications" -Headers $headers -Method Post -Body $testAppBody -ErrorAction Stop
        Write-Host "✅ Can create applications" -ForegroundColor Green
        
        # Clean up test app
        Start-Sleep -Seconds 2
        Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/applications/$($testApp.id)" -Headers $headers -Method Delete -ErrorAction SilentlyContinue
        Write-Host "✅ Permission check passed" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        throw "Cannot create applications - permission check failed"
    }
    
} catch {
    Write-Host "❌ PERMISSION CHECK FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "The managed identity does not have permission to create Azure AD applications." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "REQUIRED ACTION:" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Your Global Administrator must grant permissions by running:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Download the permission script:" -ForegroundColor White
    Write-Host "     https://releases.worldofworkflows.com/Grant-WoWPermissions.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Run in PowerShell:" -ForegroundColor White
    Write-Host "     .\Grant-WoWPermissions.ps1 -ManagedResourceGroupName '$env:AZURE_RESOURCE_GROUP' -SiteName '$env:SITE_NAME'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative - Manual PowerShell Commands:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Connect-MgGraph -Scopes 'AppRoleAssignment.ReadWrite.All'" -ForegroundColor Gray
    Write-Host "  `$identity = Get-AzUserAssignedIdentity -Name '$($env:SITE_NAME)-installer-identity' -ResourceGroupName '$env:AZURE_RESOURCE_GROUP'" -ForegroundColor Gray
    Write-Host "  `$graphSp = Get-MgServicePrincipal -Filter `"appId eq '00000003-0000-0000-c000-000000000000'`"" -ForegroundColor Gray
    Write-Host "  `$appRole = `$graphSp.AppRoles | Where-Object {`$_.Value -eq 'Application.ReadWrite.All'}" -ForegroundColor Gray
    Write-Host "  New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId `$identity.PrincipalId -PrincipalId `$identity.PrincipalId -ResourceId `$graphSp.Id -AppRoleId `$appRole.Id" -ForegroundColor Gray
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After granting permissions:" -ForegroundColor Cyan
    Write-Host "  • Wait 2-3 minutes for permissions to propagate" -ForegroundColor Gray
    Write-Host "  • The deployment will automatically retry" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor DarkGray
    Write-Host ""
    
    # Write output for retry logic
    $output = @{
        status = "PermissionsRequired"
        message = "Managed identity requires Application.ReadWrite.All permission"
        principalId = $principalId
        resourceGroup = $env:AZURE_RESOURCE_GROUP
        siteName = $env:SITE_NAME
    }
    
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['status'] = "PermissionsRequired"
    
    # Exit with error
    throw "Permissions required - see instructions above"
}

Write-Host "Proceeding with Azure AD application creation..."
Write-Host ""

# Download and execute the main script
$mainScriptUrl = "https://raw.githubusercontent.com/World-of-Workflows/Business-Edition/main/Deployment/ADDeploymentScript.ps1"
$mainScript = Invoke-RestMethod -Uri $mainScriptUrl

# Create a temporary file
$tempFile = New-TemporaryFile
Set-Content -Path $tempFile.FullName -Value $mainScript

# Execute the main script
& $tempFile.FullName -TenantId $TenantId -ServerappName $ServerappName -ClientappName $ClientappName -BaseAddress $BaseAddress -AdminUserPrincipalName $AdminUserPrincipalName

# Clean up
Remove-Item $tempFile.FullName -Force

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host "Azure AD Setup Complete"
Write-Host "═══════════════════════════════════════════════════════════"
