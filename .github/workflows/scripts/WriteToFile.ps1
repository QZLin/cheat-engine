[CmdletBinding()]
param (
  [string] $Var,
  [string] $OutputPath
)

$Var | Out-File -NoNewline -FilePath $OutputPath
