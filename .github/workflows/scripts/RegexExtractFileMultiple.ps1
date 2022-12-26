[CmdletBinding()]
param (
  [string] $File,
  [string] $CleanupRegex = "",
  [string] $Regex,
  [string] $OutputName,
  [string] $OutputPath = $env:GITHUB_OUTPUT
)

$content = Get-Content -Path $File

if ($CleanupRegex.Length -gt 0) {
  $content = [regex]::Replace($content, $CleanupRegex, "")
}

$found = [regex]::Matches($content, $Regex)

$outputList = [System.Collections.ArrayList]@()

foreach ($match in $found) {
  $outputList.Add($match.Value)
}

$output = $outputList -join "{0}"

"$OutputName=$output" >> $OutputPath

Write-Host $output
