# Multiplayer.js

A framework for multiplayer physics simulations (read: games)

## Changelog

Version 0.1 - First release, pretty mediocre API but it works.
Version 0.1.1 - Remove a bunch of extraneous dependencies

## Description

The main feature of `multiplayer.js` is lag compensation. Using interpolation,
extrapolation and client-side prediction, the _apparent_ effects of network
latency are minimised.

Since every game is different, `multiplayer.js` doesn't mandate any particular
transport protocol or simulation engine. The only requirement is to be able to
provide it with a simple JSON representation of player states and of user input.
These objects need to be passed back and forth to instances of `Server` and
`Client`.

The environment running the `Server` is responsible for running the canonical
game simulation (physics). It will need to take any user commands (inputs) and
generate a new game state every frame.

The environment(s) running the `Client` are responsible for presenting the game
state to a player (rendering), and for running a local simulation of the game in
order to predict the player's movement during the time between receiving input
and the server acknowledging that input.

## Usage

```
npm install multiplayer
```

There will be a downloadable browser-only package soon, but for now the easiest
way to include `multiplayer.js` in your browser code is to use `browserify`.
Check the example out for more info.

## How does it work?

A `framestamp` is a decimal value of form m.n, where:

  * m is an integer referring to the frame number
  * n is a decimal in the range `0.0 <= n < 1.0`, referring to a fraction of a
    frame's time

ie: framestamp 10.20 means frame 10, 20% of the way to frame 11

On the server:
  Set a constant fps, where fpsInterval = 1 / fps
  Each time a player command comes in:
    Advance the player based on the framestamp given in the command
      NOTE client framestamp must be <= server framestamp
      player.updatePhysics(dt (in milliseconds), inputs)
        @time += dt
        @position += @velocity * dt
        @velocity = getVelocity(inputs)
  Every fpsInterval:
    Advance the world by fpsInterval (non-player-controlled entities)
    Prepare and broadcast a snapshot
      Include entity positions, and player framestamps

On the client:
  Assuming the client knows server fps...
  Each time a snapshot comes in:
    Add it to a list
  Each graphics frame:
    Check for a new snapshot
      If there is one, set oldSnap = nextSnap, nextSnap = new snapshot
      If there isn't and time < nextSnap.time, don't do anything
      If there isn't and time > nextSnap.time, set oldSnap = nextSnap,
        nextSnap = null
    Run client-side prediction
      Run through the list of input commands:
        Remove and skip if command's framestamp <= oldSnap.players[this].frameStamp
        Otherwise, advance the player, using the same physics code as on the
        server
    Interpolate/extrapolate all other entities' positions
    Trigger events (a/v effects)
    Render frame

