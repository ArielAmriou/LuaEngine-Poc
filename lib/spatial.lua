-- Sounds that come from a place in the room.
-- The engine's listener cannot turn, so a sound is placed as seen from the
-- player: x = how far to their right, y = how far away. Sound2D does the rest.

local Spatial = {}

-- meters: full volume until MIN_DISTANCE, silent after MAX_DISTANCE
local MIN_DISTANCE = 6
local MAX_DISTANCE = 60

-- Gives an entity a spatial sound. Called by gridshot.lua and peek.lua.
function Spatial.attach(gm, entity, path, loop)
    gm:addComponent(entity, 'Position2D')
    gm:addComponent(entity, 'Sound', {
        path = path,
        loop = loop or false,
        stereo = true,
        attenuation = Attenuation.INVERSE,
        minDistance = MIN_DISTANCE,
        maxDistance = MAX_DISTANCE,
    })
end

-- Plays the sound from its start. Called by gridshot.lua and peek.lua.
function Spatial.play(gm, entity)
    gm:getComponent(entity, 'Sound').state = SoundState.PLAY
end

-- Stops the sound. Called by peek.lua.
function Spatial.stop(gm, entity)
    gm:getComponent(entity, 'Sound').state = SoundState.STOP
end

-- Puts the sound at x, y, z in the room. Called every frame by gridshot.lua and peek.lua.
function Spatial.place(gm, entity, x, y, z)
    for _, eye, angle in gm:view({'Position3D', 'CameraAngle'}) do
        local dx, dy, dz = x - eye.x, y - eye.y, z - eye.z
        local right = dx * math.cos(angle.yaw) + dz * math.sin(angle.yaw)
        local distanceSquared = dx * dx + dy * dy + dz * dz
        local pos = gm:getComponent(entity, 'Position2D')
        pos.x = right
        pos.y = math.sqrt(math.max(0, distanceSquared - right * right))
    end
end

return Spatial
