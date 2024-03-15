param (
    [Parameter(Mandatory=$false)]
    [string]$targetDirectory
)
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
    $sourceJson = Get-Content -Path "$sourceDirectory\launcher.config.json" -Raw | ConvertFrom-Json
    $targetJson = Get-Content -Path $targetConfigFile -Raw | ConvertFrom-Json

    # Add properties from source JSON that don't exist in target JSON
    $sourceJson.PSObject.Properties | ForEach-Object {
        $propertyName = $_.Name
        if (-not $targetJson.PSObject.Properties.Name.Contains($propertyName)) {
            $targetJson | Add-Member -MemberType NoteProperty -Name $propertyName -Value $_.Value
        }
    }

    # Convert the updated target JSON back to string and overwrite the target file
    $updatedJsonString = $targetJson | ConvertTo-Json -Depth 10
    $updatedJsonString | Set-Content -Path $targetConfigFile -Force
    Write-Host "launcher.config.json updated in the target directory: $targetDirectory"
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

