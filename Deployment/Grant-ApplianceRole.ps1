# Grant Managed Identity Operator to Appliance Resource Provider
# ================================================================
# This script grants the managed application's Appliance Resource Provider
# permission to use the managed identity during deployment

param(
    [Parameter(Mandatory=$false)]
    [string]$ApplianceApplicationId = "35cbcc06-defd-44d2-ace4-bc2bf2466970",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "WorldOfWorkflows-Setup",
    
    [Parameter(Mandatory=$false)]
    [string]$IdentityName = "WoW-Installer"
)

$ErrorActionPreference = 'Stop'

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Grant Managed Identity Operator Role                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting subscription context..." -ForegroundColor Cyan
    $null = Set-AzContext -SubscriptionId $SubscriptionId
}

$context = Get-AzContext
Write-Host "Using subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Host ""

# Get the managed identity
Write-Host "Finding managed identity..." -ForegroundColor Cyan
try {
    $identity = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $IdentityName
    Write-Host "✅ Found: $($identity.Name)" -ForegroundColor Green
    Write-Host "   Resource ID: $($identity.Id)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Could not find managed identity" -ForegroundColor Red
    Write-Host "   Resource Group: $ResourceGroupName" -ForegroundColor Gray
    Write-Host "   Identity Name: $IdentityName" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Find the Appliance Resource Provider's service principal
Write-Host "Looking up Appliance Resource Provider..." -ForegroundColor Cyan
Write-Host "  Application ID: $ApplianceApplicationId" -ForegroundColor Gray

try {
    $sp = Get-AzADServicePrincipal -ApplicationId $ApplianceApplicationId
    
    if (-not $sp) {
        Write-Host "❌ Service principal not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "This could mean:" -ForegroundColor Yellow
        Write-Host "  1. The application ID is incorrect" -ForegroundColor Gray
        Write-Host "  2. The service principal hasn't been created yet" -ForegroundColor Gray
        Write-Host "  3. You don't have permission to view it" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Try finding the correct Application ID from the error message." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Found service principal" -ForegroundColor Green
    Write-Host "   Object ID: $($sp.Id)" -ForegroundColor Gray
    Write-Host "   Display Name: $($sp.DisplayName)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Error looking up service principal" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""

# Grant Managed Identity Operator role
Write-Host "Granting 'Managed Identity Operator' role..." -ForegroundColor Cyan
Write-Host "  To: $($sp.DisplayName)" -ForegroundColor Gray
Write-Host "  On: $($identity.Name)" -ForegroundColor Gray
Write-Host ""

try {
    # Check if already assigned
    $existingRole = Get-AzRoleAssignment `
        -ObjectId $sp.Id `
        -RoleDefinitionName "Managed Identity Operator" `
        -Scope $identity.Id `
        -ErrorAction SilentlyContinue
    
    if ($existingRole) {
        Write-Host "✅ Role already assigned - no action needed" -ForegroundColor Green
    } else {
        New-AzRoleAssignment `
            -ObjectId $sp.Id `
            -RoleDefinitionName "Managed Identity Operator" `
            -Scope $identity.Id
        
        Write-Host "✅ Role assigned successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "⏱️  Wait 2-3 minutes for role to propagate before deploying" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to assign role" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Message -like "*does not exist*") {
        Write-Host ""
        Write-Host "The service principal may not exist in your tenant yet." -ForegroundColor Yellow
        Write-Host "This happens if the managed app hasn't been deployed before." -ForegroundColor Gray
    }
    
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "The Appliance Resource Provider can now use this managed identity." -ForegroundColor Gray
Write-Host "You can proceed with your marketplace deployment." -ForegroundColor Gray
Write-Host ""
