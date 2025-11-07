##### Advanced Windows Service Restart Script
##### Written by Brandon E.M. Savage
##### Version 1.0
##### 2025-11-06
param(
[string]$service
)

# Set variables - Static for now, with the eventual goal of accepting a variable passed from the command line

# Use Get-Service to find the service Status

$query = get-service -Name "$service"

if ($query.Status -eq 'Stopped') {
Restart-Service -Name "$service"
Write-Output "Starting Stopped Service $service"
}

if ($query.Status -eq 'Running') {
$id = Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" |
Select-Object -ExpandProperty ProcessId

$process = Get-Process -Id $id

Start-Process taskkill.exe -Args "-f -PID $id"

Restart-Service -Name "$service"

Write-Output "Killed PID $id and restarted $service"
}

if ($query.Status -eq 'Paused') {
Resume-Service -Name "$service"
Write-Output "Resuming Paused Service $service"
}

if ($query.Status -eq 'Start Pending') {
$id = Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" |
Select-Object -ExpandProperty ProcessId

$process = Get-Process -Id $id

Start-Process taskkill.exe -Args "-f -PID $id"

Restart-Service -Name "$service"

Write-Output "Killed PID $id and restarted $service"
}

if ($query.Status -eq 'Stop Pending') {
$id = Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" |
Select-Object -ExpandProperty ProcessId

$process = Get-Process -Id $id

Start-Process taskkill.exe -Args "-f -PID $id"

Restart-Service -Name "$service"

Write-Output "Killed PID $id and restarted $service"
}
