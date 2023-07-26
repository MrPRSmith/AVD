<#
    .SYNOPSIS
    Check RSS feed with a view to see if a new Cumulative Update has been published for Windows

    .DESCRIPTION
    Script will return TRUE or FALSE if a new Cumulative Update is detected in the RSS feed

    .VERSION

    Written By: Paul Smith
    Script Ver: 1.0.1 (26-07-2023) - Updated to reflect change in RSS feed title text and added support for Windows 11
                1.0.0 (06-07-2021)

#>

[CmdletBinding()]

param(
    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false
    )]
    [String]$Product = "Windows11", # Specify Windows10 or Windows11

    
    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false
    )]
    [String]$OSBuildNumber = "22621", # Windows build number to look for

    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false
    )]
    [ValidateRange(-365, -1)]
    [Int]$Days = -2, # -1 = 1 day ago, -10 = 10 days ago

    [Parameter(
        ValuefromPipelineByPropertyName = $true,
        Mandatory = $false
    )]
    [ValidateSet("TRUE", "FALSE")]
    [string]$Override = $null # Force a TRUE or FALSE return 
)
Write-Host "-----------------------------------------------------------------------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "## START OF SCRIPT:" $MyInvocation.MyCommand.Name " ##" -ForegroundColor White 
Write-Host ""

switch($Product)
{
    "Windows10" {$RssUrl = "https://support.microsoft.com/en-us/feed/rss/6ae59d69-36fc-8e4d-23dd-631d98bf74a9"; break}
    "Windows11" {$RssUrl = "https://support.microsoft.com/en-us/feed/rss/4ec863cc-2ecd-e187-6cb3-b50c6545db92"; break}
}

$Now = Get-Date

# Download RSS feed as XML
[xml]$RssFeed = (New-Object System.Net.WebClient).DownloadString($RssUrl) 
Write-Host "Execution Date: " $Now
Write-Host "XML Feed URL:   " $RssUrl
Write-Host "XML Feed Title: " $RssFeed.rss.channel.title
Write-Host "XML Build Date: " ([datetime]::ParseExact($RssFeed.rss.channel.lastBuildDate.Substring(5,20),"dd MMM yyyy HH:mm:ss",$null))
Write-Host "Total RSS Items:" $RssFeed.rss.channel.Item.Count 

# Select the x most recent items
# $RssItems = $RssFeed.rss.channel.Item | Select-Object -First 10
$filterDate = (Get-Date).AddDays($Days)
Write-Host ""
Write-Host "Searching for entries dated between" $filterDate "and" $Now "(the last" ($Days-$Days-$Days) "day(s)) and a title with text that:"
Write-Host "-> Includes `"OS Build`" and the Windows build number `"$OSBuildNumber`""
Write-Host "-> Does not include: `"Out-of-band`" or `"Preview`""
$RssItems = $RssFeed.rss.channel.Item | where-Object {[datetime]::ParseExact($_.pubDate.Substring(5,20),"dd MMM yyyy HH:mm:ss",$null) -gt $filterDate}
Write-Host "Entries found:" $RssItems.Count

$NewCumulativeUpdate = $False

if ($RssItems.Count -gt 0)
{
    Write-Host ""
    Write-Host "Checking each entry for details of a new Cumulative Update ...."

    foreach ($Item in $RssItems)
    {
            # Convert the items publication date to a DateTime value
            $pubDate = ([datetime]::ParseExact($Item.pubDate.Substring(5,20),"dd MMM yyyy HH:mm:ss",$null))        
    
            if (($Item.title -match "OS Build") -and ($Item.title -match $OSBuildNumber) -and ($Item.title -notmatch "Out-of-band") -and ($Item.title -notmatch "Preview"))
            {           
                Write-Host " -> Selected:" $pubDate " - " $Item.title.trim() -ForegroundColor Green
                $NewCumulativeUpdate = $true
            }
            else {
                Write-Host " -> Skipping:" $pubDate " - " $Item.title.Trim() -ForegroundColor Red
            }
    }    
}

Write-Host ""

if($NewCumulativeUpdate)
{    
    Write-Host "New Cumulative Update(s) are available." -ForegroundColor Green   
}
else
{
    Write-Host "No new Cumulative Update(s) are available." -ForegroundColor Red
}

if($Override -eq "TRUE")
{
    Write-Host ""
    Write-Host "** Override Feature Enabled **" -ForegroundColor Yellow
    Write-Host "Returning a status of `"New Cumulative Update(s) are available`"" -ForegroundColor Green
    Write-Host "##vso[task.setvariable variable=UpdateAvailable;isOutput=true]true"
}
elseif($Override -eq "FALSE")
{
    Write-Host ""
    Write-Host "** Override Feature Enabled **" -ForegroundColor Yellow
    Write-Host "Returning a status of `"No New Cumulative Update(s) are available`"" -ForegroundColor Red
    Write-Host "##vso[task.setvariable variable=UpdateAvailable;isOutput=true]false"
}
else
{
    Write-Host "##vso[task.setvariable variable=UpdateAvailable;isOutput=true]$NewCumulativeUpdate"
}

Write-Host ""
Write-Host "## END OF SCRIPT:" $MyInvocation.MyCommand.Name " ##" -ForegroundColor White 
Write-Host ""
Write-Host "-----------------------------------------------------------------------------------------------------" -ForegroundColor Green