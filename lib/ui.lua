-- 2D helpers. Sizes are given for a 720 px high screen, then scaled.

local Ui = {}

-- same as config.conf
Ui.SCREEN_W, Ui.SCREEN_H = 3000, 1876
Ui.SCALE = Ui.SCREEN_H / 720

local OFF_SCREEN = -10000

-- A size of the 720 px layout in real pixels. Called wherever the interface is placed.
function Ui.px(size)
    return size * Ui.SCALE
end

-- Moves a 2D entity. Called by round.lua and weapon.lua.
function Ui.moveTo(gm, entity, x, y)
    local pos = gm:getComponent(entity, 'Position2D')
    pos.x = x
    pos.y = y
end

-- Centers a 2D entity of the given layout size. Called by round.lua.
function Ui.center(gm, entity, width, height)
    Ui.moveTo(gm, entity, (Ui.SCREEN_W - Ui.px(width)) / 2, (Ui.SCREEN_H - Ui.px(height)) / 2)
end

-- Hides a 2D entity. Called by round.lua and weapon.lua.
function Ui.hide(gm, entity)
    Ui.moveTo(gm, entity, OFF_SCREEN, OFF_SCREEN)
end

-- Changes a text. Called by round.lua.
function Ui.setText(gm, entity, str)
    gm:getComponent(entity, 'Text2D').str = str
end

-- Creates a hidden sprite. Called by round.lua and weapon.lua.
function Ui.newSprite(gm, path, scale)
    local entity = gm:createEntity()
    gm:addComponent(entity, 'Position2D', {x = OFF_SCREEN})
    gm:addComponent(entity, 'Texture2D', {path = path})
    gm:addComponent(entity, 'Sprite2D', {scale = scale or Ui.SCALE})
    return entity
end

-- Creates an empty text. Called by round.lua.
function Ui.newText(gm, x, y, size)
    local entity = gm:createEntity()
    gm:addComponent(entity, 'Position2D', {x = x, y = y})
    gm:addComponent(entity, 'Font', {path = 'assets/fonts/font.ttf'})
    gm:addComponent(entity, 'Text2D', {str = '', fontSize = Ui.px(size)})
    return entity
end

return Ui
