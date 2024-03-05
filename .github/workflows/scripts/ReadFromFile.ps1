[CmdletBinding()]
param (
  [string] $File,
  [string] $OutputName,
  [string] $OutputPath = $env:GITHUB_OUTPUT
)

$content = Get-Content -Path $File

"$OutputName=$content" >> $OutputPath

Write-Host $content
