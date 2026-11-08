-- Loaded last, so its systems run after the game's: point the camera,
-- draw the 3D world, then the 2D on top of it. Full screen, Escape quits.

-- Stops the game when Escape or the window's close button is pressed.
-- Called by the engine every frame.
local function quit(gm)
    if gm:shouldClose() then
        gm:stop()
    end
end

-- Goes full screen and registers quit, the camera and the drawing systems,
-- in the order they run. Called once by the engine at launch.
function start(gm)
    gm:setFullScreen(true)

    gm:createSystem(quit)
    gm:addSystem('UpdateCamera')
    gm:addSystem('CameraAngle')
    gm:addSystem('Draw3D')
    gm:addSystem('DrawSprite2D')
    gm:addSystem('DrawText2D')
end
