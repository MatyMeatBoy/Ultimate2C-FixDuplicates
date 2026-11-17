param([switch]$Package)
$ErrorActionPreference='Stop'
$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if(-not (Test-Path $compiler)) {
    $compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
$source=Join-Path $PSScriptRoot 'src'
$dist=Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$out=Join-Path $dist 'Ultimate2CFix.exe'
& $compiler /nologo /target:winexe /platform:anycpu /optimize+ /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "/win32manifest:$source\app.manifest" "/resource:$source\Fix.ps1,Fix.ps1" "/out:$out" "$source\App.cs" "$source\AssemblyInfo.cs"
if($LASTEXITCODE -ne 0) { throw 'Compilation failed.' }
if($Package) {
    Copy-Item -LiteralPath "$PSScriptRoot\README.md","$PSScriptRoot\LICENSE" -Destination $dist -Force
    Compress-Archive -LiteralPath $out,"$dist\README.md","$dist\LICENSE" -DestinationPath "$dist\Ultimate2C-FixDuplicates-v0.1-portable.zip" -Force
    $assets=@($out,"$dist\Ultimate2C-FixDuplicates-v0.1-portable.zip")
    $hashes=foreach($asset in $assets) {
        $hash=Get-FileHash -LiteralPath $asset -Algorithm SHA256
        $hash.Hash.ToLowerInvariant()+'  '+[IO.Path]::GetFileName($asset)
    }
    $hashes | Set-Content -LiteralPath "$dist\SHA256SUMS.txt" -Encoding ASCII
}
Get-Item $out | Select-Object FullName,Length
