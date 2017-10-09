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
$temp="c:\TempO365\Office365AuthSetup-yFH4gu"
$npm="npm-1.4.9.zip"
$config="c:\Program Files\Qlik\Sense\ServiceDispatcher"
$target="$config\Node\Office365-Auth"
$moduleName="qlik-auth-office365"


# check if module is installed
# if(!(Test-Path -Path "$target\node_modules")) {

    $confirm = Read-Host "This script will install the Office365 Auth module for Qlik Sense, do you want to proceed? [Y/n]"
    if ($confirm -eq 'n') {
      Break
    }

    # check if npm has been downloaded already
    if(!(Test-Path -Path "$temp\$npm")) {
        New-Item -Path "$temp" -Type directory -force | Out-Null
        Invoke-WebRequest "http://nodejs.org/dist/npm/$npm" -OutFile "$temp\$npm"
    }

    New-Item -Path "$target" -Type directory -force | Out-Null
    New-Item -Path "$temp" -Type directory -force | Out-Null

    # Installing Qlik-CLI
    Write-Host "Downloading Qlik-Cli from Github and importing the Module"
    Invoke-WebRequest "https://raw.githubusercontent.com/ahaydon/Qlik-Cli/master/Qlik-Cli.psm1" -OutFile $temp\Qlik-Cli.psm1
    New-Item -ItemType directory -Path C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Qlik-Cli -force
    Move-Item $temp\Qlik-Cli.psm1 C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Qlik-Cli\ -force
    Import-Module Qlik-Cli.psm1

    # check if module has been downloaded
    # if(!(Test-Path -Path "$target")) {
        Write-Host "Extracting Office365 auth module..."
        Invoke-WebRequest "https://github.com/mjromper/$moduleName/archive/master.zip" -OutFile "$temp\$moduleName-master.zip"
        Expand-Archive -LiteralPath $temp\$moduleName-master.zip -DestinationPath $temp -Force
        Copy-Item $temp\$moduleName-master\* $target -Force -Recurse
    # }

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
#}

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
qlik_sense_hostname=
certificates_path=
auth_port=
client_id=
client_secret=
"@
	Add-Content "$config\services.conf" $settings
}

# configure module
Write-Host $nl"CONFIGURE MODULE"
Write-Host $nl"To make changes to the configuration in the future just re-run this script."

$user_directory=Read-Default $nl"Enter name of user directory (prefix)" "OFFICE365"
$qlik_sense_hostname=Read-Default $nl"Enter QS hostname (just hostname, not entire URL)" $qlik_sense_hostname
$certificates_path=Read-Default $nl"Enter certificates folder path:" "C:/ProgramData/Qlik/Sense/Repository/Exported Certificates/.Local Certificates"
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
Set-Config -file "$config\services.conf" -key "qlik_sense_hostname" -value $qlik_sense_hostname
Set-Config -file "$config\services.conf" -key "certificates_path" -value $certificates_path
Set-Config -file "$config\services.conf" -key "auth_port" -value $auth_port
Set-Config -file "$config\services.conf" -key "client_id" -value $client_id
Set-Config -file "$config\services.conf" -key "client_secret" -value $client_secret



# Adding/updating virtual proxy
$VPId=$(Get-QlikVirtualProxy -filter "description eq '$user_directory'")
if ( !$VPId ) {
    Write-Host "Creating Virtual Proxy"
    New-QlikVirtualProxy -prefix $($user_directory) -description $($user_directory) -authUri https://$($qlik_sense_hostname):$($auth_port)/oauth2callback -sessionCookieHeaderName X-Qlik-Session-$($user_directory) -loadBalancingServerNodes $(Get-QlikNode).id -websocketCrossOriginWhiteList $($qlik_sense_hostname)
    $VPId=$(Get-QlikVirtualProxy -filter "description eq '$user_directory'")
} else {
    Write-Host "Updating Virtual proxy"
    Update-QlikVirtualProxy -id $VPId.id -description $($user_directory) -authUri https://$($qlik_sense_hostname):$($auth_port)/oauth2callback -sessionCookieHeaderName X-Qlik-Session-$($user_directory) -loadBalancingServerNodes $(Get-QlikNode).id -websocketCrossOriginWhiteList $($qlik_sense_hostname)
}
Add-QlikProxy -ProxyId $(Get-QlikProxy).id -VirtualProxyId $VPId.id



# Restart ServiceDipatcher
Write-Host $nl"Restarting ServiceDispatcher.."
net stop QlikSenseServiceDispatcher
start-sleep 5
net start QlikSenseServiceDispatcher
Write-Host $nl"Done! 'Qlik Sense Service Dispatcher' restarted."$nl
Write-Host $nl"Done! Latch Auth module installed."$nl

Write-Host $nl"Access Qlik Sense through virtual proxy $user_directory."$nl
