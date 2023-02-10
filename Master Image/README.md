#  Master Images Creation

This folder contains templates for  Master Image VM Creation.

## Usage examples:
New-AzResourceGroupDeployment -TemplateFile .\MasterImageVMTemplate.json -TemplateParameterFile .\VMNAME-parameters.json -ResourceGroupName "RG-AVD-IMAGE-NE"


Once the initial Master Image VMs have been created, the following can be used to snaphost, Sysprep and capture, add captured Managed Image to a Shared Image Gallery and then restore the VMs to the pre sysprep snapshot.

## Create a Snapshot of the VM (this is a pre-sysprep snapshot)
New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-AVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode PreSysprep

## Set VM to be Generalised
Stop-AzVM -Name VMNAME -ResourceGroupName RG-AVD-IMAGE-NE
Set-AzVM -ResourceGroupName RG-AVD-IMAGE-NE -Name VMNAME -Generalized

## Create a Managed Image
New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-WVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode AfterSysprep

## Add the Managed Image to a Shared Image Gallery 
New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-WVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode AddToSIG

## Delete VM
Remove-AzVM -Name VMNAME -ResourceGroupName RG-AVD-IMAGE-NE

## Delete OS Disk
Remove-AzDisk -DiskName VMNAME_OSDisk -ResourceGroupName RG-AVD-IMAGE-NE

## Recreate the VM using the pre-sysprep snapshot
New-AzResourceGroupDeployment -TemplateFile .\CaptureMasterImage.json -TemplateParameterFile .\CaptureMasterImage-WVD-PROD-HP01.parameters.json -ResourceGroupName RG-AVD-IMAGE-NE -ExecutionMode RecreateVM