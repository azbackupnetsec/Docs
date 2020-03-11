Param(
[parameter(position=0,Mandatory=$true)]
$subscription,
[parameter(position=1,Mandatory=$true)]
$vaultPEResourceGroup,
[parameter(position=2,Mandatory=$true)]
$vaultPESubnetResourceGroup,
[parameter(position=3,Mandatory=$true)]
$vaultMsiName)

Install-Module Az.Resources
Import-Module Az.Resources

Connect-AzAccount
Set-AzContext -SubscriptionId $subscription

$role = Get-AzRoleDefinition "PrivateEndpointContributorRole"
if($role  -eq $null)
{
    ## Creating role 'PrivateEndpointContributorRole'
    $role = [Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition]::new()
    $role.Name = 'PrivateEndpointContributorRole'
    $role.Description = 'Allows management of Private Endpoint'
    $role.IsCustom = $true
    $perms = 'Microsoft.Network/privateEndpoints/*'
    $role.Actions = $perms
    $subs = '/subscriptions/' + $subscription
    $role.AssignableScopes = $subs
    New-AzRoleDefinition -Role $role
}

$role = Get-AzRoleDefinition "PrivateEndpointSubnetContributorRole"
if($role  -eq $null)
{
    ## Creating role 'PrivateEndpointSubnetContributorRole'
    $role = [Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition]::new()
    $role.Name = 'PrivateEndpointSubnetContributorRole'
    $role.Description = 'Allows adding of Private Endpoint connection to Virtual Networks'
    $role.IsCustom = $true
    $perms = 'Microsoft.Network/virtualNetworks/subnets/join/action'
    $role.Actions = $perms
    $subs = '/subscriptions/' + $subscription
    $role.AssignableScopes = $subs
    New-AzRoleDefinition -Role $role
}

$role = Get-AzRoleDefinition "NetworkInterfaceReaderRole"
if($role  -eq $null)
{
    ## Creating role 'NetworkInterfaceReaderRole'
    $role = [Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition]::new()
    $role.Name = 'NetworkInterfaceReaderRole'
    $role.Description = 'Allows read on networkInterfaces'
    $role.IsCustom = $true
    $perms = 'Microsoft.Network/networkInterfaces/read'
    $role.Actions = $perms
    $subs = '/subscriptions/' + $subscription
    $role.AssignableScopes = $subs
    New-AzRoleDefinition -Role $role
}

$msiObjId = ((Get-AzADServicePrincipal -SearchString $vaultMsiName)[0]).Id

$rolesNamesForVaultPERg = @("PrivateEndpointContributorRole", "NetworkInterfaceReaderRole", "Private DNS Zone Contributor")

foreach ($roleName in $rolesNamesForVaultPERg)
{
    $role= Get-AzRoleAssignment -ObjectId $msiObjId -RoleDefinitionName $roleName -ResourceGroupName $vaultPEResourceGroup

    if($role -eq $null)
    {
        New-AzRoleAssignment -ObjectId $msiObjId -RoleDefinitionName $roleName -ResourceGroupName $vaultPEResourceGroup
    }
    else
    {
        Write-Host("Already assigned role for " + $roleName)
    }
}

$rolesNamesForSubnetRg = @("PrivateEndpointSubnetContributorRole", "Private DNS Zone Contributor")

foreach ($roleName in $rolesNamesForSubnetRg)
{
    $role= Get-AzRoleAssignment -ObjectId $msiObjId -RoleDefinitionName $roleName -ResourceGroupName $vaultPESubnetResourceGroup

    if($role -eq $null)
    {
        New-AzRoleAssignment -ObjectId $msiObjId -RoleDefinitionName $roleName -ResourceGroupName $vaultPESubnetResourceGroup
    }
    else
    {
        Write-Host("Already assigned role for " + $roleName)
    }
}


