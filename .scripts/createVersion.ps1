$tags = git tag -l
# Filter tags matching the pattern "vX.Y"
$filteredTags = $tags -match '^v\d+\.\d+'

# Sort the filtered tags in version order
$sortedTags = $filteredTags | Sort-Object { [Version]$_.TrimStart("v") } -Descending
$highestTag = [Version]"1.0.0"
if ($sortedTags) {
    # Select the highest tag
    $highestTag = [Version] $sortedTags[0].TrimStart("v")
    $major, $minor, $rev = "$($highestTag)".Split('.')

    if (!$rev) {
        $rev = -1
    }
 

    $rev = [int]$rev + 1

    $highestTag = "$($major).$($minor).$($rev)"  
}

 
Write-Host "newVersion=$($highestTag)" | Out-File -FilePath $Env:GITHUB_OUTPUT -Encoding utf8 -Append

