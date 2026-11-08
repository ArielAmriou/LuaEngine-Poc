-- Peek: mannequins run between crates and can only be shot in the gaps.
-- Headshots score more. The player can walk and jump in front of the crates.

local Aim = dofile('lib/aim.lua')
local Models = dofile('lib/models.lua')
local Movement = dofile('lib/movement.lua')
local Spatial = dofile('lib/spatial.lua')

local Peek = {}

-- meters and seconds; crate size as in assets/models/crate.glb
local CRATE_XS = {-6.75, -2.25, 2.25, 6.75}
local CRATE_Z = -12
local CRATE_W, CRATE_H, CRATE_D = 2, 2.1, 1

local LANE_Z = -13.3
local RUN_SPEED = 3.2
local SPAWN_DELAY = 0.8
local MAX_ENEMIES = 2
local DEATH_TIME = 1.2

-- hit zones, as spheres above the feet
local BODY = {{y = 0.5, r = 0.28}, {y = 0.95, r = 0.3}, {y = 1.3, r = 0.27}}
local HEAD = {y = 1.62, r = 0.15}
local HALF_WIDTH = 0.3
local BODY_POINTS, HEAD_POINTS = 100, 150
local TIME_TO_LEAVE_COVER = (CRATE_W / 2 - HALF_WIDTH) / RUN_SPEED

-- animation indexes in enemy_*.glb (tools/make_enemy.py), ms per frame
local DEATH_ANIM, RUN_ANIM = 0, 1
local ANIM_FRAME = 13

local WALK_MIN_X, WALK_MAX_X = -14, 14
local WALK_MIN_Z, WALK_MAX_Z = CRATE_Z + CRATE_D / 2 + 0.7, 7

local crates = {}
-- {entity, dir (1 = right), alive, dying, age, x, toX, pendingAnim}
local enemies = {}

-- Restarts a mannequin's animation. Called by spawnEnemy and Peek.shoot.
-- The engine cannot reset an animation: the component is removed now and
-- added back next frame by startPendingAnimation.
local function playAnimation(gm, enemy, index)
    if gm:hasComponent(enemy.entity, 'SpriteSheet3D') then
        gm:removeComponent(enemy.entity, 'SpriteSheet3D')
    end
    enemy.pendingAnim = index
end

-- Adds back the animation asked by playAnimation. Called by Peek.update.
local function startPendingAnimation(gm, enemy)
    if enemy.pendingAnim and not gm:hasComponent(enemy.entity, 'SpriteSheet3D') then
        gm:addComponent(enemy.entity, 'SpriteSheet3D', {index = enemy.pendingAnim, frameDuration = ANIM_FRAME})
        enemy.pendingAnim = nil
    end
end

-- Hides a mannequin and stops its footsteps. Called by Peek.update and Peek.clear.
local function removeEnemy(gm, enemy)
    enemy.alive = false
    enemy.dying = false
    Models.hide(gm, enemy.entity)
    Spatial.stop(gm, enemy.entity)
end

-- Sends a free mannequin from a random crate to the next one. Called by Peek.update.
local function spawnEnemy(gm)
    local from = math.random(#CRATE_XS)
    local dir = 1
    if from == #CRATE_XS or (from > 1 and math.random() < 0.5) then
        dir = -1
    end
    for _, enemy in ipairs(enemies) do
        if not enemy.alive and not enemy.dying and enemy.dir == dir then
            enemy.alive = true
            enemy.age = 0
            enemy.x = CRATE_XS[from]
            enemy.toX = CRATE_XS[from + dir]
            Models.place(gm, enemy.entity, enemy.x, 0, LANE_Z)
            Spatial.place(gm, enemy.entity, enemy.x, 0, LANE_Z)
            Spatial.play(gm, enemy.entity)
            playAnimation(gm, enemy, RUN_ANIM)
            return
        end
    end
end

-- Moves a running mannequin; it escapes when it reaches its crate. Called by Peek.update.
local function runEnemy(gm, round, enemy, dt)
    enemy.age = enemy.age + dt
    enemy.x = enemy.x + enemy.dir * RUN_SPEED * dt
    local arrived = (enemy.toX - enemy.x) * enemy.dir <= 0
    if arrived then
        round.missed = round.missed + 1
        removeEnemy(gm, enemy)
    else
        Models.place(gm, enemy.entity, enemy.x, 0, LANE_Z)
        Spatial.place(gm, enemy.entity, enemy.x, 0, LANE_Z)
    end
end

-- Distance to the first crate along the ray, or infinity. Called by Peek.shoot.
local function nearestCrate(eye, dir)
    local nearest = math.huge
    for _, x in ipairs(CRATE_XS) do
        local along = Aim.box(eye, dir,
            x - CRATE_W / 2, 0, CRATE_Z - CRATE_D / 2,
            x + CRATE_W / 2, CRATE_H, CRATE_Z + CRATE_D / 2)
        if along and along < nearest then
            nearest = along
        end
    end
    return nearest
end

-- Distance to a mannequin along the ray and whether it is a headshot, or nil.
-- Called by Peek.shoot.
local function enemyHitBy(eye, dir, enemy)
    local head = Aim.sphere(eye, dir, enemy.x, HEAD.y, LANE_Z, HEAD.r)
    if head then
        return head, true
    end
    for _, part in ipairs(BODY) do
        local along = Aim.sphere(eye, dir, enemy.x, part.y, LANE_Z, part.r)
        if along then
            return along, false
        end
    end
    return nil
end

-- Creates a hidden animated mannequin with its footsteps. Called by Peek.create.
local function newEnemy(gm, path)
    local entity = gm:createEntity()
    gm:addComponent(entity, 'Position3D')
    Models.hide(gm, entity)
    gm:addComponent(entity, 'Model3D', {path = path})
    gm:addComponent(entity, 'ModelAnimation3D', {path = path})
    gm:addComponent(entity, 'SpriteSheet3D', {index = RUN_ANIM, frameDuration = ANIM_FRAME})
    Spatial.attach(gm, entity, 'assets/sounds/steps.wav', true)
    return entity
end

-- Creates the crates and the mannequins. Called by round.lua at launch.
-- Models cannot turn: there is one running left and one running right.
function Peek.create(gm)
    for i = 1, #CRATE_XS do
        crates[i] = Models.new(gm, 'assets/models/crate.glb')
    end
    local models = {{dir = -1, path = 'assets/models/enemy_left.glb'},
                    {dir = 1, path = 'assets/models/enemy_right.glb'}}
    for _, model in ipairs(models) do
        for _ = 1, MAX_ENEMIES do
            enemies[#enemies + 1] = {entity = newEnemy(gm, model.path), dir = model.dir,
                                     alive = false, dying = false, age = 0, x = 0, toX = 0}
        end
    end
end

-- Shows the crates and puts the player at the start. Called by round.lua.
function Peek.start(gm)
    Movement.reset(gm)
    for i, crate in ipairs(crates) do
        Models.place(gm, crate, CRATE_XS[i], 0, CRATE_Z)
    end
end

-- Hides everything and puts the player back at the start. Called by round.lua.
function Peek.clear(gm)
    Movement.reset(gm)
    for _, crate in ipairs(crates) do
        Models.hide(gm, crate)
    end
    for _, enemy in ipairs(enemies) do
        removeEnemy(gm, enemy)
    end
end

-- Hits the nearest mannequin not behind a crate: returns points and reaction, or nil.
-- Called by round.lua on a click.
function Peek.shoot(gm, round)
    local eye, dir = Aim.ray(gm)
    local hit, headshot, nearest = nil, false, nearestCrate(eye, dir)
    for _, enemy in ipairs(enemies) do
        if enemy.alive then
            local along, head = enemyHitBy(eye, dir, enemy)
            if along and along < nearest then
                hit, headshot, nearest = enemy, head, along
            end
        end
    end
    if not hit then
        return nil
    end

    -- from when it left cover, or from the previous hit if it was already out
    local reaction = math.min(hit.age - TIME_TO_LEAVE_COVER, round.sinceLastHit)
    local points = BODY_POINTS
    if headshot then
        points = HEAD_POINTS
        round.headshots = round.headshots + 1
    end

    hit.alive = false
    hit.dying = true
    hit.age = 0
    playAnimation(gm, hit, DEATH_ANIM)
    Spatial.stop(gm, hit.entity)
    return points, reaction
end

-- Moves the player and the mannequins, and spawns new ones. Called by round.lua.
function Peek.update(gm, round, dt)
    Movement.update(gm, dt, WALK_MIN_X, WALK_MAX_X, WALK_MIN_Z, WALK_MAX_Z)

    local inUse = 0
    for _, enemy in ipairs(enemies) do
        startPendingAnimation(gm, enemy)
        if enemy.alive then
            runEnemy(gm, round, enemy, dt)
        elseif enemy.dying then
            enemy.age = enemy.age + dt
            if enemy.age >= DEATH_TIME then
                removeEnemy(gm, enemy)
            end
        end
        if enemy.alive or enemy.dying then
            inUse = inUse + 1
        end
    end

    if inUse < MAX_ENEMIES and round.spawnIn <= 0 then
        spawnEnemy(gm)
        round.spawnIn = SPAWN_DELAY
    end
end

-- The mode's lines of the results. Called by round.lua.
function Peek.results(round)
    return 'Mannequins hit: ' .. round.hits .. '  (headshots: ' .. round.headshots .. ')\n' ..
           'Mannequins escaped: ' .. round.missed .. '\n'
end

return Peek
