<#
.SYNOPSIS
    Export each printable part of the water-sensor sun hat to its own STL.

.DESCRIPTION
    Runs OpenSCAD headlessly once per `part` value ("ring", "arm", "umbrella"),
    producing <model>-<part>.stl next to the .scad file. Re-run after any edit
    to the model to refresh the print files.

.EXAMPLE
    .\export-stls.ps1 -Verbose
#>
[CmdletBinding()]
param(
    # The model file. Defaults to the .scad sitting beside this script.
    [string]$Scad = (Join-Path $PSScriptRoot 'water-sensor-sun-hat.scad'),

    # OpenSCAD executable.
    [string]$OpenScad = 'C:\Program Files\OpenSCAD\openscad.exe',

    # Output directory for the STLs.
    [string]$OutDir = $PSScriptRoot,

    # The parts to export (must match the `part` selector in the .scad).
    [string[]]$Parts = @('ring', 'arm', 'umbrella')
)

if (-not (Test-Path $OpenScad)) { Write-Error "OpenSCAD not found at '$OpenScad'."; return }
if (-not (Test-Path $Scad))     { Write-Error "Model not found at '$Scad'.";       return }

$base = [System.IO.Path]::GetFileNameWithoutExtension($Scad)
$ok   = 0

foreach ($p in $Parts) {
    $out    = Join-Path $OutDir "$base-$p.stl"
    $define = 'part="{0}"' -f $p          # OpenSCAD -D arg, e.g. part="ring"

    Write-Verbose "Exporting part '$p' -> $out"
    if (Test-Path $out) { Remove-Item $out -Force }

    # OpenSCAD prints progress to stderr even on success; capture it and judge
    # success by whether the STL was actually produced (its exit code is flaky).
    $log = & $OpenScad -o $out -D $define $Scad 2>&1 | Out-String
    Write-Verbose $log

    if (Test-Path $out) {
        $kb = [math]::Round((Get-Item $out).Length / 1KB, 1)
        Write-Host ("  {0,-34} {1,8} KB" -f (Split-Path $out -Leaf), $kb) -ForegroundColor Cyan
        $ok++
    } else {
        Write-Error "OpenSCAD did not produce '$out'.`n$log"
    }
}

Write-Host "Exported $ok of $($Parts.Count) part(s) to $OutDir" -ForegroundColor Green
