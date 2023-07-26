<#
    .SYNOPSIS
    Manage Azure Image Builder Templates

    .DESCRIPTION
    Script allow you to
    
    1. Delete an existing Azure Image Builder Template
    2. Execute (the build) of an existing Azure Image Builder Template

    .VERSION

    Written By: Paul Smith
    Script Ver: 1.0.0 (01-07-2021)
#>

[CmdletBinding()]

param(
    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        ValuefromPipeline = $true,
        Mandatory = $false
    )]
    [ValidateSet("Delete", "Execute")]
    [String]$Action,

    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false
    )]
    [String]$AzureImageBuilderTemplateName,

    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false
    )]
    [String]$AzureImageBuilderTemplateResourceGroup
)

function Load-Module ($m) {

    # If module is imported say that and do nothing
    if (Get-Module | Where-Object {$_.Name -eq $m}) {
        write-host "Module $m is already imported."
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
            Import-Module $m -Verbose
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                Import-Module $m -Verbose
            }
            else {

                # If module is not imported, not available and not in online gallery then abort
                write-host "Module $m not imported, not available and not in online gallery, exiting."
                EXIT 1
            }
        }
    }

}

Write-Host ""
Write-Host "## START OF SCRIPT:" $MyInvocation.MyCommand.Name " ##" -ForegroundColor White 
Write-Host ""
Write-Host "---------------------------------------------------------" -ForegroundColor Green
Write-Host "Script Action:  $Action"
Write-Host "Template Name:  $AzureImageBuilderTemplateName"
Write-Host "Resource Group: $AzureImageBuilderTemplateResourceGroup"
Write-Host "---------------------------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Loading Module: Az.ImageBuilder" -ForegroundColor Blue
Load-Module Az.ImageBuilder

if($Action -eq "Delete")
{
    Write-Host "Removing Azure Image Builder Template $AzureImageBuilderTemplateName from Resource Group $AzureImageBuilderTemplateResourceGroup"
    Remove-AzImageBuilderTemplate -ImageTemplateName $AzureImageBuilderTemplateName -ResourceGroupName $AzureImageBuilderTemplateResourceGroup
}

if($Action -eq "Execute")
{
    Write-Host "Executing the build of Template $AzureImageBuilderTemplateName from Resource Group $AzureImageBuilderTemplateResourceGroup"
    Start-AzImageBuilderTemplate -ImageTemplateName $AzureImageBuilderTemplateName -ResourceGroupName $AzureImageBuilderTemplateResourceGroup -NoWait
}

Write-Host ""
Write-Host "## END OF SCRIPT:" $MyInvocation.MyCommand.Name " ##" -ForegroundColor White 
Write-Host ""