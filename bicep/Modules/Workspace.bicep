/* Bicep AVD Workspace Module


*/


// Workspace Parameters
@description('Azure Region of where to place the Workspace object')
param WorkspaceLocation string = resourceGroup().location

@description('Name of the Workspace object')
param WorkspaceName string = 'WS01'

@description('A friendly name for the Workspace object')
param WorkspaceFriendlyName string = 'Just Testing'

@description('A description for the Workspace object')
param WorkspaceDescription string = 'This is my first bicep script to create a Workspace! :)'

@description('Resource tags to assign to the Workspace object')
param WorkspaceTags object = {}

@description('An array of Application Group ResourceIDs to associate with the Workspace object')
param WorkspaceApplicationGroupReferences array = []

// Workspace Diagnostic Parameters
@description('Specify if to enable Diagnostic settings on the Workspace object')
param WorkspaceDiagnosticsEnable bool = false

@description('The full Resource ID of the Log Analytics Workspace to send Diagnotic data')
param WorkspaceLogAnalyticsWorkspaceId string = ''


////////////////
// Resources
////////////////

// Workspace - https://learn.microsoft.com/en-us/azure/templates/microsoft.desktopvirtualization/workspaces
resource AvdWorkspace 'Microsoft.DesktopVirtualization/workspaces@2022-10-14-preview' = {
  name: WorkspaceName
  location: WorkspaceLocation
  tags: WorkspaceTags
  properties:{
    friendlyName: WorkspaceFriendlyName
    description: WorkspaceDescription
    applicationGroupReferences: WorkspaceApplicationGroupReferences
  }  
}

// Diagnostic Settings - https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings
resource AvdWorkspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(WorkspaceDiagnosticsEnable) {
  name: 'AvdWorkspaceDiagnostics'
  scope: AvdWorkspace
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
        category : 'Feed'
        categoryGroup : null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }      
    ]
    workspaceId: WorkspaceLogAnalyticsWorkspaceId
    logAnalyticsDestinationType: null
  }
}
