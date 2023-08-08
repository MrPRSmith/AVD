/* Bicep AVD Host Pool Module

Currently supports:
 - 

Needs Testing:
 - 

To be added:
 - Scaling Plan
 - Private endopoint

*/


// Host Pool Parameters
@description('Azure Region of where to place the Host Pool object')
param HostPoolLocation string = resourceGroup().location

@description('Name of the Host Pool object')
param HostPoolName string = 'HP01'

@description('A friendly name for the Host Pool object')
param HostPoolFriendlyName string = 'Just Testing'

@description('A description for the Host Pool object')
param HostPoolDescription string = 'This is my first bicep script to create a Host Pool! :)'

@description('The maximum number of concurrent user sessions allowed on each Session Host within the Host Pool')
param HostPoolMaxSessionLimit int = 4

@description('The date and time for when the Host Pool registration token should expire. e.g. dateTimeAdd(utcNow(\'u\'), \'PT6H\') for 6 hours from \'now\'')
param HostPoolTokenExpirationTime string 

@description('The type of Host Pool - \'Personal\' or \'Pooled\'')
@allowed([
  'Pooled'
  'Personal'
])
param HostPoolType string = 'Pooled'

@description('Host Pool load balancing algorithm. \'BreadthFirst\' load balancing distributes new user sessions across all available session hosts in the Host Pool. \'DepthFirst\' load balancing distributes new user sessions to an available Session Host with the highest number of connections but has not reached its maximum session limit threshold.')
@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param HostPoolLoadBalancerType string = 'BreadthFirst'

@description('Set the the preferred App Group type for this Host Pool. If an end user has both RemoteApp (\'RailApplications\') and Desktop apps published to them on this Host Pool they will only see the selected App type in their feed')
@allowed([
  'Desktop'
  'RailApplications'
])
param HostPoolLoadAppGroupType string = 'Desktop'

@description('Resource tags to assign to the Host Pool object')
param HostPoolTags object = {}

@description('Specify if the Host Pool is a \'validation\' Host Pool')
param HostPoolIsValidationEnvironment bool = false

@description('Specify if VMs in the Host Pool should \'Start On Connect\' or not')
param HostPoolStartVmOnConnect bool = false

@description('Specify a Custom RDP propertly configuration')
param HostPoolCustomRdpProperty string = ''

// Host Pool Diagnostic Parameters
@description('Specify if to enable Diagnostic settings on the Host Pool object')
param HostPoolDiagnosticsEnable bool = false

@description('The full Resource ID of the Log Analytics Workspace to send Diagnotic data')
param HostPoolLogAnalyticsWorkspaceId string = ''


////////////////
// Resources
////////////////


// Host Pool - https://learn.microsoft.com/en-us/azure/templates/microsoft.desktopvirtualization/hostpools
resource AvdHostPool 'Microsoft.DesktopVirtualization/hostPools@2022-10-14-preview' = {
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
    validationEnvironment: HostPoolIsValidationEnvironment
    startVMOnConnect: HostPoolStartVmOnConnect
    registrationInfo: {
      registrationTokenOperation: 'Update'
      expirationTime: HostPoolTokenExpirationTime
    }
    customRdpProperty: HostPoolCustomRdpProperty
  }
}

// Diagnostic Settings - https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource AvdHostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(HostPoolDiagnosticsEnable) {
  name: 'AvdHostPoolDiagnostics'
  scope: AvdHostPool
  properties:{
    logs:[
      /*
      {
        category : null
        categoryGroup : 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      } 
      */        
      {
        category : 'Checkpoint'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        category : 'Error'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }      
      {
        category : 'Management'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }      
      {
        category : 'Connection'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }      
      {
        category : 'HostRegistration'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }  
      {
        category : 'AgentHealthStatus'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }                
      {
        category : 'NetworkData'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }        
      {
        category : 'SessionHostManagement'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }        
    ]
    workspaceId: HostPoolLogAnalyticsWorkspaceId
    logAnalyticsDestinationType: null
  }
}


////////////////
// Outputs
////////////////


// output HostPoolRegistrationToken string = AVDHostPool.properties.registrationInfo.token
output HostPoolRegistrationToken string = reference(AvdHostPool.id, '2021-01-14-preview').registrationInfo.token
output HostPoolRegistrationTokenExpirationTime string = HostPoolTokenExpirationTime
output HostPoolId string = AvdHostPool.id

// https://github.com/Azure/bicep/issues/6105
// https://lrottach.hashnode.dev/avd-working-with-registration-tokens
