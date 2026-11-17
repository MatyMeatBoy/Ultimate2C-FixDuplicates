$ErrorActionPreference='Stop'
. "$PSScriptRoot\..\src\Fix.ps1" -LibraryOnly
# These cases catch overbroad selection that would disable the real controller,
# other products, or arbitrary devices sharing part of a hardware ID.
$cases=@(
 @('HID\VID_2DC8&PID_310A&MI_01&COL02\9&USB&0&0001',$true),
 @('HID\VID_2DC8&PID_310A&MI_02\9&RECEIVER&0&0000',$true),
 @('hid\vid_2dc8&pid_310a&mi_02\newport',$true),
 @('HID\VID_2DC8&PID_310A&IG_00\GAMEPAD',$false),
 @('HID\VID_2DC8&PID_310A&MI_01&COL01\KEYBOARD',$false),
 @('HID\VID_2DC8&PID_310A&MI_01&COL03\MOUSE',$false),
 @('USB\VID_2DC8&PID_310A&MI_02\PARENT',$false),
 @('HID\VID_0079&PID_0006\N64',$false),
 @('HID\VID_2DC8&PID_9999&MI_02\OTHER',$false),
 @('HID\VID_2DC8&PID_310A&MI_020\OTHER',$false),
 @('HID\VID_2DC8&PID_310A&MI_01&COL020\OTHER',$false),
 @('HID\VID_2DC8&PID_310A&MI_02\',$false),
 @('',$false)
)
$failures=0
foreach($case in $cases) {
 $actual=Test-Auxiliary $case[0]
 if($actual -ne $case[1]) { Write-Host "FAIL: $($case[0]) expected=$($case[1]) actual=$actual"; $failures++ }
}
if($failures) { throw "$failures selection tests failed" }
Write-Host "$($cases.Count) selection tests passed"
