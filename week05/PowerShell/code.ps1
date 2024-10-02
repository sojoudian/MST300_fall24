# Set variables for resource names
$resourceGroupName = "MyResourceGroup"
$location = "eastus"
$vnetName = "vm1-vnet"
$subnetName = "default"
$publicIpName = "vm1-pip"
$nicName = "vm1-nic"
$vmName = "vm1"
$storageAccountName = "vm1storagemaziar"
$nsgName = "vm1-nsg"
$adminUsername = "azureuser"
$adminPassword = "Pa$$w0rd1234"

# Create a new resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a virtual network and subnet
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix "10.1.0.0/16"
Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix "10.1.0.0/24"
$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet  # Update the VNet object after adding subnet

# Retrieve the updated virtual network object to ensure subnet information is available
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName

# Retrieve the subnet configuration from the updated virtual network object
$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }

# Ensure the subnet is not null
if ($subnet -eq $null) {
    Write-Error "Subnet not found in virtual network."
    exit
} else {
    Write-Host "Subnet ID: $($subnet.Id)"
}

# Create a public IP address with Static allocation method (required for Standard SKU)
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -Name $publicIpName -AllocationMethod Static -Sku Standard

# Create a network security group (NSG) and allow RDP and HTTP traffic
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName

# Allow RDP (3389)
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name "allow_rdp" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 3389 -Access Allow

# Allow HTTP (80)
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name "allow_http" -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 80 -Access Allow

# Apply the rules to the NSG
$nsg.SecurityRules = @($nsgRuleRDP, $nsgRuleHTTP)
$nsg | Set-AzNetworkSecurityGroup

# Create a network interface (NIC)
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id

# Ensure the NIC was created successfully
if ($nic -eq $null) {
    Write-Error "Network interface creation failed."
    exit
} else {
    Write-Host "NIC ID: $($nic.Id)"
}

# Set the VM size
$vmSize = "Standard_B2s"

# Define the OS disk configuration
$osDiskName = "osdisk"
$osDiskConfig = New-AzDiskConfig -Location $location -CreateOption FromImage -DiskSizeGB 256

# Define the Windows Server 2019 image
$imageReference = Get-AzVMImage -Location $location -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest"

# Define the credentials
$credentials = New-Object PSCredential ($adminUsername, (ConvertTo-SecureString $adminPassword -AsPlainText -Force))

# Create the VM configuration and validate each step
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

if ($vmConfig -eq $null) {
    Write-Error "Failed to create VM configuration."
    exit
}

$vmConfig = $vmConfig | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $credentials

if ($vmConfig -eq $null) {
    Write-Error "Failed to set VM operating system."
    exit
}

$vmConfig = $vmConfig | Set-AzVMSourceImage -PublisherName $imageReference.PublisherName -Offer $imageReference.Offer -Skus $imageReference.Skus -Version $imageReference.Version

if ($vmConfig -eq $null) {
    Write-Error "Failed to set VM source image."
    exit
}

$vmConfig = $vmConfig | Add-AzVMNetworkInterface -Id $nic.Id

if ($vmConfig -eq $null) {
    Write-Error "Failed to add network interface to VM configuration."
    exit
}

$vmConfig = $vmConfig | Set-AzVMOSDisk -Name $osDiskName -CreateOption FromImage -ManagedDiskId $osDiskConfig.ManagedDisk.Id -StorageAccountType "Standard_LRS"

if ($vmConfig -eq $null) {
    Write-Error "Failed to set OS disk configuration."
    exit
}

# Create the virtual machine
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

# Create a storage account
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccountName -Location $location -SkuName "Standard_LRS" -Kind "StorageV2"