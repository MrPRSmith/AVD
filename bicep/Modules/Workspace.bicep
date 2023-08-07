/* Bicep AVD Workspace Module


*/


// Workspace Parameters
param WorkspaceLocation string = resourceGroup().location
param WorkspaceName string = 'WS01'
param WorkspaceFriendlyName string = 'Just Testing'
param WorkspaceDescription string = 'This is my first bicep script to create a Workspace! :)'
param WorkspaceTags object = {}


////////////////
// Resources
////////////////

// Workspace
resource AVDWorkspace 'Microsoft.DesktopVirtualization/workspaces@2022-10-14-preview' = {
  name: WorkspaceName
  location: WorkspaceLocation
  tags: WorkspaceTags
  properties:{
    friendlyName: WorkspaceFriendlyName
    description: WorkspaceDescription
  }  
}
