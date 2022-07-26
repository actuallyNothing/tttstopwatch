
# Configuration

<br>

## Server

### `stopwatch_on_fail`

Default: `cancel`

What should happen if the spot to <br>
teleport to is blocked by a player.

-   `cancel`

    Cancel the teleport.

-   `kill_blocker`

    Kill the player that's blocking the spot and <br>
    attribute the kill to the Stopwatch user.

-   `kill_user`

    Kill the Stopwatch user and attribute the <br>
    kill to the player that's blocking the spot.

<br>

### `stopwatch_cooldown`

Default : `30` <br>
Unit : `Seconds`

Cooldown in seconds between Stopwatch uses.

<br>

### `stopwatch_cancel_cooldown`

Default: `3` <br>
Unit : `Seconds`

How much time has to pass before the player can teleport early. <br>
If set to more than `10 Seconds`, it will effectively be disabled.

<br>

### `stopwatch_allow_cancelling_midair`

Default: `1`

Can players teleport early while in mid-air.

<br>

### `stopwatch_nofall`

Default: `1`

Should the Stopwatch negate fall damage while active.

<br>
<br>

## Client

### `stopwatch_show_time`

Default: `0`

Should the exact time in seconds before <br>
teleportation be shown to the player.

<br>