# Aim Trainer

A first-person aim trainer for the R-Type Lua engine
([Lua scripting guide](https://github.com/pierrick-simon/R-Type/wiki/Lua-Scripting-Guide)).

Targets appear in front of you and shrink until they vanish. Shoot them with the
left click: the faster the hit, the more points. A round lasts 30 seconds, then
the score is shown, and you can play again or quit.

## Run

```sh
cd LuaPoc && game
```

## Files

The engine loads the scripts in alphabetical order, and their systems run in that
order every frame: the number in front of each file sets it. Each script has its
own variables, so every file is self-contained.

| File | Role |
|---|---|
| `src/1_room.lua` | the 3D room |
| `src/2_player.lua` | the camera, turned by the mouse |
| `src/3_round.lua` | the game: targets, shooting, score, menus |
| `src/4_weapon.lua` | the gun in the right hand: recoil, flash, sound |
| `src/5_render.lua` | runs last: camera, 3D drawing, 2D on top, Escape quits |
| `tools/gen_assets.py` | generates the room, the targets, the 2D sprites and the sounds in `assets/` |
| `tools/render_viewmodel.py` | renders `assets/sprites/gun.png` with Blender (see below) |

The settings (round time, target life, number of targets, sensitivity) are at the
top of `3_round.lua` and `2_player.lua`.

## Screen size

The game runs full screen at the screen's own resolution. A script cannot read
the screen's size, so it is written in three places: `windowWidth` and
`windowHeight` in `config.conf`, and `SCREEN_W, SCREEN_H` at the top of
`3_round.lua` and `4_weapon.lua`. Everything in 2D is scaled from it.

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
at the top of `src/4_weapon.lua` by itself.

```sh
blender -b --python tools/render_viewmodel.py -- --gun-back 0.05 --look-left 0.1
```

The mannequin and the pistol it uses are in `tools/sources/`.

## Credits

- Mannequin and pose: Universal Animation Library by Quaternius (CC0).
- Pistol: Makarov from the "Guns&Explosives" pack.
- Font: DejaVu Sans Bold.
