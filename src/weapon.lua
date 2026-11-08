-- The gun in the right hand: on every left click, it kicks back, flashes and bangs.

-- same as config.conf
local SCREEN_W, SCREEN_H = 3000, 1876

-- gun.png and these numbers are written by tools/render_viewmodel.py:
-- the sprite sits in the bottom-right corner, scaled to the screen's height,
-- and MUZZLE_X, MUZZLE_Y is the end of the barrel inside the sprite
local RENDER_HEIGHT = 1876
local SPRITE_W, SPRITE_H = 800, 847
local MARGIN_RIGHT, MARGIN_BOTTOM = 17, 0
local MUZZLE_X, MUZZLE_Y = 104, 46

local SCALE = SCREEN_H / RENDER_HEIGHT
local GUN_X = SCREEN_W - (MARGIN_RIGHT + SPRITE_W) * SCALE
local GUN_Y = SCREEN_H - (MARGIN_BOTTOM + SPRITE_H) * SCALE
-- flash.png is 160 px wide
local FLASH_SIZE = 160 * SCALE

local gun, flash, shotSound
-- 1 right after a shot, back to 0 quickly
local recoil = 0
-- seconds the flash stays visible
local flashTime = 0

-- Moves a 2D entity on screen. Called by update.
local function moveTo(gm, entity, x, y)
    local pos = gm:getComponent(entity, 'Position2D')
    pos.x = x
    pos.y = y
end

-- The gun's system: on a left click, starts the recoil, the flash and the
-- sound, then places the gun and the flash. Called by the engine every frame.
local function update(gm)
    local dt = gm:elapsed() / 1000

    if gm:mouse():isPressed(MouseButton.Left) then
        recoil = 1
        flashTime = 0.05
        gm:getComponent(shotSound, 'Sound').state = SoundState.PLAY
    end
    recoil = math.max(0, recoil - dt * 8)
    flashTime = flashTime - dt

    -- the recoil pushes the gun down and to the right
    local x = GUN_X + recoil * 30 * SCALE
    local y = GUN_Y + recoil * 70 * SCALE
    moveTo(gm, gun, x, y)

    if flashTime > 0 then
        moveTo(gm, flash, x + MUZZLE_X * SCALE - FLASH_SIZE / 2, y + MUZZLE_Y * SCALE - FLASH_SIZE / 2)
    else
        moveTo(gm, flash, -10000, -10000)
    end
end

-- Creates the gun, the flash and the shot sound, and registers update.
-- Called once by the engine at launch.
function start(gm)
    gun = gm:createEntity()
    gm:addComponent(gun, 'Position2D')
    gm:addComponent(gun, 'Texture2D', {path = 'assets/sprites/gun.png'})
    gm:addComponent(gun, 'Sprite2D', {scale = SCALE})

    flash = gm:createEntity()
    gm:addComponent(flash, 'Position2D', {x = -10000})
    gm:addComponent(flash, 'Texture2D', {path = 'assets/sprites/flash.png'})
    gm:addComponent(flash, 'Sprite2D', {scale = SCALE})

    shotSound = gm:createEntity()
    gm:addComponent(shotSound, 'Sound', {path = 'assets/sounds/shot.wav'})
    gm:getComponent(shotSound, 'Sound'):setVolume(0.6)

    gm:createSystem(update)
end
