<#
    .SYNOPSIS
    Manage Azure Shared Image Gallery Versions

    .DESCRIPTION
    Allows you to control the number of image versions for a specific definition by deleting the oldest

    .VERSION

    Written By: Paul Smith
    Script Ver: 1.0.0 (02-07-2021)
#>

[CmdletBinding()]

param(
    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false)]
    [String]
    $SharedImageGalleryResourceGroup,
    # Resource Group Containing the Shared Image Gallery

    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false)]
    [String]
    $SharedImageGalleryName,
    # Name of the Shared Image Gallery

    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false)]
    [String]
    $SharedImageGalleryDefinitionName,
    # Definition within the Shared Image Gallery

    [Parameter(Mandatory = $false, ValuefromPipelineByPropertyName = $true)]
    [ValidateRange(0,[int]::MaxValue)]    
    [int]
    $ImageVersionsToKeep = [int]::MaxValue
    # The maximum number of image definitions that should be kept in the gallery. Default is no limit (well 2147483647)
)

Write-Host ""
Write-Host "## START OF SCRIPT:" $MyInvocation.MyCommand.Name " ##" -ForegroundColor White 
Write-Host ""
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "Resource Group: " $SharedImageGalleryResourceGroup
Write-Host "Gallery Name:   " $SharedImageGalleryName
Write-Host "Definition Name:" $SharedImageGalleryDefinitionName

$ImageVersions = @()

try {
  $ImageVersions = Get-AzGalleryImageVersion -ResourceGroupName $SharedImageGalleryResourceGroup -GalleryName $SharedImageGalleryName -GalleryImageDefinitionName $SharedImageGalleryDefinitionName | Sort-Object -Property {$_.PublishingProfile.PublishedDate} -Descending
}
catch {
    Write-Host "An error occured whist trying to 'get' the image versions" -ForegroundColor Red
    EXIT 1
}

Write-Host "Image Versions: " $ImageVersions.Count "(Maximum desired versions" $ImageVersionsToKeep")"
foreach($ImageVersion in $ImageVersions)
{
    Write-Host " -> Published Date:" $ImageVersion.PublishingProfile.PublishedDate "- Version Name:" $ImageVersion.Name    
}
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Green
Write-Host ""

# If there are zero image versions
if($ImageVersions.Count -eq 0)
{
    Write-Host "There are no image versions in the specified definition. No action will be taken."
}

# If the number of image versions is greater than the number to maintain
elseif($ImageVersions.Count -gt $ImageVersionsToKeep)
{
    $OldestNumberOfImageVersions = $ImageVersions.Count - $ImageVersionsToKeep
    Write-Host "There are" $OldestNumberOfImageVersions "more version(s) in the gallery for this image definition than is desired. The oldest" $OldestNumberOfImageVersions "version(s) will now be removed."
    $ImageVersionsToDelete = $ImageVersions | Select-Object -Last $OldestNumberOfImageVersions | Sort-Object -Property {$_.PublishingProfile.PublishedDate}

    foreach($ImageVersionToDelete in $ImageVersionsToDelete)
    {
        Write-Host " --> Deleting" $ImageVersionToDelete.PublishingProfile.PublishedDate "-" $ImageVersionToDelete.Name -ForegroundColor Yellow
        Remove-AzGalleryImageVersion -ResourceGroupName $SharedImageGalleryResourceGroup -GalleryName $SharedImageGalleryName -GalleryImageDefinitionName $SharedImageGalleryDefinitionName -Name $ImageVersionToDelete.Name -Force
    }
}

#
else
{
    Write-Host "No maintenance actions required."    
}
Write-Host ""
Write-Host "## END OF SCRIPT:" $MyInvocation.MyCommand.Name " ##" -ForegroundColor White 
Write-Host ""