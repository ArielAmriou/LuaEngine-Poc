-- The player's body: walking with Z Q S D and jumping with Space moves the camera.

local Movement = {}

-- meters, and per second
local EYE_HEIGHT = 1.7
local START_X, START_Z = 0, 0
local WALK_SPEED = 5
local JUMP_SPEED = 6
local GRAVITY = 18

-- the feet's height above the floor, and their vertical speed
local height = 0
local upSpeed = 0

-- Puts the player at the start. Called by player.lua and peek.lua.
function Movement.reset(gm)
    height, upSpeed = 0, 0
    for _, eye in gm:view({'Position3D', 'CameraAngle'}) do
        eye.x, eye.y, eye.z = START_X, EYE_HEIGHT, START_Z
    end
end

-- The direction asked by the keys (forward, right), of length 1 at most.
-- Called by Movement.update.
local function keysDirection(keyboard)
    local forward, right = 0, 0
    if keyboard:isDown(Key.Z) then forward = forward + 1 end
    if keyboard:isDown(Key.S) then forward = forward - 1 end
    if keyboard:isDown(Key.D) then right = right + 1 end
    if keyboard:isDown(Key.Q) then right = right - 1 end

    local length = math.sqrt(forward * forward + right * right)
    if length > 0 then
        forward, right = forward / length, right / length
    end
    return forward, right
end

-- Jumps on Space when on the floor, then falls back. Called by Movement.update.
local function jumpAndFall(keyboard, dt)
    if height == 0 and keyboard:isPressed(Key.Space) then
        upSpeed = JUMP_SPEED
    end
    upSpeed = upSpeed - GRAVITY * dt
    height = math.max(0, height + upSpeed * dt)
    if height == 0 then
        upSpeed = 0
    end
end

-- Walks and jumps, staying inside the given area. Called by peek.lua every frame.
function Movement.update(gm, dt, minX, maxX, minZ, maxZ)
    local keyboard = gm:keyboard()
    local forward, right = keysDirection(keyboard)
    jumpAndFall(keyboard, dt)

    for _, eye, angle in gm:view({'Position3D', 'CameraAngle'}) do
        local lookX, lookZ = math.sin(angle.yaw), -math.cos(angle.yaw)
        local rightX, rightZ = math.cos(angle.yaw), math.sin(angle.yaw)
        local step = WALK_SPEED * dt

        local x = eye.x + (lookX * forward + rightX * right) * step
        local z = eye.z + (lookZ * forward + rightZ * right) * step
        eye.x = math.max(minX, math.min(maxX, x))
        eye.z = math.max(minZ, math.min(maxZ, z))
        eye.y = EYE_HEIGHT + height
    end
end

return Movement
