<#
.SYNOPSIS
  ShutUp10++ Aggressive clone (Apply / Revert). Backup first! Use -DryRun to preview.
.DESCRIPTION
  - Apply: backup (registry keys, hosts, firewall export, services/tasks list), set many privacy registry policies,
           disable/stop services, disable scheduled tasks, remove common Appx bloatware, add hosts blocking,
           create firewall block rules (best-effort by resolving current IPs).
  - Revert: restore backups from the backup folder (registry .reg imports, hosts restore, firewall import, service/task restore best-effort).
.PARAMETER Action
  'Apply' or 'Revert'
.PARAMETER DryRun
  If present, actions are not executed; script only reports.
.EXAMPLE
  .\BachDinhRM_Aggressive_v1.ps1 -Action Apply -DryRun
  .\BachDinhRM_Aggressive_v1.ps1 -Action Apply
  .\BachDinhRM_Aggressive_v1.ps1 -Action Revert
#>

param(
  [ValidateSet('Apply','Revert')][string]$Action = 'Apply',
  [switch]$DryRun
)

# ---------- Helpers ----------
function Write-Log { param($m); $m | Out-File -FilePath $logFile -Append -Encoding utf8; Write-Host $m }
function Check-Admin {
  if (-not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
    throw "Script must be run as Administrator."
  }
}
function Do-Run { param($sb)
  if ($DryRun) { Write-Host "[DRYRUN] $($sb.ToString())" } else { & $sb }
}

# ---------- Setup backup paths ----------
$timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$backupDir = "$env:ProgramData\BachDinhRM_Backup_$timestamp"
if (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory -Force | Out-Null }
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup = Join-Path $backupDir "hosts.bak"
$regBackupDir = Join-Path $backupDir "Registry"
if (-not (Test-Path $regBackupDir)) { New-Item -Path $regBackupDir -ItemType Directory -Force | Out-Null }
$firewallBackup = Join-Path $backupDir "firewall_backup.wfw"
$svcBackupDir = Join-Path $backupDir "Services"
if (-not (Test-Path $svcBackupDir)) { New-Item -Path $svcBackupDir -ItemType Directory -Force | Out-Null }
$taskBackupDir = Join-Path $backupDir "Tasks"
if (-not (Test-Path $taskBackupDir)) { New-Item -Path $taskBackupDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $backupDir "BachDinhRM_log_$timestamp.txt"
"Backup folder: $backupDir" | Out-File -FilePath $logFile -Encoding utf8

# ---------- Lists of targets (expanded compared to earlier) ----------
# Registry policies (many keys used by O&O ShutUp10++)
# Each entry: Hive (HKLM/HKCU), Path (no trailing slash), Name, Value, Type
$regTargets = @(
  # DataCollection & Telemetry
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\DataCollection';N='AllowTelemetry';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection';N='AllowTelemetry';V=0;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo';N='Enabled';V=0;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\InputPersonalization';N='RestrictImplicitTextCollection';V=1;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\InputPersonalization';N='RestrictImplicitInkCollection';V=1;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Microsoft\PolicyManager\default\Experience';N='AllowExperimentation';V=0;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\Privacy';N='TailoredExperiencesWithDiagnosticDataEnabled';V=0;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\Siuf\Rules';N='NumberOfSIUFInPeriod';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\CloudContent';N='DisableWindowsConsumerFeatures';V=1;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\CloudContent';N='DisableSoftLanding';V=1;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\CloudContent';N='DisableWindowsSpotlightFeatures';V=1;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\System';N='AllowActivityFeed';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\System';N='PublishUserActivities';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\System';N='UploadUserActivities';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\WindowsSearch';N='AllowCortana';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\WindowsSearch';N='DisableWebSearch';V=1;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='SystemPaneSuggestionsEnabled';V=0;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='RotatingLockScreenEnabled';V=0;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager';N='SubscribedContent-353694Enabled';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\OneDrive';N='DisableFileSyncNGSC';V=1;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization';N='DODownloadMode';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\Windows Defender\Spynet';N='SpynetReporting';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\Windows Defender\Spynet';N='SubmitSamplesConsent';V=2;T='DWord'}, # 2 = Deny
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\System';N='EnableSmartScreen';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\System';N='ShellSmartScreenLevel';V=0;T='DWord'},

  # Search/Sync/Clipboard/Speech
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\System';N='AllowClipboardHistory';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\System';N='AllowCrossDeviceClipboard';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\Windows Search';N='ConnectedSearchUseWeb';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\Windows Search';N='AllowSearchToUseLocation';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Speech_OneCore\Consent';N='VoiceActivationEnable';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\SearchSettings';N='DisableWebResults';V=1;T='DWord'},

  # Edge Chromium (examples)
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Edge';N='SafeBrowsingEnabled';V=0;T='DWord'},
  @{H='HKLM';P='SOFTWARE\Policies\Microsoft\Edge';N='BrowserSignin';V=0;T='DWord'},

  # Misc / Setting sync groups (example)
  @{H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials';N='Enabled';V=0;T='DWord'},
  @{H='HKCU';P='Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization';N='Enabled';V=0;T='DWord'}
)

# Services to disable (aggressive)
$servicesToDisable = @(
  'DiagTrack','dmwappushservice','WMPNetworkSvc','XblGameSave','XboxNetApiSvc','XboxGipSvc','WerSvc','PcaSvc','DoSvc',
  'lfsvc','WSearch','SysMain','DPS','WaaSMedicSvc','UsoSvc','MapsBroker','RemoteRegistry'
)

# Scheduled tasks to disable (aggressive list - not exhaustive)
$tasksToDisable = @(
  '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
  '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
  '\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask',
  '\Microsoft\Windows\Customer Experience Improvement Program\Uploader',
  '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
  '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
  '\Microsoft\Windows\Application Experience\StartupAppTask',
  '\Microsoft\Windows\Feedback\Siuf\DmClient',
  '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload',
  '\Microsoft\Windows\Autochk\Proxy',
  '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
  '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem',
  '\Microsoft\Windows\Shell\FamilySafetyMonitor',
  '\Microsoft\Windows\Office\OfficeTelemetryAgentLogOn',
  '\Microsoft\Windows\Office\OfficeTelemetryAgentFallBack',
  '\Microsoft\Windows\Diagnosis\Scheduled',
  '\Microsoft\Windows\NetTrace\GatherNetworkInfo',
  '\Microsoft\Windows\PI\Sqm-Tasks',
  '\Microsoft\Windows\SettingSync\NetworkStateChangeTask',
  '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
  '\Microsoft\Windows\Device Information\Device',
  '\Microsoft\Windows\DiskFootprint\Diagnostics',
  '\Microsoft\Windows\Maintenance\WinSAT',
  '\Microsoft\Windows\Shell\FamilySafetyRefresh',
  '\Microsoft\Windows\Subscription\EnableLicenseAcquisition',
  '\Microsoft\Windows\Subscription\LicenseAcquisition',
  '\Microsoft\Windows\WaaSMedic\PerformRemediation',
  '\Microsoft\Windows\UpdateOrchestrator\ScanForUpdates',
  '\Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
)

# Appx packages to remove (modify to taste)
$appxToRemove = @(
  'Microsoft.XboxApp','Microsoft.XboxGamingOverlay','Microsoft.XboxGameCallableUI','Microsoft.XboxIdentityProvider',
  'Microsoft.BingWeather','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftOfficeHub','Microsoft.MinecraftUWP',
  'Microsoft.WindowsFeedbackHub'
)

# Hosts (telemetry domains) - classic list
$telemetryHosts = @(
  'vortex.data.microsoft.com',
  'vortex-win.data.microsoft.com',
  'settings-win.data.microsoft.com',
  'telemetry.microsoft.com',
  'telemetry.appex.bing.net',
  'watson.telemetry.microsoft.com',
  'oca.telemetry.microsoft.com',
  'oca.telemetry.microsoft.com.nsatc.net',
  'v10.vortex-win.data.microsoft.com'
)

# ---------- Utility functions ----------
function Export-RegistryKey {
  param($HiveRoot,$SubPath,$OutFile)
  $full = "$HiveRoot\$SubPath"
  $cmd = "reg export `"$full`" `"$OutFile`" /y"
  if ($DryRun) { Write-Host "[DRYRUN] $cmd" } else {
    cmd.exe /c $cmd | Out-Null
    if (Test-Path $OutFile) { Write-Log "Exported $full -> $OutFile" }
  }
}

function Backup-Hosts {
  if (Test-Path $hostsPath) {
    Copy-Item -Path $hostsPath -Destination $hostsBackup -Force
    Write-Log "Hosts backed up to $hostsBackup"
  }
}

function Add-HostsEntries {
  param($Entries)
  if ($DryRun) { foreach ($h in $Entries) { Write-Host "[DRYRUN] Add hosts -> 0.0.0.0 $h" }; return }
  Backup-Hosts
  foreach ($h in $Entries) {
    $pattern = [regex]::Escape($h)
    if (-not (Select-String -Path $hostsPath -Pattern $pattern -SimpleMatch -Quiet -ErrorAction SilentlyContinue)) {
      $entry = "0.0.0.0`t$h"
      Out-File -FilePath $hostsPath -Encoding ASCII -Append -InputObject $entry
      Write-Log "Added hosts entry: $h"
    } else {
      Write-Log "Hosts already contains: $h"
    }
  }
}

function Restore-Hosts {
  if (Test-Path $hostsBackup) {
    if ($DryRun) { Write-Host "[DRYRUN] Restore hosts from $hostsBackup" } else {
      Copy-Item -Path $hostsBackup -Destination $hostsPath -Force
      Write-Log "Hosts restored from backup."
    }
  } else { Write-Log "No hosts backup found." }
}

function Backup-Firewall {
  $cmd = "netsh advfirewall export `"$firewallBackup`""
  if ($DryRun) { Write-Host "[DRYRUN] $cmd" } else {
    cmd.exe /c $cmd | Out-Null
    Write-Log "Exported firewall rules to $firewallBackup"
  }
}

function Restore-Firewall {
  if (Test-Path $firewallBackup) {
    $cmd = "netsh advfirewall import `"$firewallBackup`""
    if ($DryRun) { Write-Host "[DRYRUN] $cmd" } else {
      cmd.exe /c $cmd | Out-Null
      Write-Log "Imported firewall rules from backup."
    }
  } else { Write-Log "No firewall backup file found." }
}

# Apply registry settings
function Apply-Registry {
  foreach ($r in $regTargets) {
    $hive = $r.H
    $path = $r.P
    $name = $r.N
    $value = $r.V
    $type = $r.T

    # export existing key for backup
    $hiveRoot = if ($hive -eq 'HKLM') { 'HKEY_LOCAL_MACHINE' } else { 'HKEY_CURRENT_USER' }
    $safeName = ($hiveRoot + '_' + ($path -replace '[\\:\*?"<>|]','_'))
    $outReg = Join-Path $regBackupDir ($safeName + ".reg")
    Export-RegistryKey -HiveRoot $hiveRoot -SubPath $path -OutFile $outReg

    # Create registry path if missing and set value
    $psPath = "${hive}:\$path"
    # Use New-Item with -Force if not exist
    if ($DryRun) {
      Write-Host "[DRYRUN] Ensure path: $psPath ; Set $name = $value ($type)"
    } else {
      if (-not (Test-Path $psPath)) { New-Item -Path $psPath -Force | Out-Null }
      # Convert type to appropriate Set-ItemProperty behaviour
      if ($type -eq 'DWord') {
        $v = [int]$value
      } else { $v = $value }
      Set-ItemProperty -Path $psPath -Name $name -Value $v -Force -ErrorAction SilentlyContinue
      Write-Log "Set $psPath\$name = $value"
    }
  }
}

# Revert registry (import backups)
function Revert-Registry {
  $files = Get-ChildItem -Path $regBackupDir -Filter *.reg -ErrorAction SilentlyContinue
  if (-not $files) { Write-Log "No registry backups found." ; return }
  foreach ($f in $files) {
    $cmd = "reg import `"$($f.FullName)`""
    if ($DryRun) { Write-Host "[DRYRUN] $cmd" } else { cmd.exe /c $cmd | Out-Null; Write-Log "Imported $($f.Name)" }
  }
}

# Services
function Disable-Services {
  foreach ($s in $servicesToDisable) {
    try {
      $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
      if ($svc) {
        $bak = Join-Path $svcBackupDir ("service_$s.json")
        $svc | Select-Object Name,DisplayName,Status,StartType | ConvertTo-Json | Out-File $bak -Encoding utf8
        Write-Log "Backed up service $s -> $bak"
        if (-not $DryRun) {
          Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
          Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
        } else {
          Write-Host "[DRYRUN] Stop-Service -Name $s ; Set-Service -Name $s -StartupType Disabled"
        }
      } else { Write-Log "Service $s not present." }
    } catch { Write-Log "Error disabling $s : $_" }
  }
}

function Revert-Services {
  $files = Get-ChildItem -Path $svcBackupDir -Filter service_*.json -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    $obj = Get-Content $f.FullName | ConvertFrom-Json
    $name = $obj.Name
    $startType = $obj.StartType
    if ($DryRun) { Write-Host "[DRYRUN] Set-Service -Name $name -StartupType $startType ; Start-Service if was Running" } else {
      try {
        Set-Service -Name $name -StartupType $startType -ErrorAction SilentlyContinue
        if ($obj.Status -eq 'Running') { Start-Service -Name $name -ErrorAction SilentlyContinue }
        Write-Log "Restored service $name -> StartType $startType ; Running=$($obj.Status -eq 'Running')"
      } catch { Write-Log "Failed to restore service $name : $_" }
    }
  }
}

# Tasks
function Disable-Tasks {
  foreach ($t in $tasksToDisable) {
    try {
      $parent = Split-Path $t -Parent
      $leaf = Split-Path $t -Leaf
      # backup via schtasks /Query /TN "<task>" /XML > file
      $safe = ($t -replace '[\\:]', '_')
      $out = Join-Path $taskBackupDir ("task" + $safe + ".xml")
      $cmdExp = "schtasks /Query /TN `"$t`" /XML > `"$out`""
      if ($DryRun) { Write-Host "[DRYRUN] $cmdExp ; Disable-ScheduledTask -TaskPath $parent -TaskName $leaf" } else {
        cmd.exe /c $cmdExp | Out-Null
        Disable-ScheduledTask -TaskPath $parent -TaskName $leaf -ErrorAction SilentlyContinue
        Write-Log "Disabled task $t (backup: $out)"
      }
    } catch { Write-Log "Task $t not found or error: $_" }
  }
}

function Revert-Tasks {
  $xmls = Get-ChildItem -Path $taskBackupDir -Filter *.xml -ErrorAction SilentlyContinue
  foreach ($x in $xmls) {
    Write-Log "Task backup: $($x.FullName). To restore: schtasks /Create /TN <name> /XML `"$($x.FullName)`" (manual/automatic depending on task)."
  }
}

# Appx removal
function Remove-Appx {
  foreach ($a in $appxToRemove) {
    $pkgs = Get-AppxPackage -Name "*$a*" -AllUsers -ErrorAction SilentlyContinue
    foreach ($p in $pkgs) {
      $bak = Join-Path $backupDir ("appx_" + $p.Name + ".json")
      $p | Select-Object Name,PackageFullName,PackageFamilyName | ConvertTo-Json | Out-File $bak -Encoding utf8
      Write-Log "Backed up package info $($p.Name) -> $bak"
      if ($DryRun) { Write-Host "[DRYRUN] Remove-AppxPackage -Package $($p.PackageFullName) -AllUsers" } else {
        try {
          Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction SilentlyContinue
          # remove provisioned package
          $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$a*" } -ErrorAction SilentlyContinue
          foreach ($pr in $prov) {
            Remove-AppxProvisionedPackage -Online -PackageName $pr.PackageName -ErrorAction SilentlyContinue
          }
          Write-Log "Removed package $($p.Name)"
        } catch { Write-Log "Failed remove package $($p.Name) : $_" }
      }
    }
  }
}

# Firewall block by resolving current IPs (best-effort)
function Add-Firewall-Blocks {
  $rulePrefix = "BachDinhRM_BlockTelemetry_"
  foreach ($h in $telemetryHosts) {
    try {
      if ($DryRun) { 
        Write-Host "[DRYRUN] Resolve-DnsName $h ; then New-NetFirewallRule -RemoteAddress <ips> -Action Block" 
        continue 
      }
      $ips = (Resolve-DnsName -Name $h -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress } | Select-Object -ExpandProperty IPAddress -Unique)
      if ($ips) {
        foreach ($ip in $ips) {
          $ruleName = $rulePrefix + $h + "_" + $ip.ToString()
          # create outbound block rule
          New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block -RemoteAddress $ip -Description "Block telemetry host $h" -ErrorAction SilentlyContinue
          Write-Log "Firewall block rule created: $ruleName -> $ip"
        }
      } else { 
        Write-Log "Could not resolve $h to IPs (skipping firewall rule)" 
      }
    } catch { 
      Write-Log "Firewall block failed for $h : $_" 
    }
  }
}


function Remove-BachDinhRM-FirewallRules {
  Get-NetFirewallRule -DisplayName "BachDinhRM_BlockTelemetry_*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
  Write-Log "Removed firewall rules added by BachDinhRM (if any)."
}

# ---------- Main sequences ----------
function Do-Apply {
  Write-Log "=== APPLY START $(Get-Date) ==="
  # Checkpoint System Restore (best-effort)
  try {
    if (-not $DryRun) {
      if (Get-Command -Name Checkpoint-Computer -ErrorAction SilentlyContinue) {
        Checkpoint-Computer -Description "BachDinhRM_Backup_$timestamp" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
        Write-Log "Created System Restore point (if enabled)."
      } else { Write-Log "Checkpoint-Computer not available on this SKU." }
    } else { Write-Host "[DRYRUN] Create System Restore point (if supported)" }
  } catch { Write-Log "System restore point creation failed or not supported: $_" }

  # 1. Backup firewall
  Backup-Firewall

  # 2. Export registry keys listed
  foreach ($r in $regTargets) {
    $hiveRoot = if ($r.H -eq 'HKLM') { 'HKEY_LOCAL_MACHINE' } else { 'HKEY_CURRENT_USER' }
    $sub = $r.P
    $out = Join-Path $regBackupDir (($hiveRoot + '_' + ($sub -replace '[\\:\*?"<>|]','_')) + ".reg")
    Export-RegistryKey -HiveRoot $hiveRoot -SubPath $sub -OutFile $out
  }

  # 3. Apply registry changes
  Apply-Registry

  # 4. Disable services
  Disable-Services

  # 5. Disable scheduled tasks
  Disable-Tasks

  # 6. Remove Appx
  Remove-Appx

  # 7. Hosts blocking
  Add-HostsEntries -Entries $telemetryHosts

  # 8. Firewall blocking (resolve IPs and add outbound block rules)
  Add-Firewall-Blocks

  Write-Log "=== APPLY END $(Get-Date) ==="
}

function Do-Revert {
  Write-Log "=== REVERT START $(Get-Date) ==="
  # 1. Restore firewall
  Restore-Firewall
  Remove-BachDinhRM-FirewallRules

  # 2. Restore registry (import backup .reg files)
  Revert-Registry

  # 3. Revert services
  Revert-Services

  # 4. Revert tasks (manual instructions)
  Revert-Tasks

  # 5. Restore hosts
  Restore-Hosts

  Write-Log "=== REVERT END $(Get-Date) ==="
}

# ---------- Run ----------
try {
  Check-Admin
  Write-Log "Action: $Action ; DryRun: $DryRun ; BackupDir: $backupDir"
  if ($Action -eq 'Apply') { Do-Apply } else { Do-Revert }
  Write-Host "Done. Backup & logs: $backupDir" -ForegroundColor Green
  Write-Host "Log file: $logFile" -ForegroundColor Green
} catch {
  Write-Log "ERROR: $_"
  throw
}
