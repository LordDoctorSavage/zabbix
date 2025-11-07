##### Zabbix Agent 2 Install Script
##### Written by Brandon E.M. Savage - brandon at brandonsavage . com
##### Version 6.2
##### 2025-11-06

### Remember to always use variables kids!  It'll save you so much time down the road!

### Install, uninstall, and download variables - $file and $link can be changed for different versions.
### We will be using the latest version of Zabbix Agent 2 on the 7.0 LTS branch

$file = 'zabbix_agent2-7.0-latest-windows-amd64-openssl.msi'
$link = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/latest/$file"
$soft_name = 'Zabbix Agent 2 (64-bit)'
$problematicRegKey = 'HKLM:\SYSTEM\ControlSet001\Services\EventLog\Application\Zabbix Agent 2'
$problematicRegKey2 = 'HKML:\SYSTEM\ControlSet002\Services\Zabbix Agent 2'
$serviceName = 'Zabbix Agent 2'
$exitCode = 0

### Zabbix Configuration File Variables - If using a proxy, use the hostname or FDQN of the proxy in the $zabbixServer variable.  - 
### Hostname/FQDN of the proxy must be defined in the DNS record for the site or the agents will not check in.

###  Make sure that folders, servers and TLS info are updated to reflect your environment.

$rootFolder = "C:\Program" + " " + "Files\Zabbix\"
$installFolder = $rootFolder + "Monitoring\"
$tlsIdentity = '[Your TLS Identity]'
$tlsHash = '[Your TLS Hash]'
$zabbixServer = '[Your Zabbix server or proxy]'

### These variables assign the hostname, and after installation edit the config file to make the hostname dynamic.
### The addition of system.hostname[fqdn,lower] in Zabbix 7.0 resolves a longstanding issue that we have faced.  Rejoice in the 7.0 update!

$hostNameStatic = [System.Net.Dns]::GetHostByName($env:computerName).HostName.ToLower()
$zabbixConfigFile = "$installFolder" + "zabbix_agent2.conf"

$strFind = "HOSTNAME=$hostNameStatic"
$strReplace = 'HostnameItem=system.hostname[fqdn,lower]' # Not backwards compatible with agents before 7.0

### Action variables - You should not need to modify these unless you do not have a Windows\Temp folder for some reason.

$tmp = "$env:WinDir\temp\$file"
$find = Get-WmiObject -Class Win32_Product -Filter "Name LIKE `'$soft_name`%'"
$client = New-Object System.Net.WebClient

###  MSI install parameters - This section should not be touched, most variables can be set above and the remaining ones shouldn't need changing. 
###  You can be more discriminating  with your AllowKey settings here if you are under more strict security considerations.
###  Prior to version 7.0.18, the timeout max was 30 seconds.  It is 600 seconds in all later versions.
###  ***MSI variables are very specific and should be edited with caution.***

$msiParams = "/l*v $env:WinDir\temp\zabbixinstall.log" + " " + "/i $tmp" + " " + '/qn' + " " + "INSTALLFOLDER=`"$installFolder`"" + " " + "SERVER=`"$zabbixServer`"" + " " + "SERVERACTIVE=`"$zabbixServer`"" + " " + 'TLSCONNECT="psk"' + " " + 'TLSACCEPT="psk"' + " " + "TLSPSKVALUE=`"$tlsHash`"" + " " + "TLSPSKIDENTITY=`"$tlsIdentity`"" + " " + "HOSTNAME=`"$hostNameStatic`""+ " " + 'STARTUPTYPE="delayed"' + " " + 'ALLOWDENYKEY="AllowKey=system.run[*]"' + " " + 'TIMEOUT=30'

### END VARIABLES - *** Nothing below this line should need to be touched - unless a functional change to the script is necessary. 

### Set downloads to secure TLS12 - This may cause some 2012r2 and earlier servers to fail.  
### Nobody should be using 2012r2 servers or earlier, and they are out of support so if this fails, tough titties.

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

### Check for existing agents and uninstall if they exist.

if ($find -ne $null) {
		$find.Uninstall()
		Write-Output "Uninstalled $soft_name"
	}

### The next section cleans up orphaned files, folders, and registry entries that may get left behind by an uninstallation.
### These variables must be set after the uninstall step above.
### If any of these are not removed, install may fail with a 1603 error.

### Check for orphaned services, regkeys and folders

$zabbixService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
$orphanRegKey = Get-ItemProperty -Path $problematicRegKey -ErrorAction SilentlyContinue
$orphanRegKey2 = Get-ItemProperty -Path $problematicRegKey -ErrorAction SilentlyContinue
$leftoverFolder = Test-Path $rootFolder -ErrorAction SilentlyContinue

### If there is an orphaned Zabbix service, remove it.

if ($zabbixService -ne $null) {
		Start-Process sc.exe -ArgumentList "delete $serviceName"
		#Remove-Service -Name $serviceName - Only works in PowerShell 6.0+
		Write-Output 'Removed orphaned Zabbix service'
}

### Remove install folder and any orphaned files before re-installing

if ($leftoverFolder -eq 'True') {
		Remove-Item $rootFolder -Recurse -Force -ErrorAction SilentlyContinue
		Write-Output 'Removed orphaned Zabbix install folder'
}

### Clean up orphaned registry key(s)

if ($orphanRegKey -ne $null) {
		Remove-Item -Path $problematicRegKey -Force
		Write-Output 'Removed orphaned Zabbix registry key'
}

if ($orphanRegKey2 -ne $null) {
		Remove-Item -Path $problematicRegKey2 -Force
		Write-Output 'Removed orphaned Zabbix registry key'
}

### Get Zabbix downloaded, installed, and configured. 

$client.DownloadFile($link, $tmp)

$runMSI = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiParams -PassThru -Wait
	
### Return success or error code

if ($runMSI.ExitCode -ne "0")
	{
	Write-Output "Failed to install $soft_name.  Exited with error code: " $runMSI.ExitCode
	$exitCode = $runMSI.ExitCode
	} else
	{
	Write-Output "Installed $soft_name successfully"
	}

### Delete Zabbix agent install file	
	
del $tmp

### Set the hostname to be dynamically discovered on every agent startup.
### Dynamic naming will result in a new host check in every time a device name is changed or added to/removed from a domain
### If you would prefer to keep the static naming defined at the top you can comment out the following 3 commands

(Get-Content -Path $zabbixConfigFile) -replace $strFind, $strReplace | Set-Content $zabbixConfigFile

Start-Sleep -Seconds 15

Restart-Service $serviceName

### Exit the script with 0 if there is no error, or the MSI error code if there is one

exit $exitCode
