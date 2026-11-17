param([ValidateSet('Scan','Repair','Restore')][string]$Action='Scan',[string]$OutputFile,[switch]$LibraryOnly)
$ErrorActionPreference='Stop'
function Test-Auxiliary([string]$InstanceId) {
    return $InstanceId -match '^HID\\VID_2DC8&PID_310A&(?:MI_01&COL02|MI_02)\\[^\\]+$'
}
if ($LibraryOnly) { return }

function Invoke-Fix {
    if ($Action -ne 'Scan') {
        $principal=[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Administrator permission is required to repair or restore.'
        }
    }
    $all=@(Get-PnpDevice -PresentOnly -ErrorAction Stop)
    $pads=@($all | Where-Object { $_.InstanceId -match '^USB\\VID_2DC8&PID_310A\\' })
    if(-not $pads.Count) { throw 'No Ultimate 2C was found. Connect the USB cable or 2.4G receiver and check again.' }
    'Ultimate 2C detected: ' + $pads.Count + ' connection(s).'
    $targets=@($all | Where-Object { Test-Auxiliary $_.InstanceId })
    if(-not $targets.Count) { throw 'No known auxiliary interfaces were found. No devices were changed.' }
    $changed=New-Object 'System.Collections.Generic.List[string]'
    try {
        foreach($d in $targets) {
            $id=$d.InstanceId
            $problem=Get-PnpDeviceProperty -InstanceId $id -KeyName DEVPKEY_Device_ProblemCode -ErrorAction Stop
            $disabled=($problem.Data -eq 22)
            $kind=if($id -match 'MI_02\\'){'8BitDo private interface'}else{'Consumer controls'}
            if($Action -eq 'Repair' -and -not $disabled) {
                if($problem.Data -ne 0) { throw "The interface has a pre-existing error ($($problem.Data)): $id" }
                Disable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop
                $changed.Add($id)
            } elseif($Action -eq 'Restore' -and $disabled) {
                Enable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop
                $changed.Add($id)
            }
            $now=Get-PnpDeviceProperty -InstanceId $id -KeyName DEVPKEY_Device_ProblemCode -ErrorAction Stop
            if($Action -eq 'Repair' -and $now.Data -ne 22) { throw "Could not verify that the interface was disabled: $id" }
            if($Action -eq 'Restore' -and $now.Data -ne 0) { throw "Could not verify the restoration: $id" }
            $state=if($now.Data -eq 22){'DISABLED'}elseif($now.Data -eq 0){'ENABLED'}else{'ERROR '+$now.Data}
            "$kind : $state"
            "  $id"
        }
    } catch {
        $originalError=$_
        foreach($id in $changed) {
            try {
                if($Action -eq 'Repair') { Enable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop }
                elseif($Action -eq 'Restore') { Disable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop }
                "Change rolled back: $id"
            } catch { "Could not roll back automatically: $id. Use Restore or Device Manager." }
        }
        throw $originalError
    }
    ''
    if($Action -eq 'Repair') {
        'REPAIR VERIFIED: auxiliary interfaces disabled.'
        'Close and reopen joy.cpl or your game to refresh the device list.'
    } elseif($Action -eq 'Restore') {
        'RESTORE VERIFIED: auxiliary interfaces enabled.'
    } else { 'Check complete. No devices were changed.' }
    'The gamepad, keyboard, and mouse interfaces are not changed.'
}

$lines=New-Object 'System.Collections.Generic.List[string]'
$code=0
try { Invoke-Fix | ForEach-Object { $lines.Add([string]$_) } }
catch { $lines.Add('ERROR: '+$_.Exception.Message); $code=1 }
$text=$lines -join [Environment]::NewLine
if($OutputFile) { [IO.File]::WriteAllText($OutputFile,$text,[Text.Encoding]::UTF8) }
else { Write-Output $text }
exit $code
