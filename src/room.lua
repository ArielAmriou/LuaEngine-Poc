-- The training room: a big box around the player.

-- Creates the room's 3D model. Called once by the engine at launch.
function start(gm)
    local room = gm:createEntity()
    gm:addComponent(room, 'Position3D')
    gm:addComponent(room, 'Model3D', {path = 'assets/models/room.glb'})
    gm:addComponent(room, 'Sprite3D')
end
