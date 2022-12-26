[CmdletBinding()]
param (
  [string] $InstallerFile,
  [string] $Arguments = ""
)

try {
  Start-Process $InstallerFile -ArgumentList $Arguments -Wait
}
catch {
  Write-Output "$_"
}
