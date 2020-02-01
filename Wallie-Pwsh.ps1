<#
MIT License

Copyright (c) 2020 Dextroz

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
        Wallie-Pwsh sets your desktop wallpaper.
    
    .DESCRIPTION
        Wallie-Pwsh sets your desktop wallpaper using the Unsplash API!

    .PARAMETER Topics
        If supplied, Wallie-Pwsh will select a topic at random and use this to query for an image.
        It will then select a result from the Unsplash API at random.

    .PARAMETER AccessKey
        A base64 encoded API key (access key) used to authenticate with the Unsplash API.

    .EXAMPLE
        .\Wallie-Pwsh.ps1 -Topics @("Fish", "Space", "Trains", "Red car", "Jets") -AccessKey "Base64 encoded access key." -Verbose

    .EXAMPLE
        .\Wallie-Pwsh.ps1 -AccessKey "Base64 encoded access key."

    .NOTES
        Ensure you provide the AccessKey as a base64 encoded string. Sadly, security through obscurity. 
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
$Version = "0.0.1"
# Decode base64 encoded AccessKey.
try {
    Write-Verbose -Message "Attempting to decode access key"
    $AccessKey = [System.Text.Encoding]::UNICODE.GetString([System.Convert]::FromBase64String($AccessKey))
}
catch {
    Write-Error -Message "Failed to decode base64 encoded API key."
    break
}
# Check if topics has been supplied or not, run respective code flow.
if ($Topics -eq $null) {
    # If null (not supplied), query the API using the random endpoint.
    try {
        Write-Verbose -Message "Attempting to make a web request to the Unsplash API endpoint: /photos/random"
        # Retrieve a random wallpaper in landscape orientation.
        $JsonResponse = Invoke-RestMethod -Uri "https://api.unsplash.com/photos/random" -Method "GET" -Headers @{"Authorization" = "Client-ID $AccessKey" 
        "Accept-Version" = "v1"} -Body @{"orientation" = "landscape" }
    }
    catch {
        Write-Error -Message "Failed to perform web request to the Unsplash API endpoint: https://api.unsplash.com/photos/random"
        break
    }
} else {
    # If not null.
    # Select a topic at random, query the image using chosen topic and select an image returned at random.
    # Select a random topic from $Topics.
    Write-Verbose -Message "Choosing a random topic"
    $Topic = $Topics[(Get-Random -Maximum ($Topics).Count)]
    Write-Verbose -Message "Topic chosen is: $Topic"
    try {
        Write-Verbose -Message "Attempting to make a web request to the Unsplash API /photos/random endpoint with the topic: $Topic"
        $JsonResponse = Invoke-RestMethod -Uri "https://api.unsplash.com/photos/random" -Method "GET" -Headers @{"Authorization" = "Client-ID $AccessKey"
        "Accept-Version" = "v1"} -Body @{"query" = $Topic
        "orientation" = "landscape" 
        "count" = "30"}
    }
    catch {
        Write-Error -Message "Failed to perform web request to the Unsplash API endpoint: https://api.unsplash.com/photos/random with the topic: $Topic"
        break
    }
}
# Select a random image from the $JsonResponse.
Write-Verbose -Message "Selecting a random image from the JSON response"
$ImageObject = $JsonResponse | Get-Random
# Get image download url.
$ImageUrl = $ImageObject.urls.raw
Write-Verbose -Message "Image URL is: $ImageUrl"
# Download the image.
$ImagePath = "$Env:USERPROFILE\Documents\TempWallpaper.jpeg"
Write-Verbose -Message "Attempting to download image from URL: $ImageUrl to file path: $ImagePath"
try {
    Invoke-WebRequest -Uri $ImageUrl -OutFile $ImagePath
}
catch {
    Write-Error -Message "Failed to download the image from URL: $ImageUrl"
    break
}
# Set the desktop wallpaper.
Write-Verbose -Message "Setting desktop wallpaper"
# Credit for the code below comes from Jose Espitia
# https://www.joseespitia.com/2017/09/15/set-wallpaper-powershell-function/
$SPI_SETDESKWALLPAPER = 0x14;
$SPIF_UPDATEINIFILE = 0x00;
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
[Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $SPIF_UPDATEINIFILE) | Out-Null
