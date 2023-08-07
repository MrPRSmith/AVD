// Global Parameters
param DateTimeNow string = utcNow('u')
param AvdArtifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

// Key Vault Parameters
param KvName string = 'KV-GEN-WE' // Main KV for username and passwords etc.
param KvRG string = 'RG-CORE-SVC-WE'
param KvLocation string = resourceGroup().location
param KvSubId string = subscription().id
param KvBitLockerName string = 'KV-GEN-WE' // KV for storing BitLocker recovery keys
param KvBitLockerRG string = 'RG-CORE-SVC-WE'
param KvBitLockerLocation string = resourceGroup().location
param KvBitLockerSubId string = subscription().id

// Workspace Parameters
param WorkspaceLocation string = resourceGroup().location
param WorkspaceName string = 'WS1'
param WorkspaceFriendlyName string = 'Just Testing'
param WorkspaceDescription string = 'This is my first bicep script to create a Workspace! :)'

// Host Pool Parameters
param HostPoolLocation string = resourceGroup().location
param HostPoolName string = 'HP01'
param HostPoolFriendlyName string = 'Just Testing'
param HostPoolDescription string = 'This is my first bicep script to create a Host Pool! :)'
param HostPoolMaxSessionLimit int = 4
var HostPoolTokenExpiry = dateTimeAdd(DateTimeNow, 'PT6H') // 6 hours from now

@allowed([
  'Pooled'
  'Personal'
])
param HostPoolType string = 'Pooled'

@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param HostPoolLoadBalancerType string = 'BreadthFirst'

@allowed([
  'Desktop'
  'RailApplications'
])
param HostPoolLoadAppGroupType string = 'Desktop'

// Session Host Parameters
param SessionHostLocation string = resourceGroup().location
param SessionHostNamePrefix string = 'AZVM'
param SessionHostCount int = 0
param SessionHostVmSize string = 'Standard_B2ms'

// Key Vaults
resource KeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: KvName
  scope: resourceGroup(KvSubId,KvRG)
}

resource KeyVaultBitLocker 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: KvBitLockerLocation
  scope: resourceGroup(KvBitLockerSubId,KvBitLockerRG)
}

// Workspace
resource AVDWorkspace 'Microsoft.DesktopVirtualization/workspaces@2022-10-14-preview' = {
  name: WorkspaceName
  location: WorkspaceLocation
  properties:{
    friendlyName: WorkspaceFriendlyName
    description: WorkspaceDescription
  }  
}

// Host Pool
resource AVDHostPool 'Microsoft.DesktopVirtualization/hostPools@2022-10-14-preview' = {
  name: HostPoolName
  location: HostPoolLocation
  properties: {
    hostPoolType: HostPoolType
    loadBalancerType: HostPoolLoadBalancerType
    preferredAppGroupType: HostPoolLoadAppGroupType
    description: HostPoolDescription
    friendlyName: HostPoolFriendlyName
    maxSessionLimit: HostPoolMaxSessionLimit
    validationEnvironment: false
    startVMOnConnect: false
    registrationInfo: {
      registrationTokenOperation: 'Update'
      expirationTime: HostPoolTokenExpiry
    }
  }
}

// https://github.com/Azure/bicep/issues/6105
// https://lrottach.hashnode.dev/avd-working-with-registration-tokens
// output RegistrationToken string = AVDHostPool.properties.registrationInfo.token
output RegistrationToken string = reference(AVDHostPool.id, '2021-01-14-preview').registrationInfo.token
output HostPoolTokenExpiry string = HostPoolTokenExpiry



module SessionHost 'SessionHost.bicep' = {
  name: 'DeploySessionHost'
  params: {
    SessionHostLocation: SessionHostLocation
    SessionHostNamePrefix: SessionHostNamePrefix
    SessionHostCount: SessionHostCount
    SessionHostVmSize: SessionHostVmSize
    adminPassword: KeyVault.getSecret('AzVmLocalUserName')
    adminUsername: KeyVault.getSecret('AzVmLocalUserPassword')
    NicLocation: SessionHostLocation
    AvailabilitySetLocation: SessionHostLocation
  }
}
