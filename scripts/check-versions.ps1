<#
.SYNOPSIS
  Verifies the plugin version is identical everywhere it is declared.

.DESCRIPTION
  The version lives in three places that must match:
    - plugins/interview/.claude-plugin/plugin.json      ("version")
    - .claude-plugin/marketplace.json                   (plugins[name=interview].version)
    - plugins/interview/skills/interview/SKILL.md       (frontmatter metadata.version)
  Exits 1 if any of them differ.

.EXAMPLE
  ./scripts/check-versions.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

$pluginJson = Get-Content (Join-Path $root 'plugins/interview/.claude-plugin/plugin.json') -Raw | ConvertFrom-Json
$marketJson = Get-Content (Join-Path $root '.claude-plugin/marketplace.json') -Raw | ConvertFrom-Json
$skillMd    = Get-Content (Join-Path $root 'plugins/interview/skills/interview/SKILL.md') -Raw

$marketEntry = $marketJson.plugins | Where-Object { $_.name -eq 'interview' }
$skillMatch  = [regex]::Match($skillMd, '(?m)^\s+version:\s*([^\s]+)\s*$')

$versions = [ordered]@{
  'plugin.json'      = $pluginJson.version
  'marketplace.json' = $marketEntry.version
  'SKILL.md'         = if ($skillMatch.Success) { $skillMatch.Groups[1].Value } else { '' }
}

foreach ($k in $versions.Keys) { Write-Host ("{0,-17} {1}" -f $k, $versions[$k]) }

$distinct = @($versions.Values | Sort-Object -Unique)
if ($distinct.Count -ne 1 -or [string]::IsNullOrEmpty($distinct[0])) {
  Write-Error "Plugin versions do not match. Update all three files to the same version."
  exit 1
}
Write-Host "OK    all versions are $($distinct[0])"
