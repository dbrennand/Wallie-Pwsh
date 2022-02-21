# Wallie-Pwsh

Wallie-Pwsh can update your desktop wallpaper on Windows 10 🖥️

## Prerequisites

1. Register an application with the [Unsplash API](https://unsplash.com/documentation#registering-your-application).

2. Copy the **Access Key**.

3. Launch a PowerShell terminal as administrator.

4. Clone the repository:

    ```powershell
    git clone https://github.com/dbrennand/Wallie-Pwsh.git; cd Wallie-Pwsh
    ```

5. Create an `AccessKey.txt` file containing your Unsplash access key in encrypted format:

    ```powershell
    # Run the command below to stop the Unsplash access key from being logged in PSReadline history
    # Set-PSReadlineOption -HistorySaveStyle SaveNothing
    $UnsplashAccessKeySecureString = ConvertTo-SecureString -String "<Unsplash access key>" -AsPlainText -Force
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Wallie-Pwsh",$UnsplashAccessKeySecureString
    $Cred.Password | ConvertFrom-SecureString | Out-File -FilePath "$(pwd)\AccessKey.txt" -Force
    ```

## Usage

Wallie-Pwsh has an optional parameter to supply topics using `-Topics`.
When supplied, a topic will be chosen at random and used in the query to the Unsplash API.

Example usage of the `-Topics` parameter:

```powershell
.\Wallie-Pwsh.ps1 -Topics "Fish","Space","Trains","Jets" -AccessKeyFile ".\AccessKey.txt" -Verbose
```

If the `-Topics` parameter is not provided, then Wallie-Pwsh will query the `/photos/random` API endpoint for random images.

### Updating the Desktop Wallpaper at Log In

A use case for Wallie-Pwsh is to run it using Windows Task Scheduler at log in.

> [!NOTE]
>
> Make sure you enter the correct absolute paths to the [Wallie-Pwsh.ps1](Wallie-Pwsh.ps1) script and Unsplash access key file (using the `-AccessKeyFile` parameter).
>
> To get the absolute paths, run the following command in the Wallie-Pwsh directory:
> ```powershell
> (Get-ChildItem | Where-Object -FilterScript { $_.Name -match "AccessKey|Wallie" }).FullName
> ```

Configure Windows Task Scheduler to execute Wallie-Pwsh at log in:

> [!NOTE]
>
> Replace the values of the `-Topics` parameter in the command below or remove it.

```powershell
$Task = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-NoProfile -WindowStyle "Hidden" -ExecutionPolicy "Bypass" -Command absolute\path\to\Wallie-Pwsh.ps1 -Topics "Mountain","Space","Trains" -AccessKeyFile "absolute\path\to\AccessKey.txt" -Verbose'
$Trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -RunLevel "Highest" -Action $Task -Trigger $Trigger -TaskName "Wallie-Pwsh" -Description "Updates the desktop wallpaper at log in."
```

## Authors -- Contributors

* **dbrennand** - *Author* - [dbrennand](https://github.com/dbrennand)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) for details.
