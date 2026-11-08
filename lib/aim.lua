-- What a shot hits: a ray from the eyes, tested against spheres and boxes.
-- The tests return the distance along the ray, so the nearest hit can be kept.

local Aim = {}

-- The eyes' position and the direction they look at. Called by gridshot.lua and peek.lua.
function Aim.ray(gm)
    for _, eye, angle in gm:view({'Position3D', 'CameraAngle'}) do
        local dir = {
            x = math.sin(angle.yaw) * math.cos(angle.pitch),
            y = math.sin(angle.pitch),
            z = -math.cos(angle.yaw) * math.cos(angle.pitch),
        }
        return {x = eye.x, y = eye.y, z = eye.z}, dir
    end
end

-- Distance to a sphere along the ray, or nil. Called by gridshot.lua and peek.lua.
function Aim.sphere(eye, dir, cx, cy, cz, r)
    local x, y, z = cx - eye.x, cy - eye.y, cz - eye.z
    local along = x * dir.x + y * dir.y + z * dir.z
    local awaySquared = x * x + y * y + z * z - along * along
    if along > 0 and awaySquared < r * r then
        return along
    end
    return nil
end

-- Where along the ray it is between two sides of a box, on one axis. Called by Aim.box.
local function rayBetween(from, step, low, high)
    if step == 0 then
        if from < low or from > high then
            return math.huge, -math.huge
        end
        return -math.huge, math.huge
    end
    local toLow, toHigh = (low - from) / step, (high - from) / step
    return math.min(toLow, toHigh), math.max(toLow, toHigh)
end

-- Distance to a box along the ray, or nil. Called by peek.lua.
function Aim.box(eye, dir, minX, minY, minZ, maxX, maxY, maxZ)
    local nearX, farX = rayBetween(eye.x, dir.x, minX, maxX)
    local nearY, farY = rayBetween(eye.y, dir.y, minY, maxY)
    local nearZ, farZ = rayBetween(eye.z, dir.z, minZ, maxZ)
    local near = math.max(0, nearX, nearY, nearZ)
    local far = math.min(farX, farY, farZ)
    if near <= far then
        return near
    end
    return nil
end

return Aim
