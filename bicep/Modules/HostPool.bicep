/* Bicep AVD Host Pool Module


*/


// Host Pool Parameters
param HostPoolLocation string = resourceGroup().location
param HostPoolName string = 'HP01'
param HostPoolFriendlyName string = 'Just Testing'
param HostPoolDescription string = 'This is my first bicep script to create a Host Pool! :)'
param HostPoolMaxSessionLimit int = 4
param HostPoolTokenExpirationTime string 

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

param HostPoolTags object = {}


////////////////
// Resources
////////////////

// Host Pool
resource AVDHostPool 'Microsoft.DesktopVirtualization/hostPools@2022-10-14-preview' = {
  name: HostPoolName
  location: HostPoolLocation
  tags: HostPoolTags
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
      expirationTime: HostPoolTokenExpirationTime
    }
  }
}

////////////////
// Outputs
////////////////

// output HostPoolRegistrationToken string = AVDHostPool.properties.registrationInfo.token
output HostPoolRegistrationToken string = reference(AVDHostPool.id, '2021-01-14-preview').registrationInfo.token
output HostPoolRegistrationTokenExpirationTime string = HostPoolTokenExpirationTime
output HostPoolId string = AVDHostPool.id

// https://github.com/Azure/bicep/issues/6105
// https://lrottach.hashnode.dev/avd-working-with-registration-tokens
