-- 3D helpers. A model is created once, then moved; it is hidden under the floor.

local Models = {}

local HIDDEN_Y = -100

-- Creates a hidden model. Called by gridshot.lua and peek.lua.
function Models.new(gm, path)
    local entity = gm:createEntity()
    gm:addComponent(entity, 'Position3D', {y = HIDDEN_Y})
    gm:addComponent(entity, 'Model3D', {path = path})
    gm:addComponent(entity, 'Sprite3D')
    return entity
end

-- Moves a 3D entity. Called by gridshot.lua and peek.lua.
function Models.place(gm, entity, x, y, z)
    local pos = gm:getComponent(entity, 'Position3D')
    pos.x, pos.y, pos.z = x, y, z
end

-- Hides a 3D entity. Called by gridshot.lua and peek.lua.
function Models.hide(gm, entity)
    Models.place(gm, entity, 0, HIDDEN_Y, 0)
end

return Models
