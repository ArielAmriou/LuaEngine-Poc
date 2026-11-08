-- Gridshot: targets appear and shrink until they vanish. Faster hits score more.

local Aim = dofile('lib/aim.lua')
local Models = dofile('lib/models.lua')
local Spatial = dofile('lib/spatial.lua')

local Gridshot = {}

-- seconds and meters
local TARGET_LIFE = 2
local SPAWN_DELAY = 0.3
local MAX_TARGETS = 3
local SPAWN_MIN_X, SPAWN_MAX_X = -6, 6
local SPAWN_MIN_Y, SPAWN_MAX_Y = 1, 6
local SPAWN_MIN_Z, SPAWN_MAX_Z = -14, -9
-- radius of a new target, and the part of it left when it vanishes
local MIN_SIZE, MAX_SIZE = 0.5, 0.9
local END_SIZE = 0.35
local BASE_POINTS, BONUS_POINTS = 50, 100

-- {entity, alive, age, size}
local targets = {}

-- A random number between low and high. Called by spawnTarget.
local function between(low, high)
    return low + math.random() * (high - low)
end

-- Hides a target. Called by Gridshot.shoot, Gridshot.update and Gridshot.clear.
local function removeTarget(gm, target)
    target.alive = false
    Models.hide(gm, target.entity)
end

-- Shows a target at a random place and plays its pop. Called by Gridshot.update.
local function spawnTarget(gm, target)
    local x = between(SPAWN_MIN_X, SPAWN_MAX_X)
    local y = between(SPAWN_MIN_Y, SPAWN_MAX_Y)
    local z = between(SPAWN_MIN_Z, SPAWN_MAX_Z)
    Models.place(gm, target.entity, x, y, z)
    Spatial.place(gm, target.entity, x, y, z)
    Spatial.play(gm, target.entity)
    target.alive = true
    target.age = 0
    target.size = between(MIN_SIZE, MAX_SIZE)
end

-- 1 when the target appears, 0 when it vanishes. Called by radiusOf and Gridshot.shoot.
local function lifeLeft(target)
    return 1 - target.age / TARGET_LIFE
end

-- The target's radius now. Called by Gridshot.update and Gridshot.shoot.
local function radiusOf(target)
    return target.size * (END_SIZE + (1 - END_SIZE) * lifeLeft(target))
end

-- Creates the targets. Called by round.lua at launch.
function Gridshot.create(gm)
    for i = 1, MAX_TARGETS do
        local entity = Models.new(gm, 'assets/models/target.glb')
        Spatial.attach(gm, entity, 'assets/sounds/pop.wav')
        targets[i] = {entity = entity, alive = false, age = 0, size = MIN_SIZE}
    end
end

-- Nothing to set up: the targets come with update. Called by round.lua.
function Gridshot.start(gm)
end

-- Hides every target. Called by round.lua.
function Gridshot.clear(gm)
    for _, target in ipairs(targets) do
        removeTarget(gm, target)
    end
end

-- Hits the nearest target under the crosshair: returns points and reaction, or nil.
-- Called by round.lua on a click.
function Gridshot.shoot(gm, round)
    local eye, dir = Aim.ray(gm)
    local hit, nearest = nil, math.huge
    for _, target in ipairs(targets) do
        if target.alive then
            local pos = gm:getComponent(target.entity, 'Position3D')
            local along = Aim.sphere(eye, dir, pos.x, pos.y, pos.z, radiusOf(target))
            if along and along < nearest then
                hit, nearest = target, along
            end
        end
    end
    if not hit then
        return nil
    end

    local points = BASE_POINTS + BONUS_POINTS * lifeLeft(hit)
    -- from when it appeared, or from the previous hit if it was already there
    local reaction = math.min(hit.age, round.sinceLastHit)
    removeTarget(gm, hit)
    return points, reaction
end

-- Ages, shrinks and removes the targets, and spawns new ones. Called by round.lua.
function Gridshot.update(gm, round, dt)
    for _, target in ipairs(targets) do
        if target.alive then
            target.age = target.age + dt
            if target.age >= TARGET_LIFE then
                round.missed = round.missed + 1
                removeTarget(gm, target)
            else
                local pos = gm:getComponent(target.entity, 'Position3D')
                gm:getComponent(target.entity, 'Sprite3D').scale = radiusOf(target)
                Spatial.place(gm, target.entity, pos.x, pos.y, pos.z)
            end
        elseif round.spawnIn <= 0 then
            spawnTarget(gm, target)
            round.spawnIn = SPAWN_DELAY
        end
    end
end

-- The mode's lines of the results. Called by round.lua.
function Gridshot.results(round)
    return 'Targets hit: ' .. round.hits .. '\n' ..
           'Targets missed: ' .. round.missed .. '\n'
end

return Gridshot
