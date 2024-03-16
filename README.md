 [![Paypal Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=SVZHLRTQ6H4VL)
# SWBF Classic / Classic Collection Dedicated Server Launcher

This is a helper script which starts your dedicated server for SWBF1 Classic or Classic Collection.
Key Features are:
* Discord integration
* Auto Restart
* Auto Recover when crashing

Its based on the script the Classic Hub from me is using for 1000 Ticket Servers since day one: https://discord.gg/MENWbnEuvF
Feel free to join the discord and play with others.

## Installation

To install or update the launcher, follow these steps:

1. Clone or download this repository.
2. Run the `installOrUpdate.ps1` script.
## Configuration Options

```js
{
    "steamFolder": "C:\\Gaming\\Steam", // The Folder to your Steam.exe
    "additionalMapTranslations": {
        // For modded maps add translations for them to print then properly to the discord by game
        "classic": {
            "test1": "test1 map"  
        },
        "classicCollection": {}
    },
    "gameConfigs": {
        // Stores the game configs which holds executable name, folder name and app id
        "classic": {
            "gameFolderSuffix": "Star Wars Battlefront (Classic 2004)\\GameData",  // The Last Parts (unique) of the folder path to the classic swbf (this here is the default value)
            "executable": "Battlefront.exe", // Name of the Battlefront executable (by default its Battlefront.exe)
            "appID": "1058020" // steam app id 
        },
        // this is the same config for  the classic collection
        "classicCollection": {
            "gameFolderSuffix": "Battle", // the folder name for the classic collection
            "executable": "Battlefront.exe", 
            "appID": "2446550"  // steam app id
        }
    },
    "launchOptions": {
        "recoverAfterSeconds": 5, // This are the seconds the script should wait before recovering a crashed server
        "game": "classic", // The game key name (classic or classicCollection)
        // This configures the discord functionality
        "discord": {
            "enabled": false, // Turns discord integration on/off (true/false)
            "webookUrl": "<url for your webhook>" // See below for more info
            "announcements": {
                "serverCrash": true, // Tells the bot to post to given channel when server crashs or gets recovered
                "serverRestart": true, // Tells the bot to post when its auto restarting the server 
                "configChange": true // Tells the bot to post when a config has changed
            },
            // Text template for discord  messages (you can use markdown) - see available placeholders below
            "textTemplates": {
                "serverCrash": "Server  `{serverName}` crashed will recover it in {recoverSeconds} seconds.", 
                "serverRecovered": "Server `{serverName}` recovered from crash.",
                "serverRestart": "Server `{serverName}`  will restart in exact {minutesTillRestart} Minutes (@{restartTime} {timeZone})!",
                "serverRestartingNow": "Server `{serverName}` will restart **now**. Please be patient as the server can be unavailable for a few minutes!",
                "configChange": "Server `{serverName}` config has been changed: \r\n\r\n{changes} \r\nChanges apply at next restart."
            },
            // Discord messages for chaning in this configurations
            "changeDetection": {
                "maps": true, // Sends a discord message when a map is added, removed or changed
                "arguments": true // Sends a discord message when a server argument was added, removed or changed
            }
        },

        // this is the auto restart functionality
        // it will restart the server at exact the time of the day you set it to
        // TimeZone Param is only for displey the timezone in discord messages
        // Launcher uses timezone of your computer / server.
        "autoRestart": {
            "enabled": true,
            "restartTime": "15:52",
            "timeZone": "CET"
        }
    }
}
```


## Usage
### Configure your server
Frst open the `server.config` with a text editor. Adjust it how you like or add parameters as you whish (See steam guides for it).
Nex lets set up our map pool - this happens in the `maps.config`.

The maps are listed like that:

`mapshort1 <tickets side a> <tickets side b> mapshort2 <tickets side a> <tickets side b>`

Here is the default map pool for SWBF 1:

| Map Short Name | Map Fullname             |
| -------------- | ------------------------ |
| bes1a          | Bespin: Platforms GCW    |
| bes1r          | Bespin: Platforms CW     |
| bes2a          | Bespin: Cloud City GCW   |
| bes2r          | Bespin: Cloud City CW    |
| end1a          | Endor: Bunker            |
| geo1r          | Geonosis: Spire          |
| hot1i          | Hoth: Echo Base          |
| kam1c          | Kamino: Tipoca City      |
| kas1c          | Kashyyyk: Islands CW     |
| kas1i          | Kashyyyk: Islands GCW    |
| kas2c          | Kashyyyk: Docks CW       |
| kas2i          | Kashyyyk: Docks GCW      |
| nab1c          | Naboo: Plains CW         |
| nab1i          | Naboo: Plains GCW        |
| nab2a          | Naboo: Theed GCW         |
| nab2c          | Naboo: Theed CW          |
| rhn1i          | Rhen Var: Harbor GCW     |
| rhn1r          | Rhen Var: Harbor CW      |
| rhn2a          | Rhen Var: Citadel GCW    |
| rhn2c          | Rhen Var: Citadel CW     |
| tat1i          | Tatooine: Dune Sea GCW   |
| tat1r          | Tatooine: Dune Sea CW    |
| tat2i          | Tatooine: Mos Eisley GCW |
| tat2r          | Tatooine: Mos Eisley CW  |
| yav1c          | Yavin IV: Temple CW      |
| yav1i          | Yavin IV: Temple GCW     |
| yav2i          | Yavin IV: Arena GCW      |
| yav2r          | Yavin IV: Arena CW       |

### Start the server
To start using the launcher, follow these steps:

1. Make sure you have installed it on a location you find it.
2. Run the `launcher.ps1` script.

### Config changes:
Changes to `server.config` and `maps.config`are detected every 5 Minutes and will be applied on next server start or crash recover.
For changes to `launcher.config.json` you need to stop the Server and the launcher first.


## Discord Integration

If you want to enable Discord integration, you'll need to create a bot and find the channel ID. Here's how:
**Important**
The info here was wrong. Dont create a bot. Instead create a web hook.

### Setting up the webhook
1. Go to your discord server
2. Click on the arrow next to the server name (very top)

This dropdown should appear:
![Dropdown](docs/image01.png)

3. Now click on `Server Setting`
4. Below `Apps` click on `Integrations`
5. Now select `Webhooks`
6. Create your webhook:
![Webhook Settings](docs/image02.png)

This is where you select a name,  profile picture and a target channel for your "bot".
7. When done: Click on `Copy Webhook Url` and paste it into the the config value in `launcher.config.json` under launchOptions -> discord -> webookUrl

## FAQ

### Can I use the launcher for SWBF II Classic?
Technically yes. But you have to configure it all by yourself including the map translations, folder suffix and the executable name.

### Why the auto restart?
The server process sometimes freezed and the server was gone due to it even the server windows was fully accsible.
A restart every 24 Hours solved this issue.

### How to contribute
You can create pull request for changes you find usefull. If youre not into programming Im more than happy with a small paypal donation. :-) 

 [![Paypal Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=SVZHLRTQ6H4VL)
