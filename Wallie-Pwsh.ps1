<#
MIT License

Copyright (c) 2020 dbrennand

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

.SYNOPSIS
    Wallie-Pwsh updates your desktop wallpaper.

.DESCRIPTION
    Wallie-Pwsh updates your desktop wallpaper using the Unsplash API.

.PARAMETER Topics
    If supplied, Wallie-Pwsh will select a user provided topic at random and use this to query an image from the Unsplash API.
    Wallie-Pwsh will then select a result from the Unsplash API at random.

.PARAMETER AccessKey
    A base64 encoded access key used to authenticate with the Unsplash API.

.EXAMPLE
    .\Wallie-Pwsh.ps1 -Topics "Fish","Space","Trains","Jets" `
        -AccessKey "MwAxADgANQAxADIAYQA3AGEAMwBkAGsANABkAGsANQBlADkAOAAwADYAMwA2ADQAMgBmAHYAZAA2ADMANgA5AHMAZABkADkANAA4ADMANwA0AGUAYQAxADYAMQBmAGMAZgAyAG4AZAA3AHkAawA2ADAAYgA1AHYAOQAxAGUAOQA=" -Verbose

.EXAMPLE
    .\Wallie-Pwsh.ps1 -AccessKey "MwAxADgANQAxADIAYQA3AGEAMwBkAGsANABkAGsANQBlADkAOAAwADYAMwA2ADQAMgBmAHYAZAA2ADMANgA5AHMAZABkADkANAA4ADMANwA0AGUAYQAxADYAMQBmAGMAZgAyAG4AZAA3AHkAawA2ADAAYgA1AHYAOQAxAGUAOQA=" -Verbose

.NOTES
    Ensure you provide the AccessKey parameter as a base64 encoded string. Sadly, security through obscurity.
    If you know a better way of handling this, feel free to submit a PR :-)
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [Array]
    $Topics,

    [Parameter(Mandatory = $true)]
    [String]
    $AccessKey
)

$Version = "0.0.2"

# Decode base64 encoded AccessKey parameter
try {
    Write-Verbose -Message "Attempting to decode base64 encoded access key."
    $AccessKey = [System.Text.Encoding]::UNICODE.GetString([System.Convert]::FromBase64String($AccessKey))
}
catch {
    throw "Failed to decode base64 encoded access key."
}

# Declare Unsplash API random endpoint
$UnsplashApiRandomEndpoint = "https://api.unsplash.com/photos/random"
# Declare Unsplash API request headers hashtable
$RequestHeaders = @{ "Authorization" = "Client-ID $($AccessKey)"; "Accept-Version" = "v1" }

Write-Output -InputObject "Obtaining random images from the Unsplash API."

if ($Topics) {
    # Topics parameter has been provided
    # Select a user provided topic from the array at random, query for images from the Unplash API using chosen topic
    Write-Verbose -Message "Attempting to select a topic at random from provided topics ""$($Topics)""."
    $Topic = $Topics[(Get-Random -Maximum ($Topics).Count)]
    Write-Verbose -Message "Chosen topic is ""$($Topic)""."
    try {
        Write-Verbose -Message "Attempting to make a web request to the Unsplash API endpoint ""$($UnsplashApiRandomEndpoint)"" using the topic ""$($Topic)""."
        $JsonResponse = Invoke-RestMethod -Uri $UnsplashApiRandomEndpoint -Method GET -Headers $RequestHeaders -Body @{ "query" = $($Topic); "orientation" = "landscape"; "count" = "30" }
    }
    catch {
        throw "Failed to make a web request to the Unsplash API endpoint ""$($UnsplashApiRandomEndpoint)"" using the topic ""$($Topic)"":`n$($_.Exception.Message)"
    }
}
else {
    # Topics parameter has not been provided
    # Query random images from the Unsplash API
    try {
        Write-Verbose -Message "Attempting to make a web request to the Unsplash API endpoint ""$($UnsplashApiRandomEndpoint)"" with no topic."
        $JsonResponse = Invoke-RestMethod -Uri $UnsplashApiRandomEndpoint -Method GET -Headers $RequestHeaders -Body @{ "orientation" = "landscape"; "count" = "30" }
    }
    catch {
        throw "Failed to make a web request to the Unsplash API endpoint ""$($UnsplashApiRandomEndpoint)"" with no topic:`n$($_.Exception.Message)"
    }
}

# Select a random image from the JsonResponse
Write-Verbose -Message "Attempting to select a random image from the Unsplash API JSON response."
$ImageObject = $JsonResponse | Get-Random
Write-Verbose -Message "Randomly chosen image object:`n$($ImageObject)."
# Obtain image download url
Write-Verbose -Message "Attempting to obtain download URL for the chosen image."
$ImageUrl = $ImageObject.Urls.Raw
Write-Verbose -Message "Image URL ""$($ImageUrl)""."

# Perform a mock download to the Unsplash API
# This is required by Unsplash API guidelines
try {
    Write-Verbose -Message "Attempting to obtain download location URL for the chosen image."
    $ImageDownloadLocation = $ImageObject.Links.Download_Location
    Write-Verbose -Message "Attempting to make a web request to endpoint ""$($ImageDownloadLocation)"" to perform a mock download required by the Unsplash API guidelines."
    Invoke-RestMethod -Uri $ImageDownloadLocation -Method GET -Headers $RequestHeaders | Out-Null
}
catch {
    throw "Failed to make a web request to the Unsplash API endpoint ""$($ImageDownloadLocation)"":`n$($_.Exception.Message)"
}

# Download the chosen image
Write-Output -InputObject "Downloading chosen image from the Unsplash API."
$ImagePath = "$($Env:USERPROFILE)\Documents\TempWallpaper.jpeg"
try {
    Write-Verbose -Message "Attempting to download the chosen image using URL ""$($ImageUrl)"" to file path ""$($ImagePath)""."
    Invoke-WebRequest -Uri $ImageUrl -OutFile $ImagePath
}
catch {
    throw "Failed to download the chosen image using URL ""$($ImageUrl)"":`n$($_.Exception.Message)"
}

# Update the desktop wallpaper
Write-Verbose -Message "Attempting to update the desktop wallpaper."
<#
Credit for the code below comes from Jose Espitia
https://www.joseespitia.com/2017/09/15/set-wallpaper-powershell-function/
#>
$SPI_SETDESKWALLPAPER = 0x14;
$SPIF_UPDATEINIFILE = 0x00;
Write-Verbose -Message "Attempting to add required type definition."
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Params
{
    [DllImport("User32.dll",CharSet=CharSet.Unicode)]
    public static extern int SystemParametersInfo (Int32 uAction,
                                                   Int32 uParam,
                                                   String lpvParam,
                                                   Int32 fuWinIni);
}
"@
try {
    [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $SPIF_UPDATEINIFILE) | Out-Null
}
catch {
    throw "Failed to update desktop wallpaper from downloaded image located at ""$($ImagePath)"" using parameters `$SPI_SETDESKWALLPAPER = 0x14; `$SPIF_UPDATEINIFILE = 0x00;:`n$($_.Exception.Message)"
}
Write-Verbose -Message "Successfully updated wallpaper from downloaded image located at ""$($ImagePath)"" using parameters `$SPI_SETDESKWALLPAPER = 0x14; `$SPIF_UPDATEINIFILE = 0x00;."
Write-Output -InputObject "Successfully updated desktop wallpaper."
