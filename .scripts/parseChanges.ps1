param (
    [Parameter(Mandatory=$true)]
    [string]$version,
    [string]$changelogFile = ".\CHANGELOG.md"
)
 
$regex = "(?s)$version(.*?)###"
$changelog = Get-Content -Path $changelogFile -Raw
$changes = ""

if ($changelog -match $regex) {
    $changes = $matches[1].Trim()
    
} 

Write-Output "changes=$($changes)" >> $Env:GITHUB_OUTPUT