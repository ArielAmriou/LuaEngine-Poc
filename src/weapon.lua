-- The gun in the right hand: a left click makes it kick back, flash and bang.

local Ui = dofile('lib/ui.lua')

-- written by tools/render_viewmodel.py
local RENDER_HEIGHT = 1876
local SPRITE_W, SPRITE_H = 800, 847
local MARGIN_RIGHT, MARGIN_BOTTOM = 17, 0
local MUZZLE_X, MUZZLE_Y = 104, 46

local SCALE = Ui.SCREEN_H / RENDER_HEIGHT
local GUN_X = Ui.SCREEN_W - (MARGIN_RIGHT + SPRITE_W) * SCALE
local GUN_Y = Ui.SCREEN_H - (MARGIN_BOTTOM + SPRITE_H) * SCALE

-- pixels of gun.png and seconds
local RECOIL_X, RECOIL_Y = 30, 70
local RECOIL_TIME = 0.125
local FLASH_TIME = 0.05
local FLASH_SIZE = 160 * SCALE
local SHOT_VOLUME = 0.6

local gun, flash, shotSound
-- 1 right after a shot, 0 when the gun is back
local recoil = 0
local flashTime = 0

-- Fires on a click, then places the gun and the flash. Called by the engine every frame.
local function update(gm)
    local dt = gm:elapsed() / 1000

    if gm:mouse():isPressed(MouseButton.Left) then
        recoil = 1
        flashTime = FLASH_TIME
        gm:getComponent(shotSound, 'Sound').state = SoundState.PLAY
    end
    recoil = math.max(0, recoil - dt / RECOIL_TIME)
    flashTime = flashTime - dt

    local x = GUN_X + recoil * RECOIL_X * SCALE
    local y = GUN_Y + recoil * RECOIL_Y * SCALE
    Ui.moveTo(gm, gun, x, y)

    if flashTime > 0 then
        local muzzleX, muzzleY = x + MUZZLE_X * SCALE, y + MUZZLE_Y * SCALE
        Ui.moveTo(gm, flash, muzzleX - FLASH_SIZE / 2, muzzleY - FLASH_SIZE / 2)
    else
        Ui.hide(gm, flash)
    end
end

-- Creates the gun, the flash and the shot sound. Called by the engine at launch.
function start(gm)
    gun = Ui.newSprite(gm, 'assets/sprites/gun.png', SCALE)
    flash = Ui.newSprite(gm, 'assets/sprites/flash.png', SCALE)

    shotSound = gm:createEntity()
    gm:addComponent(shotSound, 'Sound', {path = 'assets/sounds/shot.wav'})
    gm:getComponent(shotSound, 'Sound'):setVolume(SHOT_VOLUME)

    gm:createSystem(update)
end
