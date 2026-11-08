-- The player's eyes: a camera that turns with the mouse.

local EYE_HEIGHT = 1.7
local SENSITIVITY = 0.0025

-- Creates the camera and the engine systems that turn it with the mouse.
-- Called once by the engine at launch.
function start(gm)
    local camera = gm:createEntity()
    gm:addComponent(camera, 'Position3D', {y = EYE_HEIGHT})
    gm:addComponent(camera, 'Camera3D', {fovy = 70})
    gm:addComponent(camera, 'CameraAngle')
    gm:addComponent(camera, 'CameraAngleInput')
    gm:addComponent(camera, 'CameraMouseControl', {sensitivity = SENSITIVITY})

    -- keep the mouse inside the window, as in any first-person game
    gm:setHideCursor(true)

    -- mouse movement -> camera angle
    gm:addSystem('CameraMouseControl')
    gm:addSystem('CameraAngleInput')
end
