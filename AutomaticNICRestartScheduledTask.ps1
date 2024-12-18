# Set Script Path / Additional Details
$scriptDirectory = "C:\Scripts"
$scriptPath = "$scriptDirectory\AutomaticNICRestart.ps1"
$taskName = "Automatically Restart NIC Adapter"
$taskDescription = "This scheduled task was created to automatically restart network adapters to workaround a known issue with Windows Server 2025 pulling a public network profile on Domain Controllers instead of a Domain network."
$taskTrigger = "AtStartup"
$adapterName = "Ethernet"

# Create the Scripts directory if it's non existent
if (-not (Test-Path -Path $scriptDirectory)) {
    New-Item -Path $scriptDirectory -ItemType Directory
}

# Here is our script content for the PS script the task will be running
# IMPORTANT NOTE: Replace the Ethernet name with the name of your server's NIC adapter
$scriptContent = @'
# This script restarts your network adapter named "Ethernet"
# If the adapter you're wanting to reset isn't "Ethernet" please change the name to the appropriate NIC
$adapterName = "Ethernet"

# Check if the adapter exists and add a fail safe to just stop the script if it doesn't
$adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
if ($adapter -ne $null) {
    Write-Host "Restarting network adapter: $adapterName"
    Disable-NetAdapter -Name $adapterName -Confirm:$false
    Start-Sleep -Seconds 5
    Enable-NetAdapter -Name $adapterName -Confirm:$false
} else {
    Write-Host "Network adapter named '$adapterName' not found."
}
'@

# Create the new PowerShell script with the content we defined earlier
Set-Content -Path $scriptPath -Value $scriptContent -Force

# Create scheduled task
# Execution policy set to bypass to ensure it runs even if running scripts has been disabled on the system via ExecutionPolicy
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptPath"

# Define the task trigger (at startup)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Define the scheduled task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the task
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description $taskDescription -User "NT AUTHORITY\SYSTEM" -Settings $settings

Write-Host "Scheduled task '$taskName' has now been registered"