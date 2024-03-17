param (
    [Parameter(Mandatory=$false)]
    [string]$targetDirectory
)
function Update-JsonProperties($sourceJson, $targetJson, $currentPath = "") {

    $x = $sourceJson | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    $y= $targetJson | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    $keys = $x + $y | Select-Object -Unique
    Write-Host $keys
    $keys | ForEach-Object {
        $key = $_
        $value = $sourceJson.$key
        Write-Host "Updating properties $($_)..."

        # Warn is the property is not in the source json JSON
        if ($null -eq $sourceJson.$key) {

            Write-Warning "Warning: Property $($currentPath).$key seems to be deprecated. Consider removing it from your configuration. It will not longer be used."
        }
        if ($null -eq $targetJson.$key) {
            $targetJson | Add-Member -MemberType NoteProperty -Name $key -Value $value
        }
        elseif ($value -is [psobject] -and $targetJson.$key -is [psobject]) {
            
            $targetJson.$key = Update-JsonProperties $value $targetJson.$key -currentPath "$currentPath.$key".TrimStart('.')       
        }
        
    }
    return $targetJson
}

Write-Host "This will install or update the SWBF Classic (2004) / SWBF Classic Collection"

# Check if the target directory is null, empty, or does not exist
if ([string]::IsNullOrEmpty($targetDirectory) ) {
    do {
        # Prompt the user for a new valid target directory
        $targetDirectory = Read-Host -Prompt "Enter a valid target directory to install or update"
    } while ([string]::IsNullOrEmpty($targetDirectory))
}
# Inform the user to stop the server and launcher
Write-Host "Please make sure to stop the server and launcher before installing or updating."
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Prompt the user to confirm the target directory
$confirmMessage = "Is the target directory '$targetDirectory' correct? (Y/N)"
$confirmResponse = Read-Host -Prompt $confirmMessage

# Check if the user confirmed the target directory
if ($confirmResponse -ne "Y" -and $confirmResponse -ne "y") {
    Write-Host "Operation cancelled. Please provide the correct target directory."
    return
}

$sourceDirectory = Get-Location
Write-Host "Source directory: $sourceDirectory"

# Check if the target directory exists, if not, create it
if (-not (Test-Path -Path $targetDirectory)) {
    New-Item -ItemType Directory -Path $targetDirectory | Out-Null
    Write-Host "Target directory created: $targetDirectory"
}

# Copy launcher.ps1 to the target directory
Copy-Item -Path "$sourceDirectory\launcher.ps1" -Destination $targetDirectory -Force
Write-Host "launcher.ps1 copied to the target directory: $targetDirectory"

# Check if launcher.config.json exists in the target directory
$targetConfigFile = Join-Path -Path $targetDirectory -ChildPath "launcher.config.json"
if (Test-Path -Path $targetConfigFile) {
    # Read the source and target JSON files
    $sourceJson = Get-Content -Path "$sourceDirectory\launcher.config.json" | ConvertFrom-Json -Depth 10
    $targetJson = Get-Content -Path $targetConfigFile | ConvertFrom-Json -Depth 10
    
    Write-Host "Updating launcher config with new properties..."
    # Update the target JSON with the source JSON properties
    $updatedJson = Update-JsonProperties -sourceJson $sourceJson -targetJson $targetJson
    $updatedJson | ConvertTo-Json -Depth 10 | Set-Content $targetConfigFile

    Write-Host "launcher.config.json updated in the target directory: $targetDirectory"
    Write-Information "Your configuration was only updated not changed."
}
else {
    # Copy launcher.config.json to the target directory
    Copy-Item -Path "$sourceDirectory\launcher.config.json" -Destination $targetDirectory -Force
    Write-Host "launcher.config.json copied to the target directory: $targetDirectory"
}

# Check if maps.config exists in the target directory
$targetMapsConfigFile = Join-Path -Path $targetDirectory -ChildPath "maps.config"
if (-not (Test-Path -Path $targetMapsConfigFile)) {
    # Copy maps.config to the target directory
    Copy-Item -Path "$sourceDirectory\maps.config" -Destination $targetDirectory -Force
    Write-Host "maps.config copied to the target directory: $targetDirectory"
}

# Check if server.config exists in the target directory
$targetServerConfigFile = Join-Path -Path $targetDirectory -ChildPath "server.config"
if (-not (Test-Path -Path $targetServerConfigFile)) {
    # Copy server.config to the target directory
    Copy-Item -Path "$sourceDirectory\server.config" -Destination $targetDirectory -Force
    Write-Host "server.config copied to the target directory: $targetDirectory"
}


Write-Host "Installation or update completed."
Write-Host "Over and out.  Goodbye!"

