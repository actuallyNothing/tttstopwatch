# ![Stopwatch Icon](https://i.imgur.com/DKpabMV.png) Stopwatch
A piece of equipment that allows you to mark your position and teleport back to it 10 seconds later.

This is my take on Tommy228's old X-Mark equipment, which is now deleted. I've heard numerous requests for this weapon before, so this is my own take on it.

## Usage

After buying it off the Traitor shop, press E + R to activate it. This will start a 10-second timer, that upon ending, will teleport you back to the position you marked.
During this time, **you receive no fall damage.**
After 3 seconds have passed since the start of the timer, you can teleport early. By default, this has a 30 second cooldown, after which you can use the ability again.

You can't start the ability while crouching or mid-air, and the ability's status is shown through a small GUI for the player.

## ConVars
### Server ConVars
- **stopwatch_on_fail** (default: 'cancel'): Determines what will happen if a player is blocking a teleport spot. Allowed values are:
  - **'cancel'**: Will cancel the teleport.
  - **'kill_blocker'**: Will kill the player that's blocking, and attribute the kill to the Stopwatch user.
  - **'kill_user'**: Will kill the Stopwatch user, and attribute the kill to the player that's blocking.
  
- **stopwatch_cooldown** (default: 30): Determines the cooldown in seconds between Stopwatch uses.

- **stopwatch_cancel_cooldown** (default: 3): Determines how much time in seconds has to pass before the player can teleport early. Set to a value higher than 10 to effectively disable early teleporting.

- **stopwatch_allow_cancelling_midair** (default: 1): Determines whether players can teleport early while in mid-air.

### Client ConVars
- **stopwatch_show_time** (default: 0): Determines whether to show the exact time in seconds before teleporting the player.

## Installing

Alongside the Workshop installation, you can download this repository's code as a ZIP file, and extract it inside your game or server's garrysmod/addons folder.
Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2599563790

## Credits

Thanks to **Stig**, **Michy**, **Reino**, **Haru**, **Alejandro**, **Eagle** and **DaniPrrrum** for helping to test this addon.

Original idea by Tommy228: https://github.com/Tommy228/

Icon made with works by Icons8: https://icons8.com/
