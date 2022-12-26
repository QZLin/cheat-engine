[CmdletBinding()]
param (
  [string] $File,
  [string] $CleanupRegex = "",
  [string] $Regex,
  [string] $RegexGroup,
  [string] $OutputName,
  [string] $OutputPath = $env:GITHUB_OUTPUT
)

$content = Get-Content -Path $File

if ($CleanupRegex.Length -gt 0) {
  $content = [regex]::Replace($content, $CleanupRegex, "")
}

$match = [regex]::Match($content, $Regex).Groups[$RegexGroup].Value

"$OutputName=$match" >> $OutputPath

Write-Host $match
