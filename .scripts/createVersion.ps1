 
# Sort the filtered tags in version order
$latestTag = git describe --abbrev=0 --tags
if ($latestTag) {
    # Select the highest tag
    $highestTag = [Version] $latestTag.TrimStart("v")
    $major, $minor, $rev = "$($highestTag)".Split('.')

    if (!$rev) {
        $rev = -1
    }
 

    $rev = [int]$rev + 1

    $highestTag = "$($major).$($minor).$($rev)"  
}
Write-Output "newversion=$($highestTag)" >> $Env:GITHUB_OUTPUT

