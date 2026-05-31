<#
.SYNOPSIS
  Syncs the canonical skill (plugins/interview/skills/interview) down to the
  manual-install copy (skill/).

.DESCRIPTION
  plugins/interview/skills/interview is the SINGLE SOURCE OF TRUTH. The skill/
  folder exists only so users can copy the skill into their own project without
  installing the plugin (see README "Option 2"). Edit the plugins/ copy, then run
  this script to regenerate skill/. Run with -Check in CI to fail on drift.

.EXAMPLE
  ./scripts/sync-skill.ps1            # copy plugins/ -> skill/
  ./scripts/sync-skill.ps1 -Check     # exit 1 if skill/ is out of sync (no copy)
#>
[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$root   = Split-Path $PSScriptRoot -Parent
$canon  = Join-Path $root 'plugins/interview/skills/interview'
$mirror = Join-Path $root 'skill'

$files = @(
  'SKILL.md',
  'references/questioning-examples.md',
  'examples/order-cancellation-spec.md'
)

$drift = $false
foreach ($f in $files) {
  $src = Join-Path $canon $f
  $dst = Join-Path $mirror $f
  $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
  $dstHash = if (Test-Path $dst) { (Get-FileHash $dst -Algorithm SHA256).Hash } else { '' }

  if ($srcHash -eq $dstHash) {
    Write-Host "OK    $f"
    continue
  }

  if ($Check) {
    Write-Host "DRIFT $f"
    $drift = $true
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    Copy-Item $src $dst -Force
    Write-Host "SYNC  $f"
  }
}

if ($Check -and $drift) {
  Write-Error "skill/ is out of sync with plugins/. Run ./scripts/sync-skill.ps1 and commit."
  exit 1
}
