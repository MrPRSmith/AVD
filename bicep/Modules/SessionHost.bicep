/* Bicep AVD Session Host Deployment Module

Currently supports:
 - Using the Azure Market Place, a Compute Gallery or a Managed Image as a Session Host image source 
 - Active Directory (AADS) or Azure Active Directory (AAD) Joined
 - Intune MDM enrolment when Session Hosts are AAD Joined
 - Choice of using Availability Zones or Availability Sets (for Host Pools with 200 or less VMs)
 - Automatic shutdown of Session Hosts via DevTestLab
 - Session Hosts based on Trusted Launch VMs 

 Needs Testing:
 - Custom Script execution - e.g. install SCCM agent, other tooling or app etc.

To be added:
 - Azure Disk Encryption (BitLocker)
 - Diagnostics / Monitoring
 - Boot Diagnostics

*/

// Global Parameters
@description('Location from where to obtain the  AVD artificats')
param AvdArtifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

@description('Specify the Time Zone for the Session Host(s)')
param TimeZone string = 'GMT Standard Time'

// Session Host Parameters
@description('Resource Group of where to place the Session Host(s)')
param SessionHostLocation string = resourceGroup().location

@description('Session Host name prefix. e.g. AVD-HOST-')
param SessionHostNamePrefix string = 'AVD-HOST-'

@description('The number of Session Host(s) to deploy')
param SessionHostCount int = 1

@description('Initial Session Host number to start from. e,g. 23 = AVD-HOST-23')
param SessionHostInitialNumber int = 201

@description('VM size of the Session Host. e.g. Standard_B2ms')
param SessionHostVmSize string = 'Standard_B2ms'

@description('Pad the session host instance number to be the specified number of characters wide e.g. 3 = 001 (AVD-HOST-001) or 2 = 01 (AVD-HOST-01)')
param SessionHostNumberPadding int = 2 //length(string(SessionHostInitialNumber))

@description('Name suffix for Session Host OS Disk name. e.g. -OsDisk (AVDHOST001-OsDisk)')
param SessionHostOsDiskNameSuffix string = '-OsDisk'

@description('Session Host OS Disk size in GB. e.g. 128')
param SessionHostOsDiskSizeGb int = 128

@description('Specify if to use an Azure Marketplace image or an Azure Compute Gallery image for the Session Host(s)')
@allowed([
  'AzureMarketplace'
  'AzureComputeGallery'
])
param SessionHostImageType string = 'AzureMarketplace'

@description('Required if SessionHostImageType is AzureMarketplace. Specifies the Azure Marketplace image Publisher. e.g. MicrosoftWindowsDesktop, MicrosoftWindowsServer')
param SessionHostImageReferencePublisher string ='MicrosoftWindowsDesktop'

@description('Required if SessionHostImageType is AzureMarketplace. Specifies the Azure Marketplace image Offer. e.g. WindowsServer, office-365, windows-10, windows-11')
param SessionHostImageReferenceOffer string ='office-365'

@description('Required if SessionHostImageType is AzureMarketplace. Specifies the Azure Marketplace image SKU. e.g. win11-22h2-avd-m365, 2022-datacenter-g2, win10-22h2-ent-g2 etc.')
param SessionHostImageReferenceSku string ='win11-22h2-avd-m365'

@description('Required if SessionHostImageType is AzureMarketplace. Specifies the Azure Marketplace image Version')
param SessionHostImageReferenceVersion string ='latest'

@description('Required if SessionHostImageType is AzureComputeGallery. Specifies the Azure Compute Gallery ID or Managed Image ID')
param SessionHostImageId string = ''

@description('Specifies the type of Azure Hybrid licensing that will be applied to the Operating System')
@allowed( [
  'Windows_Server'
  'Windows_Client'
])
param SessionHostLicenseType string = 'Windows_Client'

@description('Specifies if to enable Trusted Launch on the Session Host VM object. A supported OS image must be used if enabled')
param SessionHostTrustedLaunchEnabled bool = true

@description('FQDN for AD DS domain to join. e.g. corp.contoso.com')
param SessionHostDomainToJoin string = ''

@description('Distinguished name of the OU (Organisational Unit) path into which to place the Computer account. Leave blank for default OU placement')
param SessionHostDomainToJoinOuPath string = ''

@description('Bit flag that defines the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx')
param SessionHostDomainToJoinOptions int = 3

@description('Username in UPN format of the account with permission to perform the Domain Join. e.g. DomJoin@corp.contoso.com')
@secure()
param SessionHostDomainJoinUsername string = ''

@description('Password for the account with permission to perform the Domain Join')
@secure()
param SessionHostDomainJoinPassword string = ''

@description('Session Host Join Type. e.g. WindowsAD (AD DS) or AzureAD (AADJ)')
@allowed([
  'WindowsAD'
  'AzureAD'
])
param SessionHostJoinType string = 'AzureAD'

@description('Specify if to enrol the Session Host into Intune for MDM management. The Session Host must be AzureAD joined and a supported Operating System')
param SessionHostIntuneEnrol bool = false

@description('Disk storage account type for the OS disk of the Session Host(s)')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_LRS'
  'UltraSSD_LRS'
  'PremiumV2_LRS'
  'StandardSSD_LRS'
  'StandardSSD_ZRS'
])
param SessionHostOsDiskStorageAccountType string = 'StandardSSD_LRS'

@description('Specify if to include the deletion of the OS disk when the Session Host VM object is deleted')
param SessionHostOsDiskDeleteWithSessionHost bool = false

@description('Specify the Session Host(s) availability configuration to use. None, Availability Set or Availability Zone')
@allowed([
  'None'
  'Set'
  'Zone'  
])
param SessionHostAvailabilityConfiguration string = 'None'

@description('Specify the Tags to assign to the Session Host. This will be applied to VM, NIC and Disk objects')
param SessionHostTags object = {}

//Host Pool Parameters
@description('The AVD Host Pool name against which the Session Host(s) will be registered')
param HostPoolName string

@description('The AVD Registration Token to be used to register the Session Host(s) with the specified Host Pool')
param HostPoolRegistrationToken string

// Availability Zone Parameters
@description('Specify the Availability Zone allocation method. Manual = Session Host(s) are all assigned to the same Zone. Automatic = Session Host(s) are distruted across all the available zones')
@allowed([
  'Manual'
  'Automatic'
])
param AvailabilityZoneAllocationType string = 'Automatic'

@description('The number of Availability Zones available in the Azure Region that the Session Host(s) are being deployed')
param AvailabilityZoneCount int = 3

@description('Specify the Availability Zones to assign all Session Host(s) when using Manual assignment')
param AvailabilityZoneManuallyAssigned int = 1

// Local VM Account and Credentials
@description('Username for the built-in local administrator account. e.g. VmAdmin')
@secure()
param adminUsername string

@description('Password for the built-in local administrator account')
@secure()
param adminPassword string

// Network Interface Parameters
@description('Resource Group of where to place the NIC')
param NicLocation string = resourceGroup().location

@description('The prefix to use for the name of the NIC. Defaults to matching the Session Host prefix. e.g. AVD-HOST-')
param NicNamePrefix string = SessionHostNamePrefix

@description('The suffix to append to the end of NIC name. e.g. AVD-HOST-345-NIC-01')
param NicNameSuffix string = '-NIC-01'

@description('Enable accelerated networking if supported by selected VM')
param NicEnableAcceleratedNetworking bool = false

@description('Specify if to include the deletion of the NIC when the VM object is deleted')
param NicDeleteWithSessionHost bool = false

// Virtual Network Parameters
@description('Name of the vNet to use')
param VnetName string

@description('Name of the Resource Group containing the vNet')
param VnetRG string

@description('Name of the Subnet within the vNet that Session Host(s) are to use')
param SubnetName string

// Availability Set Parameters
@description('The name of the Availability Set')
param AvailabilitySetName string = 'AS-AVDHOSTS-01'

@description('Resource Group of where to place the Availability Set')
param AvailabilitySetLocation string = resourceGroup().location

// Autoshutdown Parameters
@description('Choose to configure an automatic shutdown time')
param AutoShutdownEnable bool = true

@description('Specify the Time Zone for the specified shutdown time')
param AutoShutdownTimeZone string = TimeZone

@description('Time in 24hr format of when the Session Host(s) should shutdown. e.g. choose 21:00 for 9pm')
param AutoShutdownTime string = '21:00'

// Custom Script Parameters
@description('Choose to enable the execution of a Custom Script')
param CustomScriptEnable bool = false

@description('The entry point script to run')
param CustomScriptCommandToExecute string = ''

@description('An array of URLs for dwonloading the required files for the Custom Script')
param CustomScriptFileUris array = [
  ''
]

@description('The name of the storage account from where to access the Custom Script')
param CustomScriptStorageAccountName string = ''

@description('The key with which to access the specified storage account')
@secure()
param CustomScriptStorageAccountKey string = ''

@description('The managed identity to use for downloading files. Valid values are {}, {"clientId" : "string"} which is the client ID of the managed identity, or {"objectId" : "string"}, which is the object ID of the managed identity')
param CustomScriptManagedIdentity string = '{}'

@description('The Custom Script Time Stamp. Change this value to trigger a rerun of the script. Any integer value is acceptable, as long as it is different from the previous value')
param CustomScriptTimestamp int = 0


////////////////
// Variables
////////////////

// Configure Session Host Join Type
var SessionHostWindowsADJoin = contains(SessionHostJoinType, 'WindowsAD') // Sets as true or false - AD DS Domain Join
var SessionHostAzureADJoin = contains(SessionHostJoinType, 'AzureAD')     // Sets as true or false - AAD Join
var SessionHostIdentity = SessionHostAzureADJoin ? 'SystemAssigned' : 'None'     // Bool ? 'value if true' : value if false''

// Configure Availability
var UseAvailabilitySet = contains(SessionHostAvailabilityConfiguration, 'Set')   // Sets as true or false - Use Availability Set
var UseAvailabilityZone = contains(SessionHostAvailabilityConfiguration, 'Zone')   // Sets as true or false - Use Availability Zones
// Either assign Session Hosts to the same Availability Zone manually or distribute across all available zones automatically
var AssignAvailabilityZoneAutomatic = contains(AvailabilityZoneAllocationType, 'Automatic') 

// Either use an Azure Marketplace image or an Azure Compute Gallery image
var SessionHostAzureMarketplaceImage = {
  publisher: SessionHostImageReferencePublisher
  offer: SessionHostImageReferenceOffer
  sku: SessionHostImageReferenceSku
  version: SessionHostImageReferenceVersion
}
var SessionHostAzureComputeGalleryImage = {
  id: SessionHostImageId
}
var SessionHostImageReference = contains(SessionHostImageType,'AzureMarketplace') ? SessionHostAzureMarketplaceImage : SessionHostAzureComputeGalleryImage

// Configuration for Trusted Launch (if enabled)
var TrustedLaunchEnabled = {
  securityType:'TrustedLaunch'
  uefiSettings:{
    secureBootEnabled:true
    vTpmEnabled:true
  }
} 
var TrustedLaunchDisabled = {}


////////////////
// Resources
////////////////

// Existing Resource - Virtual Network
resource ExistingVnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: VnetName
  scope: resourceGroup(VnetRG)
}

// Existing Resource - Subnet
resource ExistingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: ExistingVnet
  name: SubnetName
}

// Availability Set - I will need to re-work this logic if there are more than 200 Session Hosts!
resource AvailabilitySet 'Microsoft.Compute/availabilitySets@2023-03-01' = if(UseAvailabilitySet) {
  name: AvailabilitySetName
  location: AvailabilitySetLocation 
  properties:{
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  sku: {
    name: 'Aligned'
  }
}

// Network Interface(s)
resource Nic 'Microsoft.Network/networkInterfaces@2023-02-01' = [for SessionHostInstance in range(0,SessionHostCount): {
  name: '${NicNamePrefix}${padLeft(SessionHostInstance + SessionHostInitialNumber ,SessionHostNumberPadding,'0')}${NicNameSuffix}'
  location: NicLocation
  tags: SessionHostTags
  properties: {
    ipConfigurations:[
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: ExistingSubnet.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: NicEnableAcceleratedNetworking
  }
}]

// Session Host(s) - https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines
resource SessionHosts 'Microsoft.Compute/virtualMachines@2023-03-01' = [for SessionHostInstance in range(0,SessionHostCount): {
  name: '${SessionHostNamePrefix}${padLeft(SessionHostInstance + SessionHostInitialNumber, SessionHostNumberPadding,'0')}'
  location: SessionHostLocation
  tags: SessionHostTags
  identity:{
    type: SessionHostIdentity
  }
  properties:{
    hardwareProfile:{
      vmSize: SessionHostVmSize
    }
    availabilitySet: UseAvailabilitySet ? AvailabilitySet.id : null
    osProfile:{
      computerName: '${SessionHostNamePrefix}${padLeft(SessionHostInstance + SessionHostInitialNumber, SessionHostNumberPadding,'0')}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        timeZone: TimeZone
      }
    }
    storageProfile: {
      imageReference: SessionHostImageReference
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: SessionHostOsDiskStorageAccountType
        }
        name: '${SessionHostNamePrefix}${padLeft(SessionHostInstance + SessionHostInitialNumber, SessionHostNumberPadding,'0')}${SessionHostOsDiskNameSuffix}'
        diskSizeGB: SessionHostOsDiskSizeGb
        deleteOption: SessionHostOsDiskDeleteWithSessionHost ? 'Delete' : 'Detach'
      }
    } 
    securityProfile: SessionHostTrustedLaunchEnabled ? TrustedLaunchEnabled : TrustedLaunchDisabled
    networkProfile:{
      networkInterfaces:[
        {
          id: Nic[SessionHostInstance].id 
          properties: {
            deleteOption: NicDeleteWithSessionHost ? 'Delete' : 'Detach'
          }
        }
      ]
    }
    licenseType: SessionHostLicenseType 
  }
  // https://github.com/Azure/bicep/discussions/8018#discussioncomment-3445010
  // AssignAvailabilityZoneAutomatic ? string(SessionHostInstance % AvailabilityZoneCount + 1) : string(AvailabilityZoneManuallyAssigned)
  zones: (UseAvailabilityZone ? (AssignAvailabilityZoneAutomatic ? array(string((SessionHostInstance % AvailabilityZoneCount + 1))) : string(AvailabilityZoneManuallyAssigned)) : null)
  dependsOn:[
    Nic[SessionHostInstance]
  ]
}]

// Windows Server AD DS Domain Join
resource DomainJoin 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for SessionHostInstance in range(0,SessionHostCount): if(SessionHostWindowsADJoin) {
  parent: SessionHosts[SessionHostInstance]
  name: 'DomainJoin'
  location: SessionHostLocation
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: SessionHostDomainToJoin
      ouPath: SessionHostDomainToJoinOuPath
      user: SessionHostDomainJoinUsername
      restart: true
      options: SessionHostDomainToJoinOptions
    }
    protectedSettings: {
      Password: SessionHostDomainJoinPassword
    }
  }
}]

// Azure AD (Entra) Join - Cloud Native with or without Intune enrollment
resource AzureADJoin 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for SessionHostInstance in range(0,SessionHostCount): if(SessionHostAzureADJoin) {
  parent: SessionHosts[SessionHostInstance] 
  name: 'AzureADJoin'
  location: SessionHostLocation
  properties:{
    publisher: 'Microsoft.Azure.ActiveDirectory' 
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: SessionHostIntuneEnrol ? '0000000a-0000-0000-c000-000000000000' : null // Intune AppID
    }
  }
}]

// Register Session Host with AVD - https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-windows
resource AzureVirtualDesktopRegistration 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for SessionHostInstance in range(0,SessionHostCount): {
  parent: SessionHosts[SessionHostInstance]
  name: 'AVDRegistration'
  location: SessionHostLocation
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: AvdArtifactsLocation
        script: 'Configuration.ps1'
        function: 'AddSessionHost'
      }
      configurationArguments: {
        hostPoolName: HostPoolName
        registrationInfoToken: HostPoolRegistrationToken
      }
    }
  }
  dependsOn:[
    AzureADJoin[SessionHostInstance]
    DomainJoin[SessionHostInstance]
  ]
}]

// Enable Auto Shutdown - https://learn.microsoft.com/en-us/azure/templates/microsoft.devtestlab/schedules
resource Autoshutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = [for SessionHostInstance in range(0, SessionHostCount): if (AutoShutdownEnable) {  
  name: 'Shutdown-ComputeVm-${SessionHosts[SessionHostInstance].name}'
  location: SessionHostLocation
  properties:{
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence:{
      time: AutoShutdownTime
    }
    timeZoneId: AutoShutdownTimeZone
    notificationSettings: {
      status: 'Disabled'
    }
    targetResourceId: SessionHosts[SessionHostInstance].id
   }
   dependsOn:[
    SessionHosts[SessionHostInstance]
   ]
}]

// Enable Custom Script - https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows
resource CustomScript 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for SessionHostInstance in range(0, SessionHostCount): if (CustomScriptEnable) {
  parent: SessionHosts[SessionHostInstance]
  name: 'CustomScriptExtension'
  location: SessionHostLocation
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: CustomScriptTimestamp
    }
    protectedSettings: {
      commandToExecute: CustomScriptCommandToExecute
      fileUris: CustomScriptFileUris
      storageAccountName: CustomScriptStorageAccountName
      storageAccountKey: CustomScriptStorageAccountKey
      managedIdentity: CustomScriptManagedIdentity
    }
  }
}]
