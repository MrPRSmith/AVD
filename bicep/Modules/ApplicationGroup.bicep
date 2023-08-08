/* Bicep AVD Application Group Module


*/

@description('Name of the Application Group object')
param ApplicationGroupName string

@description('Azure Region of where to place the Application Group object')
param ApplicationGroupLocation string

@description('Application Group tags')
param ApplicationGroupTags object = {}

@description('Resource type of the Application Group. Desktop or RemoteApp')
@allowed([
  'Desktop'
  'RemoteApp'
])
param ApplicationGroupType string = 'Desktop'

@description('Friendly name for the Application Group')
param ApplicationGroupFriendlyName string

@description('Description for thee Application Group')
param ApplicationGroupFriendlyDescription string

@description('ResourceId for the Host Pool to which the Application Group will be asssociated')
param HostPoolId string

// Application Group Diagnostic Parameters
@description('Specify if to enable Diagnostic settings on the Host Pool object')
param AppGroupDiagnosticsEnable bool = false

@description('The full Resource ID of the Log Analytics Workspace to send Diagnotic data')
param AppGroupLogAnalyticsWorkspaceId string = ''


////////////////
// Resources
////////////////


// Application Groups https://learn.microsoft.com/en-us/azure/templates/microsoft.desktopvirtualization/applicationgroups
resource ApplicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2022-10-14-preview' = {
  name: ApplicationGroupName
  location: ApplicationGroupLocation
  tags: ApplicationGroupTags
  properties: {
    applicationGroupType: ApplicationGroupType
    hostPoolArmPath: HostPoolId
    friendlyName: ApplicationGroupFriendlyName
    description: ApplicationGroupFriendlyDescription
  }
}

// Diagnostic Settings - https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource AvdAppGroupDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(AppGroupDiagnosticsEnable) {
  name: 'AvdAppGroupDiagnostics'
  scope: ApplicationGroup
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
    ]
    workspaceId: AppGroupLogAnalyticsWorkspaceId
    logAnalyticsDestinationType: null
  }
}


////////////////
// Outputs
////////////////

output ApplicationGroupResourceId array = array(ApplicationGroup.id)
