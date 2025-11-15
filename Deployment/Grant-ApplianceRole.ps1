# Grant Managed Identity Operator to Appliance Resource Provider
# ================================================================
# This script grants the managed application's Appliance Resource Provider
# permission to use the managed identity during deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$ApplianceResourceProviderId = "35cbcc06-defd-44d2-ace4-bc2bf2466970",
    
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

# Grant Managed Identity Operator role
Write-Host "Granting 'Managed Identity Operator' role..." -ForegroundColor Cyan
Write-Host "  To: Appliance Resource Provider ($ApplianceResourceProviderId)" -ForegroundColor Gray
Write-Host "  On: $($identity.Name)" -ForegroundColor Gray
Write-Host ""

try {
    # Check if already assigned
    $existingRole = Get-AzRoleAssignment `
        -ObjectId $ApplianceResourceProviderId `
        -RoleDefinitionName "Managed Identity Operator" `
        -Scope $identity.Id `
        -ErrorAction SilentlyContinue
    
    if ($existingRole) {
        Write-Host "✅ Role already assigned - no action needed" -ForegroundColor Green
    } else {
        New-AzRoleAssignment `
            -ObjectId $ApplianceResourceProviderId `
            -RoleDefinitionName "Managed Identity Operator" `
            -Scope $identity.Id
        
        Write-Host "✅ Role assigned successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "⏱️  Wait 2-3 minutes for role to propagate before deploying" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to assign role" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
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
