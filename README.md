# Wallie-Pwsh
Wallie-Pwsh can set your desktop wallpaper on Windows 10 🖥️

## Prerequisites

1. Register an application with the [Unsplash API](https://unsplash.com/documentation#registering-your-application)

2. Copy the **Access Key**

3. Launch a PowerShell console as administrator

4. Run the following command to produce a base64 encoded string representation of your Unsplash access key:

    ```powershell
    # Wallie-Pwsh currently requires that you supply the Unsplash access key as a base64 encoded string.
    # This command will produce a base64 encoded string of your access key.
    [System.Convert]::ToBase64String([System.Text.Encoding]::UNICODE.GetBytes("Enter access key here."))
    ```

5. When running Wallie-Pwsh, supply this string to the `-AccessKey` parameter.

## Usage

Wallie-Pwsh has the option to supply some topics using the `-Topics` parameter. 
When supplied, one will be chosen at random and used in the query to the Unsplash API.

Example usage for `-Topics` parameter:

```powershell
.\Wallie-Pwsh.ps1 -Topics "Fish","Space","Trains","Jets" -AccessKey "Base64 encoded access key." -Verbose
```

Or you can choose to not supply the `-Topics` parameter. Wallie-Pwsh will query the `/photos/random` API endpoint for a random image.

### Running periodically

A use case for this script is to run it using Task Scheduler.

**Ensure you enter the correct path to Wallie-Pwsh and provide a base64 encoded access key**

Run the following commands to execute this script on user logon:

```powershell
$Task = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-NoProfile -WindowStyle "Hidden" -ExecutionPolicy "Bypass" -Command absolute\path\to\Wallie-Pwsh.ps1 -Topics "Fish","Space","Trains" -AccessKey "Base64 encoded access key." -Verbose'
$Trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -RunLevel "Highest" -Action $Task -Trigger $Trigger -TaskName "Wallie-Pwsh" -Description "Sets desktop wallpaper at user logon"
```

## Authors -- Contributors

* **Dextroz** - *Author* - [Dextroz](https://github.com/Dextroz)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) for details.