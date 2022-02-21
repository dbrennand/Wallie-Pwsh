<#
MIT License

Copyright (c) 2022 dbrennand

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
    If supplied, Wallie-Pwsh will select a topic at random and use this to query an image from the Unsplash API.
    Wallie-Pwsh will then select a result from the Unsplash API at random.

.PARAMETER AccessKeyFile
    The absolute path to the file containing the encrypted Unsplash access key.

.EXAMPLE
    .\Wallie-Pwsh.ps1 -Topics "Fish","Space","Trains","Jets" `
        -AccessKeyFile "C:\Users\User\Wallie-Pwsh\AccessKey.txt"

.EXAMPLE
    .\Wallie-Pwsh.ps1 -AccessKeyFile "C:\Users\User\Wallie-Pwsh\AccessKey.txt" -Verbose
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [Array]
    $Topics,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
    [String]
    $AccessKeyFile
)

# Declare script version
$Version = "1.0.0"
Write-Verbose -Message "Running Wallie-Pwsh.ps1 version: $($Version)."

# Get encrypted Unsplash access key from file
try {
    Write-Verbose -Message "Attempting to get encrypted Unsplash access key from file ""$($AccessKeyFile)""."
    $AccessKeyFileContents = Get-Content -Path $AccessKeyFile -Verbose:($PSBoundParameters["Verbose"] -eq $true)
}
catch {
    throw "Failed to get encrypted Unsplash access key from file ""$($AccessKeyFile)"":`n$($_.Exception.Message)"
}

# Decrypt Unsplash access key
try {
    Write-Verbose -Message "Attempting to decrypt Unsplash access key."
    $AccessKeySecureString = $AccessKeyFileContents | ConvertTo-SecureString
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Wallie", $AccessKeySecureString
    $AccessKey = $Cred.GetNetworkCredential().Password
}
catch {
    throw "Failed to decrypt Unsplash access key from file ""$($AccessKeyFile)"":`n$($_.Exception.Message)"
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
        $JsonResponse = Invoke-RestMethod -Uri $UnsplashApiRandomEndpoint -Method GET -Headers $RequestHeaders -Body @{ "query" = $($Topic); "orientation" = "landscape"; "count" = "30" } -Verbose:($PSBoundParameters["Verbose"] -eq $true)
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
        $JsonResponse = Invoke-RestMethod -Uri $UnsplashApiRandomEndpoint -Method GET -Headers $RequestHeaders -Body @{ "orientation" = "landscape"; "count" = "30" } -Verbose:($PSBoundParameters["Verbose"] -eq $true)
    }
    catch {
        throw "Failed to make a web request to the Unsplash API endpoint ""$($UnsplashApiRandomEndpoint)"" with no topic:`n$($_.Exception.Message)"
    }
}

# Select a random image from the JSON response
Write-Verbose -Message "Attempting to select a random image from the JSON response."
$ImageObject = $JsonResponse | Get-Random
Write-Verbose -Message "Randomly chosen image object:`n$($ImageObject)."
# Obtain image download url
Write-Verbose -Message "Attempting to obtain download URL for the chosen image."
$ImageUrl = $ImageObject.Urls.Raw
Write-Verbose -Message "Image URL ""$($ImageUrl)""."

# Perform a mock download to the Unsplash API
# Required by Unsplash API guidelines: https://help.unsplash.com/en/articles/2511258-guideline-triggering-a-download
try {
    Write-Verbose -Message "Attempting to obtain download location URL for the chosen image."
    $ImageDownloadLocation = $ImageObject.Links.Download_Location
    Write-Verbose -Message "Attempting to make a web request to endpoint ""$($ImageDownloadLocation)"" to perform a mock download required by the Unsplash API guidelines."
    Invoke-RestMethod -Uri $ImageDownloadLocation -Method GET -Headers $RequestHeaders -Verbose:($PSBoundParameters["Verbose"] -eq $true) | Out-Null
}
catch {
    throw "Failed to make a web request to the Unsplash API endpoint ""$($ImageDownloadLocation)"":`n$($_.Exception.Message)"
}

# Download the chosen image
Write-Output -InputObject "Downloading chosen image from the Unsplash API."
$ImagePath = "$($Env:USERPROFILE)\Documents\TempWallpaper.jpeg"
try {
    Write-Verbose -Message "Attempting to download the chosen image with URL ""$($ImageUrl)"" to file path ""$($ImagePath)""."
    Invoke-WebRequest -Uri $ImageUrl -Method GET -OutFile $ImagePath -Verbose:($PSBoundParameters["Verbose"] -eq $true)
}
catch {
    throw "Failed to download the chosen image with URL ""$($ImageUrl)"" to file path ""$($ImagePath)"":`n$($_.Exception.Message)"
}

<#
Credit for the type definition below comes from Jose Espitia
https://www.joseespitia.com/2017/09/15/set-wallpaper-powershell-function/
#>
$SPI_SETDESKWALLPAPER = 0x14;
$SPIF_UPDATEINIFILE = 0x00;
try {
    Write-Verbose -Message "Attempting to add type definition."
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
}
catch {
    throw "Failed to add type definition:`n$($_.Exception.Message)"
}

# Update the desktop wallpaper
try {
    Write-Output -InputObject "Updating desktop wallpaper."
    Write-Verbose -Message "Attempting to update desktop wallpaper to image located at ""$($ImagePath)"" using parameters `$SPI_SETDESKWALLPAPER = $($SPI_SETDESKWALLPAPER); `$SPIF_UPDATEINIFILE = $($SPIF_UPDATEINIFILE);."
    [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $SPIF_UPDATEINIFILE) | Out-Null
}
catch {
    throw "Failed to update desktop wallpaper to image located at ""$($ImagePath)"":`n$($_.Exception.Message)"
}
Write-Verbose -Message "Successfully updated desktop wallpaper to image located at ""$($ImagePath)""."
Write-Output -InputObject "Successfully updated desktop wallpaper."
