# Change detections (dont change)
function Load-SvrArguments {
    $filePath = Join-Path -Path (Get-Location) -ChildPath "server.config"
    if (Test-Path -Path $filePath) {
        $content = Get-Content -Path $filePath
        return $content.Trim()
    }
    else {
        Write-Host "File $filePath does not exist."
        return $null
    }
}

function Load-Maps {
    $filePath = Join-Path -Path (Get-Location) -ChildPath "maps.config"
    if (Test-Path -Path $filePath) {
        $content = Get-Content -Path $filePath
        return $content.Trim()
    }
    else {
        Write-Host "File $filePath does not exist."
        return $null
    }
}

function Get-Servername($arguments) {
    return $arguments | Select-String -Pattern '/gamename (\S+)' | ForEach-Object { $_.Matches.Groups[1].Value }
}


$configPath = Join-Path -Path (Get-Location) -ChildPath "launcher.config.json";
$configFile =  Get-Content -Path $configPath | ConvertFrom-Json

function SendConfigToHost($obj, $prefix = "") {
    foreach ($property in $obj.PSObject.Properties) {
        $key = $prefix + $property.Name
        $value = $property.Value

        if ($value -is [System.Management.Automation.PSCustomObject]) {
            SendConfigToHost $value "$key."
        }
        else {
            Write-Host "$key = $value"
        }
    }
}

function Get-PropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Object,
        
        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    # Check if the property exists in the object
    if ($Object.PSObject.Properties.Match($PropertyName)) {
        # Get the value of the specified property
        return $Object.$PropertyName
    } else {
        Write-Host "Property '$PropertyName' does not exist in the object."
        return $null
    }
}
function Get-GameConfig($game) {
   $gameConfigEntry = $configFile.gameConfigs.PSObject.Properties | Where-Object { $_.Name -eq "$($game)" } 
    
   return $gameConfigEntry[0].Value
}

Write-Host "Loaded following launcher configuration:`n"
SendConfigToHost $configFile
Write-Host "****************************************`n"
function Send-DiscordMessage($message) {
    Write-Host "Sending message to Discord: >$($message)<..."
    if ($configFile.launchOptions.discord.enabled -eq $false) {
        Write-Host "Discord notifications are disabled. Skipping message."
        return
    }

    $hookUri = "$($configFile.launchOptions.discord.webookUrl)"

    $params = @{"content" = $message; }
        
    Invoke-WebRequest -Uri $hookUri -Method POST -Body $params
}

$textTemplates = @{
    "serverCrash"         = "Server {serverName}` crashed will recover it in {recoverSeconds} seconds."
    "serverRecovered"     = "Server {serverName}` recovered from crash."
    "serverRestart"       = "Server {serverName}` will restart in exact {minutesTillRestart} Minutes (@{restartTime} {timeZone})!"
    "configChange"        = "Server {serverName}` config has been changed: `r`n`r`n{changes}`r`nChanges apply at next restart."
    "serverRestartingNow" = "Server {serverName}` is restarting now."
}

if ($configFile.launchOptions.discord.textTemplates) {
    foreach ($key in $configFile.launchOptions.discord.textTemplates.PSObject.Properties) {
        $textTemplates[$key.Name] = $key.Value
        Write-Host "Setting text template for $($key.Name) to $($key.Value)"
    }
    
}
 

$skipArguments = @('adminpw', 'win', 'norender')
$serverName = ""
$serverExe = Join-Path -Path $configFile.steamFolder  -ChildPath "steam.exe"
Write-Host "Steam Exe: $($serverExe)"

$gameConfig = Get-GameConfig -game $configFile.launchOptions.game

$appID = ""
$gameFolderSuffix = $gameConfig.gameFolderSuffix

$executable = $gameConfig.executable
$appID = $gameConfig.appID
Write-Host "App ID: $appID"
Write-Host "Executable: $executable"
Write-Host "Game Folder Suffix: $gameFolderSuffix"

$gameFolderSuffix = $gameFolderSuffix.TrimEnd("\")   

$serverArguments = "" | Load-SvrArguments
$changedServerArguments = "" | Load-SvrArguments
$currentMaps = "" | Load-Maps
$newMaps = "" | Load-Maps

$serverName = Get-Servername -arguments $serverArguments
Write-Host "Server Name: $serverName"
$mapNames = @{
    "bes1a"  = "Bespin: Platforms GCW"
    "bes1r"  = "Bespin: Platforms CW"
    "bes2a"  = "Bespin: Cloud City GCW"
    "bes2r"  = "Bespin: Cloud City CW"
    "end1a"  = "Endor: Bunker"
    "geo1r"  = "Geonosis: Spire"
    "hot1i"  = "Hoth: Echo Base"
    "kam1c"  = "Kamino: Tipoca City"
    "kas1c"  = "Kashyyyk: Islands CW"
    "kas1i"  = "Kashyyyk: Islands GCW"
    "kas2c"  = "Kashyyyk: Docks CW"
    "kas2i"  = "Kashyyyk: Docks GCW"
    "nab1c"  = "Naboo: Plains CW"
    "nab1i"  = "Naboo: Plains GCW"
    "nab2a"  = "Naboo: Theed GCW"
    "nab2c"  = "Naboo: Theed CW"
    "rhn1i"  = "Rhen Var: Harbor GCW"
    "rhn1r"  = "Rhen Var: Harbor CW"
    "rhn2a"  = "Rhen Var: Citadel GCW"
    "rhn2c"  = "Rhen Var: Citadel CW"
    "tat1i"  = "Tatooine: Dune Sea GCW"
    "tat1r"  = "Tatooine: Dune Sea CW"
    "tat2i"  = "Tatooine: Mos Eisley GCW"
    "tat2r"  = "Tatooine: Mos Eisley CW"
    "yav1c"  = "Yavin IV: Temple CW"
    "yav1i"  = "Yavin IV: Temple GCW"
    "yav2i"  = "Yavin IV: Arena GCW"
    "yav2r"  = "Yavin IV: Arena CW"
    "tat3c"  = "Tatooine: Jabba's Palace CW"
    "tat3a " = "Tatooine: Jabba's Palace GCW"
}

Write-Host "Loading additional map translations...   `n"
foreach ($map in (Get-PropertyValue -Object $configFile.additionalMapTranslations -PropertyName "$($configFile.launchOptions.game)").PSObject.Properties) {
    $mapNames[$map.Name] = $map.Value
    Write-Host "** Loaded translation for mapkey $($map.Name): $($mapNames[$map.Name])`r`n"
}
 

function Compare-Arguments {
    param (
        [Parameter(Mandatory = $true)]
        [string]$serverArguments,

        [Parameter(Mandatory = $true)]
        [string]$compareArguments,

        [Parameter(Mandatory = $false)]
        [string[]]$skipArguments = @()
    )

    $serverArgs = $serverArguments -split ' /' | Where-Object { $_ }
    $compareArgs = $compareArguments -split ' /' | Where-Object { $_ }

    $serverArgsHash = @{}
    $compareArgsHash = @{}

    foreach ($arg in $serverArgs) {
        $splitArg = $arg -split ' ', 2
        if ($splitArg[0] -notin $skipArguments) {
            $serverArgsHash[$splitArg[0]] = $splitArg[1]
        }
    }

    foreach ($arg in $compareArgs) {
        $splitArg = $arg -split ' ', 2
        if ($splitArg[0] -notin $skipArguments) {
            $compareArgsHash[$splitArg[0]] = $splitArg[1]
        }
    }

    $changes = @()

    foreach ($key in $serverArgsHash.Keys) {
        if ($compareArgsHash.ContainsKey($key)) {
            if ($serverArgsHash[$key] -ne $compareArgsHash[$key]) {
                $changes += New-Object PSObject -Property @{
                    Argument     = "/$key"
                    ServerValue  = $serverArgsHash[$key]
                    CompareValue = $compareArgsHash[$key]
                    Status       = "Modified"
                }
            }
        }
        else {
            $changes += New-Object PSObject -Property @{
                Argument     = "/$key"
                ServerValue  = $serverArgsHash[$key]
                CompareValue = $null
                Status       = "Removed"
            }
        }
    }

    foreach ($key in $compareArgsHash.Keys) {
        if (!$serverArgsHash.ContainsKey($key)) {
            $changes += New-Object PSObject -Property @{
                Argument     = "/$key"
                ServerValue  = $null
                CompareValue = $compareArgsHash[$key]
                Status       = "Added"
            }
        }
    }

    return $changes
}

function Compare-Maps {
    param (
        [Parameter(Mandatory = $true)]
        [string]$serverMaps,

        [Parameter(Mandatory = $true)]
        [string]$compareMaps
    )

    $serverMapList = $serverMaps -split ' ' | Where-Object { $_ }
    $compareMapList = $compareMaps -split ' ' | Where-Object { $_ }

    $changes = @()

    for ($i = 0; $i -lt $serverMapList.Count; $i += 3) {
        $mapShortName = $serverMapList[$i]
        $count = ($serverMaps -split ' ' | Where-Object { $_ -eq $mapShortName }).Count
        if ($compareMapList -notcontains $mapShortName) {
            $ticketsA = $serverMapList[$i + 1]
            $ticketsB = $serverMapList[$i + 2]
            $mapFullName = $mapNames[$mapShortName]
            if (!$mapFullName) { $mapFullName = $mapShortName }
            $changes += New-Object PSObject -Property @{
                MapName    = $mapFullName
                Tickets    = "$ticketsA - $ticketsB"
                OldTickets = "$ticketsA - $ticketsB"
                Status     = "Removed"
                Count      = $count
            }
        }
    }

    for ($i = 0; $i -lt $compareMapList.Count; $i += 3) {
        $mapShortName = $compareMapList[$i]
        $count = ($compareMaps -split ' ' | Where-Object { $_ -eq $mapShortName }).Count
        if ($serverMapList -notcontains $mapShortName) {
            $ticketsA = $compareMapList[$i + 1]
            $ticketsB = $compareMapList[$i + 2]
            $mapFullName = $mapNames[$mapShortName]
            if (!$mapFullName) { $mapFullName = $mapShortName }
            $changes += New-Object PSObject -Property @{
                MapName    = $mapFullName
                Tickets    = "$ticketsA - $ticketsB"
                OldTickets = $null
                Status     = "Added"
                Count      = $count
            }
        }
    }

    return $changes
}

# Arguments
$serverParams = "-silent -applaunch $($appID) $($serverArguments) $($currentMaps)"
Write-Host "Launching steam app  $($appID) with parameters: $serverParams $($currentMaps)"
Start-Process -FilePath $serverExe  -ArgumentList $serverParams
Write-Host "Waiting 1 Minute for server to start..."
Start-Sleep -s 60
Write-Host "Server should be started now. Starting monitoring loop."
$lastSent = $null
$autoStartString =  "$($configFile.launchOptions.autoRestart.restartTime)".Split(":")
$restartAtHour = [int]::Parse($autoStartString[0])
$restartAtMinutes = [int]::Parse($autoStartString[1])
$CurrentTime = (date)
$restartDate = Get-Date -Year $CurrentTime.Year `
    -Month $CurrentTime.Month `
    -Day $CurrentTime.Day `
    -Hour $restartAtHour `
    -Minute $restartAtMinutes `
    -Second 0
Write-Host "Set restart date to $($restartDate)"

if ( $restartDate -lt $CurrentTime) {
    $restartDate = $restartDate.AddDays(1);
    Write-Host "Set new restart date to $($restartDate)"
}

$doRecover = $false
$lastServerConfigRefresh = Get-Date
	
while ($true) {
    
    $changeLog = $null
    
    $currentDate = Get-Date

    $timeDifference = ($currentDate - $lastServerConfigRefresh).TotalMinutes
 
   
    
    if ($timeDifference -ge 1) {
        
        Write-Host "Server config is older than 5 Minutes. Reloading..."
        $lastServerConfigRefresh = Get-Date

        $changedServerArguments = "" | Load-SvrArguments
        $newMaps = "" | Load-Maps
        # Usage
        $mapChanges = Compare-Maps -serverMaps $newMaps  -compareMaps $currentMaps
        $changedMaps = $mapChanges

        # Usage
        $changes = Compare-Arguments -serverArguments $changedServerArguments -compareArguments  $serverArguments -skipArguments $skipArguments
        $changedArguments = $changes 
    
        

        $serverArgumentsTranslation = @{
            "/randomize"    = "Random Order"
            "/noteamdamage" = "No Team Damage"
            "/tps"          = "Ticks per second"
            "/noaim"        = "No AIM Assist"
            "/gamename"     = "Server Name"
            "/playerlimit"  = "Max Players"
            "/netplayers"   = "Max Player Connected"
            "/playercount"  = "Min Players to start map"
            "/difficulty"   = "Difficulty"
            "/throttle"     = "Throttle"
            "/spawn"        = "Spawn Protection (Seconds)"
            "/bots"         = "Bots per Team"
        }

        foreach ($change in $changedArguments) {
            $argumentName = $serverArgumentsTranslation[$change.Argument]
            if (!$argumentName) { continue }
            $serverValue = $change.ServerValue
   
            $realStatus = $change.Status

            if (!$serverValue) {
                $realStatus = "changed"
            }


            if ($change.Status -eq "Removed" -and !$serverValue) { $serverValue = "no" }
            if ($change.Status -ne "Removed" -and !$serverValue) { $serverValue = "yes" }

            if ($configFile.launchOptions.discord.changeDetection.arguments) {
                
                $changeLog += "- **$argumentName** was $($realStatus.ToUpper()) to __$($serverValue)__`n"
            }
        }
        $addedMaps = $null
        $removedMaps = $null
        $modifiedMaps = $null

        foreach ($change in $changedMaps) {
    
            $mapName = $change.MapName
            $tickets = $change.Tickets
            $status = $change.Status

            if ($status -eq "Added") {
                $addedMaps += "- $mapName ($tickets)`n"
            }
            elseif ($status -eq "Removed") {
                $removedMaps += "- $mapName ($tickets)`n"
            }
            elseif ($status -eq "Modified") {
                $modifiedMaps += "- $mapName ($tickets) ~~($($change.OldTickets))~~`n"
            }


        }

        if ($addedMaps -and $configFile.launchOptions.discord.changeDetection.maps) {
            $changeLog += "The following maps were added: `n$addedMaps(Appears now $($change.Count) times in the rotation)`n"
        }

        if ($removedMaps -and $configFile.launchOptions.discord.changeDetection.maps) {
            $changeLog += "The following maps were removed: `n$removedMaps(Remains now $($change.Count) times in the rotation)`n"
        }

        if ($modifiedMaps -and $configFile.launchOptions.discord.changeDetection.maps) {
            $changeLog += "The following maps were modified: `n$modifiedMaps(Remains now $($change.Count) times in the rotation)`n"
        }   

        if ($changeLog) {
            $serverArguments = $changedServerArguments
            $currentMaps = $newMaps
            $serverParams = "-silent -applaunch $($appID) $($serverArguments) $($currentMaps)"
            $serverName = Get-Servername -arguments $serverArguments

            $message = $textTemplates.configChange -replace "{serverName}", $serverName -replace "{changes}", $changeLog	
            Send-DiscordMessage -message $message
        }
        else {
            Write-Host "No changes found"
        } 


    }
    else {
        Write-Host "Server config up to date."
    }

    Write-Host "[$(Get-Date)]Checking if $($gameFolderSuffix)\$($executable) is running for over 24 Hours..."
    $swbfProcess = Get-Process | Where-Object { $_.Path -like "*$($gameFolderSuffix)\$($executable)*" }
    if ($null -eq $swbfProcess) {
        Write-Host "[$(Get-Date)]SWBF Not Running"
		 
        if ($true -eq $doRecover) {
            Start-Process -FilePath $serverExe  -ArgumentList $serverParams
            $message = $textTemplates.serverRecovered -replace "{serverName}", $serverName
            Send-DiscordMessage -message $message

            if ($configFile.launchOptions.discord.announcements.serverCrash -eq $true) {
                Send-DiscordMessage -message $message
            }
            

            $doRecover = $false
        }
        else {
            $doRecover = $true
              
            $message = $textTemplates.serverCrash -replace "{serverName}", $serverName -replace "{recoverSeconds}", $configFile.launchOptions.recoverAfterSeconds
            if ($configFile.launchOptions.discord.announcements.serverCrash -eq $true) {
                Send-DiscordMessage -message $message
            }

        }
        
        Start-Sleep -s $configFile.launchOptions.recoverAfterSeconds

        continue
    }
     


    $ts = New-TimeSpan -Start (Get-Date) -End  $restartDate

    $totalMinutes = [math]::Round($ts.TotalMinutes );

    Write-Host "[$(Get-Date)]Will restart in  $($totalMinutes) minutes"

    if ($null -eq $lastSent) {
        Write-Host "[$(Get-Date)] Last sent is null"
    }
     
    if ($totalMinutes -lt 60) {
        $doSend = $false

        Write-Host "[$(Get-Date)] Total Minutes is under 60"

        if ($null -eq $lastSent) {
            $doSend = $true

        }
        else {

            $tt = New-TimeSpan -Start $lastSent -End (Get-Date)

            if ($totalMinutes -gt 30 -and $tt.TotalMinutes -gt 14) {
                $doSend = $true
            }
            elseif ($totalMinutes -lt 20 -and $tt.TotalMinutes -gt 5) {
                $doSend = $true
            }
            elseif ($totalMinutes -lt 2 -and $totalMinutes -gt 0 -and $tt.TotalMinutes -gt 1 ) {
                $doSend = $true
            } 

        }

        

        if ($doSend -and $configFile.launchOptions.autoRestart.enabled -eq $true) {
            Write-Host "[$(Get-Date)] Informing users..."
            $exactHours = "$($restartAtHour)"
            $exactMin = "$($restartAtMinutes)"
            
            if ($restartAtHour -lt 10) {
                $exactHours = "0$($restartAtHour)"
            }

            
            if ($restartAtMinutes -lt 10) {
                $exactMin = "0$($restartAtMinutes)"
            }

            $message = $textTemplates.serverRestart -replace "{serverName}", $serverName -replace "{minutesTillRestart}", $totalMinutes -replace "{restartTime}", "$($exactHours):$($exactMin)" -replace "{timeZone}", $configFile.launchOptions.autoRestart.timeZone
            
            if ($configFile.launchOptions.discord.announcements.serverRestart -eq $true) {
                Send-DiscordMessage -message $message
            }

            $lastSent = (Get-Date)
			
            Write-Host "[$(Get-Date)] Users informed"

        }


    }



    if ($totalMinutes -lt 1 -and $configFile.launchOptions.autoRestart.enabled -eq $true) {
        $message = $textTemplates.serverRestartingNow -replace "{serverName}", $serverName
        
        if ($configFile.launchOptions.discord.announcements.serverRestart -eq $true) {
            Send-DiscordMessage -message $message
        }
            
        Write-Host "[$(Get-Date)] Reached auto restart time. Stopping"
        Stop-Process -InputObject $swbfProcess -Force		
        Start-Sleep -s 5
        Start-Process -FilePath $serverExe  -ArgumentList $serverParams
		
        Write-Host "[$(Get-Date)] $($gameFolderSuffix)\$($executable) has been stopped."
        $restartDate = [DateTime]::Today.AddDays(1).AddHours($restartAtHour).AddMinutes($restartAtMinutes);

    }
    else {
        Write-Host "[$(Get-Date)] $($gameFolderSuffix)\$($executable) is running - no actions required so far."
    }

    Write-Host "[$(Get-Date)] Check Complete! Checking again in 60 Seconds"
    Start-Sleep -s 60
}