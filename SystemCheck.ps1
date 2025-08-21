<#
.MÔ TẢ
  Công cụ audit nhanh toàn bộ registry key, service, scheduled task, 
  và AppX packages liên quan đến quyền riêng tư & hoạt động nền của Windows.
  Chỉ hiển thị kết quả, không chỉnh sửa hệ thống.
  Credit: Linh at bachdinh.com
  
.DESCRIPTION
  A quick audit tool for all registry keys, services, scheduled tasks, 
  and AppX packages related to Windows privacy & background activity.
  Displays results only, makes no system modifications.
  Credit: Linh at bachdinh.com
#>

[CmdletBinding()]
param(
  [string]$JsonOut = ".\Privacy_AuditFull_v5_$(Get-Date -Format 'yyyyMMdd-HHmmss').json",
  [string]$CsvOut  = ".\Privacy_AuditFull_v5_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

Write-Host "=== FULL WINDOWS PRIVACY AUDIT BACHDINH.COM (READ-ONLY, ALL SERVICES, TASKS & APPX APPS) ===" -ForegroundColor Cyan

$results = New-Object System.Collections.Generic.List[object]

function Get-RegValue {
  param(
    [Parameter(Mandatory)][ValidateSet('HKLM','HKCU')][string]$Hive,
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name
  )
  $reg = "${Hive}:\$Path"
  try {
    (Get-ItemProperty -Path $reg -Name $Name -ErrorAction Stop).$Name
  } catch { '[Not Found]' }
}

function Add-Check {
  param([string]$Category,[string]$Setting,[string]$Hive,[string]$Path,[string]$Name,[string]$Value)
  $results.Add([pscustomobject]@{
    Category=$Category; Setting=$Setting; Hive=$Hive; Path=$Path; Name=$Name; Value=$Value
  }) | Out-Null
}

# --------------------
# Registry: Core privacy
# --------------------
$regCore = @(
  @{S='Advertising ID';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo';N='Enabled'},
  @{S='Telemetry level (0-3)';H='HKLM';P='Software\Policies\Microsoft\Windows\DataCollection';N='AllowTelemetry'},
  @{S='Tailored experiences';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\Privacy';N='TailoredExperiencesWithDiagnosticDataEnabled'},
  @{S='Feedback frequency';H='HKCU';P='Software\Microsoft\Siuf\Rules';N='NumberOfSIUFInPeriod'},
  @{S='App suggestions/Consumer features';H='HKLM';P='Software\Policies\Microsoft\Windows\CloudContent';N='DisableWindowsConsumerFeatures'},
  @{S='Start menu suggestions';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='SystemPaneSuggestionsEnabled'},
  @{S='Activity history';H='HKLM';P='Software\Policies\Microsoft\Windows\System';N='EnableActivityFeed'},
  @{S='Publish user activities';H='HKLM';P='Software\Policies\Microsoft\Windows\System';N='PublishUserActivities'},
  @{S='Upload user activities';H='HKLM';P='Software\Policies\Microsoft\Windows\System';N='UploadUserActivities'},
  @{S='Cortana web search';H='HKLM';P='Software\Policies\Microsoft\Windows\Windows Search';N='DisableWebSearch'},
  @{S='Allow Cortana';H='HKLM';P='Software\Policies\Microsoft\Windows\Windows Search';N='AllowCortana'},
  @{S='Cortana web search online';H='HKLM';P='Software\Policies\Microsoft\Windows\Windows Search';N='ConnectedSearchUseWeb'},
  @{S='Allow Search to use location';H='HKLM';P='Software\Policies\Microsoft\Windows\Windows Search';N='AllowSearchToUseLocation'},
  @{S='OneDrive integration disabled';H='HKLM';P='Software\Policies\Microsoft\Windows\OneDrive';N='DisableFileSyncNGSC'},
  @{S='Clipboard history';H='HKLM';P='Software\Policies\Microsoft\Windows\System';N='AllowClipboardHistory'},
  @{S='Clipboard cloud sync';H='HKLM';P='Software\Policies\Microsoft\Windows\System';N='AllowCrossDeviceClipboard'},
  @{S='Tips and suggestions';H='HKLM';P='Software\Policies\Microsoft\Windows\CloudContent';N='DisableSoftLanding'},
  @{S='Windows Spotlight features';H='HKLM';P='Software\Policies\Microsoft\Windows\CloudContent';N='DisableWindowsSpotlightFeatures'},
  @{S='LockScreen Rotating Spotlight';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='RotatingLockScreenEnabled'},
  @{S='LockScreen Spotlight Overlay';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='RotatingLockScreenOverlayEnabled'},
  @{S='LockScreen Suggested apps';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='SubscribedContent-353694Enabled'},
  @{S='Tips & suggestions ID 310093';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='SubscribedContent-310093Enabled'},
  @{S='Tips & suggestions ID 338389';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='SubscribedContent-338389Enabled'}
)

# --------------------
# Registry: Network & Updates
# --------------------
$regNetUpd = @(
  @{S='WiFi Sense Hotspot reporting';H='HKLM';P='Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting';N='Value'},
  @{S='WiFi Sense auto connect';H='HKLM';P='Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots';N='Value'},
  @{S='Delivery Optimization P2P mode';H='HKLM';P='Software\Policies\Microsoft\Windows\DeliveryOptimization';N='DODownloadMode'},
  @{S='Windows Update: Block driver updates';H='HKLM';P='Software\Policies\Microsoft\Windows\WindowsUpdate';N='ExcludeWUDriversInQualityUpdate'},
  @{S='Windows Update: Defer feature updates (days)';H='HKLM';P='Software\Policies\Microsoft\Windows\WindowsUpdate';N='DeferFeatureUpdatesPeriodInDays'},
  @{S='Windows Update: Defer quality updates (days)';H='HKLM';P='Software\Policies\Microsoft\Windows\WindowsUpdate';N='DeferQualityUpdatesPeriodInDays'}
)

# --------------------
# Registry: Defender & SmartScreen (system-wide)
# --------------------
$regDefender = @(
  @{S='System SmartScreen enabled';H='HKLM';P='Software\Policies\Microsoft\Windows\System';N='EnableSmartScreen'},
  @{S='System SmartScreen level';H='HKLM';P='Software\Policies\Microsoft\Windows\System';N='ShellSmartScreenLevel'},
  @{S='Defender Spynet reporting';H='HKLM';P='Software\Policies\Microsoft\Windows Defender\Spynet';N='SpynetReporting'},
  @{S='Defender sample submission consent';H='HKLM';P='Software\Policies\Microsoft\Windows Defender\Spynet';N='SubmitSamplesConsent'}
)

# --------------------
# Registry: Edge / IE / Store / App Privacy
# --------------------
$regEdgeIe = @(
  @{S='Edge (Legacy) save passwords';H='HKLM';P='Software\Policies\Microsoft\MicrosoftEdge\Main';N='FormSuggest Passwords'},
  @{S='Edge (Legacy) form autofill';H='HKLM';P='Software\Policies\Microsoft\MicrosoftEdge\Main';N='Use FormSuggest'},
  @{S='Edge (Legacy) SmartScreen';H='HKLM';P='Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter';N='EnabledV9'},
  @{S='IE SmartScreen';H='HKLM';P='Software\Policies\Microsoft\Internet Explorer\Safety';N='EnableSmartScreen'},
  @{S='Store: Disable Store apps';H='HKLM';P='Software\Policies\Microsoft\WindowsStore';N='DisableStoreApps'},
  @{S='Store: Auto download';H='HKLM';P='Software\Policies\Microsoft\WindowsStore';N='AutoDownload'},
  @{S='App Privacy: Allow apps in background';H='HKLM';P='Software\Policies\Microsoft\Windows\AppPrivacy';N='LetAppsRunInBackground'},
  @{S='App Privacy: Access to account info';H='HKLM';P='Software\Policies\Microsoft\Windows\AppPrivacy';N='LetAppsAccessAccountInfo'}
)

# --------------------
# Registry: Capability Access (App permissions)
# --------------------
$capabilities = 'location','microphone','webcam','contacts','email','appointments','phoneCallHistory','chat','radios','bluetoothSync','userAccountInformation','documentsLibrary','picturesLibrary','videosLibrary','musicLibrary','appDiagnostics','cellularData','motion','gazeInput','graphicsCapture'
foreach ($cap in $capabilities) {
  Add-Check -Category 'Registry' -Setting ("App access to $cap") -Hive 'HKCU' -Path "Software\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\$cap" -Name 'Value' -Value (Get-RegValue -Hive 'HKCU' -Path "Software\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\$cap" -Name 'Value')
}

# --------------------
# Registry: Setting Sync groups
# --------------------
$regSync = @(
  @{S='Sync Language';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language';N='Enabled'},
  @{S='Sync Theme (Personalization)';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization';N='Enabled'},
  @{S='Sync Passwords (Credentials)';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials';N='Enabled'},
  @{S='Sync Ease of Access (Accessibility)';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility';N='Enabled'},
  @{S='Sync Other Windows settings';H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows';N='Enabled'}
)

# Add all registry checks to results
foreach ($i in $regCore + $regNetUpd + $regDefender + $regEdgeIe + $regSync) {
  Add-Check -Category 'Registry' -Setting $i.S -Hive $i.H -Path $i.P -Name $i.N -Value (Get-RegValue -Hive $i.H -Path $i.P -Name $i.N)
}

# --------------------
# Services: ALL services on the system
# --------------------
$allServices = Get-Service -Name * -ErrorAction SilentlyContinue
foreach ($svc in $allServices) {
  $value = "Status=$($svc.Status); StartType=$($svc.StartType)"
  Add-Check -Category 'Service' -Setting $svc.DisplayName -Hive '' -Path '' -Name '' -Value $value
}

# --------------------
# Scheduled Tasks: ALL tasks on the system
# --------------------
$allTasks = Get-ScheduledTask -TaskPath * -ErrorAction SilentlyContinue
foreach ($task in $allTasks) {
  $taskPath = "$($task.TaskPath)$($task.TaskName)"
  $state = if ($task.State -eq 'Disabled') { 'Disabled' } else { 'Enabled' }
  Add-Check -Category 'Task' -Setting $taskPath -Hive '' -Path '' -Name '' -Value $state
}

# --------------------
# AppX Apps: ALL AppX packages on the system
# --------------------
$allAppxPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
foreach ($app in $allAppxPackages) {
  $value = "PackageFullName=$($app.PackageFullName)"
  Add-Check -Category 'AppX' -Setting $app.Name -Hive '' -Path '' -Name '' -Value $value
}

# --------------------
# Output
# --------------------
$results | Sort-Object Category, Setting | Format-Table -Property Category, Setting, Name, Value -AutoSize

# Export machine-readable files
$results | ConvertTo-Json -Depth 6 | Out-File -FilePath $JsonOut -Encoding UTF8
$results | Export-Csv -Path $CsvOut -NoTypeInformation -Encoding UTF8

Write-Host "`nSaved JSON: $JsonOut" -ForegroundColor Green
Write-Host "Saved CSV : $CsvOut" -ForegroundColor Green