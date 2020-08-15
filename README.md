# Wallie-Pwsh

Wallie-Pwsh can update your desktop wallpaper on Windows 10 🖥️

## Prerequisites

1. Register an application with the [Unsplash API](https://unsplash.com/documentation#registering-your-application).

2. Copy the **Access Key**.

3. Launch a PowerShell console as administrator.

4. Run the following command to produce a base64 encoded string representation of your Unsplash API access key:

    ```powershell
    # Wallie-Pwsh currently requires that you supply the Unsplash API access key as a base64 encoded string
    # This command will produce a base64 encoded string of your access key
    [System.Convert]::ToBase64String([System.Text.Encoding]::UNICODE.GetBytes("Enter access key here."))
    ```

5. When running [Wallie-Pwsh.ps1](Wallie-Pwsh.ps1) provided your base64 encoded access key to the `-AccessKey` parameter.

## Usage

Wallie-Pwsh has an optional parameter to supply topics using the `-Topics` parameter.
When supplied, one will be chosen at random and used in the query to the Unsplash API.

Example usage of the `-Topics` parameter:

```powershell
.\Wallie-Pwsh.ps1 -Topics "Fish","Space","Trains","Jets" -AccessKey "Base64 encoded access key." -Verbose
```

If the `-Topics` parameter is not provided, then Wallie-Pwsh will query the `/photos/random` API endpoint for random images.

### Running periodically

A use case for this script is to run it using Windows Task Scheduler.

> [!NOTE]
> Ensure you enter the correct path to [Wallie-Pwsh.ps1](Wallie-Pwsh.ps1) and provide a base64 encoded access key.

1. Launch a PowerShell console as administrator.

2. Run the following commands to execute Wallie-Pwsh at user log in:

    > [!NOTE]
    > Replace the values of the `-Topics` parameter or remove it (if you desire a random image not based on a topic).

    ```powershell
    $Task = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-NoProfile -WindowStyle "Hidden" -ExecutionPolicy "Bypass" -Command absolute\path\to\Wallie-Pwsh.ps1 -Topics "Mountain","Space","Trains" -AccessKey "Base64 encoded access key." -Verbose'
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -RunLevel "Highest" -Action $Task -Trigger $Trigger -TaskName "Wallie-Pwsh" -Description "Updates the desktop wallpaper at user log in."
    ```

## Authors -- Contributors

* **dbrennand** - *Author* - [dbrennand](https://github.com/dbrennand)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) for details.
