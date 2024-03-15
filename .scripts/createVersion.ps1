$tags = git tag -l
# Filter tags matching the pattern "vX.Y"
$filteredTags = $tags -match '^v\d+\.\d+'

# Sort the filtered tags in version order
$sortedTags = $filteredTags | Sort-Object { [Version]$_.TrimStart("v") } -Descending
$highestTag  = "v1.0.0"
if ($sortedTags) {
    # Select the highest tag
    $highestTag = $sortedTags[0]
 
}

Write-Host "newVersion=$($highestTag.TrimStart("v"))" | Out-File -FilePath $Env:GITHUB_OUTPUT -Encoding utf8 -Append

