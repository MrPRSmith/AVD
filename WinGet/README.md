# WinGet
Use the winget tool to install and manage applications
https://learn.microsoft.com/en-us/windows/package-manager/winget/

Windows Package Manager Community Repository
https://github.com/microsoft/winget-pkgs

## Master Image Creation
When creating a master image, use WinGet to install and then export the apps so they can be easily re-installed in the future when either updating or re-creating the master image.
1. Install the required applications via WinGet (Needs to be system-wide installable apps)
2. Use the WinGet export feature to create JSON template of the installed apps
3. Use the WinGet import feature to automatically install all the required apps based on the JSON tempate

### Searching for apps
Simply type the name of the app your looking for. e.g.
- winget search discord
- winget search browser

### Examples
- winget install -e --id Notepad++.Notepad++ --scope machine
- winget install -e --id 7zip.7zip --scope machine
- winget install -e --id Adobe.Acrobat.Reader.64-bit --scope machine
- winget install -e --id VideoLAN.VLC --scope machine
- winget install -e --id GIMP.GIMP --scope machine
- winget install -e --id Microsoft.Azure.StorageExplorer --scope machine
- winget install -e --id Google.EarthPro --scope machine
- winget install -e --id WinSCP.WinSCP --scope machine
- winget install -e --id Microsoft.Sysinternals.BGInfo --scope machine
- winget install -e --id Microsoft.Sysinternals.ZoomIt --scope machine
- winget install -e --id OndrejSalplachta.AdvancedLogViewer
- winget install -e --id Microsoft.VisualStudioCode --scope machine

### Issues
- winget install -e --id Discord.Discord --scope machine 
- winget install -e --id 9WZDNCRFJ3PZ --scope machine

### Exporting JSON
winget export -o FILNAME.JSON --accept-source-agreements --include-versions

### Importing JSON
winget import -i FILNAME.JSON --accept-package-agreements --accept-source-agreements --ignore-versions --ignore-unavailable

# Known Issues
Below are some of the issues encountered when using WinGet for AVD

### Machine Scope
**Check the app suppports the machine scope flag and check it performs as expected.** When the machine scope is specified for an application, WinGet attempts to pass any flags needed to make the install machine-wide to the installer. It is up to the installer provided by the publisher of the software to do the "right thing" and add the start menu entries and shortcuts - that isn't something winget has control over. Additionally, some installers claim to install for all users but then end up only installing to a single user - despite writing their registry entries to say the install was "machine-wide".
**winget import and export functions do not include a method to specify scope.** 