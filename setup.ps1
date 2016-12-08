$nl = [Environment]::NewLine

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Write-Host $nl"Press any key to continue ..."
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Break
}

# Set black background
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# define some variables
$temp="c:\Temp\Office365AuthSetup-yFH4gu"
$npm="npm-1.4.12.zip"
$config="c:\Program Files\Qlik\Sense\ServiceDispatcher"
$target="$config\Node\Office365-Auth"

# check if module is installed
if(!(Test-Path -Path "$target\node_modules")) {

    $confirm = Read-Host "This script will install the Office 365 Auth module, do you want to proceed? [Y/n]"
    if ($confirm -eq 'n') {
      Break
    }

    # check if npm has been downloaded already
	if(!(Test-Path -Path "$temp\$npm")) {
        New-Item -Path "$temp" -Type directory -force | Out-Null
		Invoke-WebRequest "http://nodejs.org/dist/npm/$npm" -OutFile "$temp\$npm"
	}

    # check if module has been downloaded
    if(!(Test-Path -Path "$target\src")) {
        New-Item -Path "$target\src" -Type directory | Out-Null
        Invoke-WebRequest "http://raw.githubusercontent.com/mjromper/qlik-auth-office365/master/service.js" -OutFile "$target\service.js"
        Invoke-WebRequest "http://raw.githubusercontent.com/mjromper/qlik-auth-office365/master/o365.js" -OutFile "$target\o365.js"
        Invoke-WebRequest "http://raw.githubusercontent.com/mjromper/qlik-auth-office365/master/settings.json" -OutFile "$target\settings.json"
        Invoke-WebRequest "http://raw.githubusercontent.com/mjromper/qlik-auth-office365/master/package.json" -OutFile "$target\package.json"
    }

    # check if npm has been unzipped already
    if(!(Test-Path -Path "$temp\node_modules")) {
        Write-Host "Extracting files..."
        Add-Type -assembly "system.io.compression.filesystem"
        [io.compression.zipfile]::ExtractToDirectory("$temp\$npm", "$temp")
    }

    # install module with dependencies
	Write-Host "Installing modules..."
    Push-Location "$target"
    $env:Path=$env:Path + ";$config\Node"
	&$temp\npm.cmd config set spin=false
	&$temp\npm.cmd --prefix "$target" install
    Pop-Location

    # cleanup temporary data
    Write-Host $nl"Removing temporary files..."
    Remove-Item $temp -recurse
}

function Read-Default($text, $defaultValue) { $prompt = Read-Host "$($text) [$($defaultValue)]"; return ($defaultValue,$prompt)[[bool]$prompt]; }

# check if config has been added already
if (!(Select-String -path "$config\services.conf" -pattern "Identity=aor-o365-auth" -quiet)) {

	$settings = @"


[office365-auth]
Identity=aor-o365-auth
Enabled=true
DisplayName=Office365 Auth
ExecType=nodejs
ExePath=Node\node.exe
Script=Node\office365-auth\service.js

[office365-auth.parameters]
user_directory=
auth_port=
client_id=
client_secret=
"@
	Add-Content "$config\services.conf" $settings
}

# configure module
Write-Host $nl"CONFIGURE MODULE"
Write-Host $nl"To make changes to the configuration in the future just re-run this script."

$user_directory=Read-Default $nl"Enter name of user directory" "OFFICE365"
$auth_port=Read-Default $nl"Enter port" "5555"
$client_id=Read-Default $nl"Application ID" $client_id
$client_secret=Read-Default $nl"Client Secret" $client_secret

function Set-Config( $file, $key, $value )
{
    $regreplace = $("(?<=$key).*?=.*")
    $regvalue = $("=" + $value)
    if (([regex]::Match((Get-Content $file),$regreplace)).success) {
        (Get-Content $file) `
            |Foreach-Object { [regex]::Replace($_,$regreplace,$regvalue)
         } | Set-Content $file
    }
}

# write changes to configuration file
Write-Host $nl"Updating configuration..."
Set-Config -file "$config\services.conf" -key "user_directory" -value $user_directory
Set-Config -file "$config\services.conf" -key "auth_port" -value $auth_port
Set-Config -file "$config\services.conf" -key "client_id" -value $client_id
Set-Config -file "$config\services.conf" -key "client_secret" -value $client_secret

Write-Host $nl"Done! Please restart the 'Qlik Sense Service Dispatcher' service for changes to take affect."$nl