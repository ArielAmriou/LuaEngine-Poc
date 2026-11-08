# Aim Trainer

A first-person aim trainer for the R-Type Lua engine
([Lua scripting guide](https://github.com/pierrick-simon/R-Type/wiki/Lua-Scripting-Guide)).

Two modes, picked in the menu:

- **Gridshot** (`1`): targets appear in front of you and shrink until they
  vanish. The faster the hit, the more points.
- **Peek** (`2`): mannequins run from one crate to the next. Shoot them while
  they cross the gap; a headshot scores more. Walk with `Z Q S D` and jump
  with `Space`.

A round lasts 30 seconds, then the score is shown: `R` plays again, `M` goes
back to the menu, `Q` or `Escape` quits.

## Run

```sh
cd LuaPoc && game
```

## Files

The engine runs every script of `src/` (each one has a `start` function), in
alphabetical order. Each script has its own variables, so the code they share
is in modules, in `lib/`, loaded with `dofile`. `lib/` must stay out of `src/`:
the engine would run its files as scripts.

| File | Role |
|---|---|
| `src/player.lua` | the camera, turned by the mouse |
| `src/render.lua` | the camera update, 3D drawing, 2D on top, full screen, Escape quits |
| `src/room.lua` | the 3D room |
| `src/round.lua` | the menu, the rounds, the score and the results |
| `src/weapon.lua` | the gun in the right hand: recoil, flash, sound |
| `lib/gridshot.lua` | the Gridshot mode: the targets |
| `lib/peek.lua` | the Peek mode: the crates and the mannequins |
| `lib/movement.lua` | walking with Z Q S D and jumping with Space (used by Peek) |
| `lib/spatial.lua` | sounds that come from a place in the room (target pops, footsteps) |
| `lib/aim.lua` | the aim ray, and what it hits (spheres, boxes) |
| `lib/models.lua` | creating, placing and hiding 3D models |
| `lib/quit.lua` | quitting without the engine's crash on exit (destroys the sounds first) |
| `lib/ui.lua` | the screen size, and creating and placing 2D sprites and texts |

Each mode has the same functions (`create`, `start`, `clear`, `shoot`,
`update`, `results`), called by `src/round.lua`. The settings of each mode
are at the top of its file; the round time is at the top of `src/round.lua`,
the mouse sensitivity at the top of `src/player.lua`.

## Screen size

The game runs full screen at the screen's own resolution. A script cannot read
the screen's size, so it is written in `config.conf` (`windowWidth`,
`windowHeight`) and in `lib/ui.lua` (`SCREEN_W`, `SCREEN_H`). Everything in 2D
is scaled from it.

## The gun sprite

The engine cannot turn a 3D model with the camera, so the gun is a 2D image: a
Blender render of a mannequin's right arm holding a pistol, seen from its eyes.

The settings are at the top of `tools/render_viewmodel.py` (`SETTINGS`):

| Setting | Effect |
|---|---|
| `gun_back`, `gun_down`, `gun_left` | slide the gun in the hand (meters) |
| `gun_pitch`, `gun_yaw`, `gun_roll` | turn the gun in the hand (degrees) |
| `fov` | field of view: smaller makes the gun bigger |
| `look_left`, `look_up` | where the eyes look: move the gun on screen |
| `pose`, `frame` | the mannequin's animation and its frame |
| `screen_width`, `screen_height` | the game's screen, as in `config.conf` |

Try settings with a quick preview, which does not change the game: it writes
`tools/preview_eye.png` (what the player sees) and `tools/preview_side.png`
(the hand from the side). Any setting can be given on the command line.

```sh
blender -b --python tools/render_viewmodel.py -- --preview --gun-back 0.05 --look-left 0.1
```

Then render for real: it writes `assets/sprites/gun.png` and updates the numbers
at the top of `src/weapon.lua` by itself.

```sh
blender -b --python tools/render_viewmodel.py -- --gun-back 0.05 --look-left 0.1
```

The mannequin and the pistol it uses are in `tools/sources/`.

## Credits

- Mannequins and animations: Universal Animation Library by Quaternius (CC0).
- Pistol: Makarov from the "Guns&Explosives" pack.
- Font: DejaVu Sans Bold.
