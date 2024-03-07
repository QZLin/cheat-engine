[CmdletBinding()]
param (
  [string] $RegPath,
  [string] $OutputName,
  [string] $OutputPath = $env:GITHUB_OUTPUT
)

$found = Test-Path -Path "Registry::$RegPath"

"$OutputName=$([int]$found)" >> $OutputPath

Write-Host [int]$found
