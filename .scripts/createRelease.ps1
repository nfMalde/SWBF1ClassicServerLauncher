param (
    [Parameter(Mandatory=$true)]
    [string]$version,
    [string]$outputFolder = ".\release"
)

# Rest of your code goes here

 
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force
}

$zipName = "SWBF1ClassicServerLauncher_$version.zip"
$zipPath = Join-Path -Path $outputFolder -ChildPath $zipName

$srcFolder = "src"
$readmeFile = "readme.md"
$subfolderName = "SWBF1ClassicServerLauncher_$version"
$subfolderPath = Join-Path -Path $outputFolder -ChildPath $subfolderName

New-Item -ItemType Directory -Path $subfolderPath -Force

# Copy all files from src to $subfolderPath
Copy-Item -Path $srcFolder\* -Destination $subfolderPath -Recurse -Force
Copy-Item -Path $readmeFile -Destination $subfolderPath -Force

Compress-Archive -Path $subfolderPath -DestinationPath $zipPath -Force