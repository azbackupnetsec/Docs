Param(
    [parameter(position=0,Mandatory=$true)]
    $subscription,
    
    [parameter(position=1,Mandatory=$true)]
    $vaultPEName,

    [parameter(position=2,Mandatory=$true)]
    $vaultPEResourceGroup,

    [parameter(position=3,Mandatory=$true)]
    $dnsResourceGroup,
    
    [parameter(position=4,Mandatory=$true)]
    $privatezone
)
Install-Module Az.PrivateDns
Import-Module -Name Az.PrivateDns

Connect-AzAccount
Set-AzContext -SubscriptionId $subscription

$privateEndpoint = Get-AzPrivateEndpoint -Name $vaultPEName -ResourceGroupName $vaultPEResourceGroup

$zone = Get-AzPrivateDnsZone -ResourceGroupName $dnsResourceGroup -Name $privatezone 
 
$networkInterface = Get-AzResource -ResourceId $privateEndpoint.NetworkInterfaces[0].Id -ApiVersion "2019-04-01" 
 
foreach ($ipconfig in $networkInterface.properties.ipConfigurations)
{ 
    foreach ($fqdn in $ipconfig.properties.privateLinkConnectionProperties.fqdns)
    { 
        Write-Host "$($ipconfig.properties.privateIPAddress) $($fqdn)"  

        $recordName = $fqdn.split('.',2)[0] 
        $dnsZone = $fqdn.split('.',2)[1] 

        $dnsZone
        $dneentry = $recordName
        $dneentry

        $recordSet =  Get-AzPrivateDnsRecordSet -ResourceGroupName $dnsResourceGroup -ZoneName $privatezone -Name $dneentry -RecordType A 
        
        if($recordSet -eq $null)
        {
            New-AzPrivateDnsRecordSet -Name $dneentry -RecordType A -ZoneName $privatezone  `
                -ResourceGroupName $dnsResourceGroup -Ttl 600 `
                -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $ipconfig.properties.privateIPAddress)  
        }
        else
        {
            Get-AzPrivateDnsRecordSet -ResourceGroupName $dnsResourceGroup -ZoneName $privatezone -Name $dneentry -RecordType A | Add-AzPrivateDnsRecordConfig -Ipv4Address $ipconfig.properties.privateIPAddress | Set-AzPrivateDnsRecordSet
        }
    } 
}

