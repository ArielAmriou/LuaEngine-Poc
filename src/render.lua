-- Full screen, camera and drawing: 3D first, then 2D on top. Escape quits.

local Quit = dofile('lib/quit.lua')

-- Quits on Escape or the close button. Called by the engine every frame.
local function quitOnClose(gm)
    if gm:shouldClose() then
        Quit.now(gm)
    end
end

-- Registers the drawing systems, in the order they run. Called by the engine at launch.
function start(gm)
    gm:setFullScreen(true)

    gm:createSystem(quitOnClose)
    gm:addSystem('UpdateCamera')
    gm:addSystem('CameraAngle')
    gm:addSystem('Draw3D')
    gm:addSystem('DrawSprite2D')
    gm:addSystem('DrawText2D')
end
