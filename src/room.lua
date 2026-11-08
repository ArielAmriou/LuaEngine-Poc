-- The training room.

-- Creates the room's model. Called by the engine at launch.
function start(gm)
    local room = gm:createEntity()
    gm:addComponent(room, 'Position3D')
    gm:addComponent(room, 'Model3D', {path = 'assets/models/room.glb'})
    gm:addComponent(room, 'Sprite3D')
end
