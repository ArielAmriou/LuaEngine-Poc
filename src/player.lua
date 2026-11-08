-- The player's eyes: a camera turned by the mouse.

local Movement = dofile('lib/movement.lua')

local SENSITIVITY = 0.0025
-- vertical, in degrees
local FIELD_OF_VIEW = 70

-- Creates the camera and the mouse systems. Called by the engine at launch.
function start(gm)
    local camera = gm:createEntity()
    gm:addComponent(camera, 'Position3D')
    gm:addComponent(camera, 'Camera3D', {fovy = FIELD_OF_VIEW})
    gm:addComponent(camera, 'CameraAngle')
    gm:addComponent(camera, 'CameraAngleInput')
    gm:addComponent(camera, 'CameraMouseControl', {sensitivity = SENSITIVITY})
    Movement.reset(gm)

    gm:setHideCursor(true)
    gm:addSystem('CameraMouseControl')
    gm:addSystem('CameraAngleInput')
end
