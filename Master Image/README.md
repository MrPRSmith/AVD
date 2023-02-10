#  Master Images Creation

This folder contains templates for  Master Image VM Creation.

## Usage examples:
`New-AzResourceGroupDeployment -TemplateFile .\MasterImageVMTemplate.json -TemplateParameterFile .\VMNAME-parameters.json -ResourceGroupName "RG-AVD-IMAGE-NE"` 


Once the initial Master Image VMs have been created, the following can be used to snaphost, Sysprep and capture, add captured Managed Image to a Shared Image Gallery and then restore the VMs to the pre sysprep snapshot.

## Create a Snapshot of the VM (this is a pre-sysprep snapshot)
`New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-AVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode PreSysprep` 

## Set VM to be Generalised
`Stop-AzVM -Name VMNAME -ResourceGroupName RG-AVD-IMAGE-NE` 
`Set-AzVM -ResourceGroupName RG-AVD-IMAGE-NE -Name VMNAME -Generalized` 

## Create a Managed Image
`New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-WVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode AfterSysprep` 

## Add the Managed Image to a Shared Image Gallery 
`New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-WVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode AddToSIG` 

## Delete VM
`Remove-AzVM -Name VMNAME -ResourceGroupName RG-AVD-IMAGE-NE` 

## Delete OS Disk
`Remove-AzDisk -DiskName VMNAME_OSDisk -ResourceGroupName RG-AVD-IMAGE-NE` 

## Recreate the VM using the pre-sysprep snapshot
`New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-WVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode RecreateVM` 

# Azure Marketplace Image SKUs

The following are useful AVD image SKUs:

## Windows 11
- win11-21h2-avd
- win11-21h2-ent
- win11-22h2-avd
- win11-22h2-ent

## Windows 10
- 19h1-ent
- 19h1-ent-gensecond
- 19h1-evd
- 19h2-ent
- 19h2-ent-g2
- 19h2-evd
- 19h2-evd-g2
- 20h1-ent
- 20h1-ent-g2
- 20h1-evd
- 20h1-evd-g2
- 20h2-ent
- 20h2-ent-g2
- 20h2-evd
- 20h2-evd-g2
- win10-21h2-avd
- win10-21h2-avd-g2
- win10-21h2-ent
- win10-21h2-ent-g2
- win10-22h2-avd
- win10-22h2-avd-g2
- win10-22h2-ent
- win10-22h2-ent-g2

## Server OS

- 2012-R2-Datacenter
- 2012-r2-datacenter-gensecond
- 2016-Datacenter
- 2016-datacenter-gensecond
- 2019-Datacenter
- 2019-datacenter-core-g2
- 2022-datacenter
- 2022-datacenter-g2

## Identifying SKUs
The following example PowerShell can identify the SKUs

$locName="North Europe"
$pubName="MicrosoftWindowsDesktop"
$offerName="windows-11"
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName | Select Skus