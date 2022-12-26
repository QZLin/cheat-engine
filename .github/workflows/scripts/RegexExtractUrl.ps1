[CmdletBinding()]
param (
  [string] $Url,
  [string] $Regex,
  [string] $RegexGroup,
  [string] $OutputName,
  [string] $OutputPath = $env:GITHUB_OUTPUT
)

$ProgressPreference = 'SilentlyContinue'

[string] $resp = Invoke-WebRequest -Uri $Url

$match = [regex]::Match($resp, $Regex).Groups[$RegexGroup].Value

"$OutputName=$match" >> $OutputPath

Write-Host $match
