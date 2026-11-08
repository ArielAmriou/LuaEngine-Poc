-- The game itself: targets appear, the player shoots them, then the score is shown.
--
--   menu --click--> playing --time is up--> results --R or click--> playing ...

-- same as config.conf
local SCREEN_W, SCREEN_H = 3000, 1876

-- the interface is laid out for a screen 720 px high, then scaled to the real one;
-- panel.png is 720x420
local UI = SCREEN_H / 720
local PANEL_X = (SCREEN_W - 720 * UI) / 2
local PANEL_Y = (SCREEN_H - 420 * UI) / 2

-- times in seconds
local ROUND_TIME = 30
local TARGET_LIFE = 2
local SPAWN_DELAY = 0.3
local MAX_TARGETS = 3

-- 'menu', 'playing' or 'results', and the seconds spent in it
local state = 'menu'
local stateTime = 0

-- the stats of the current round, filled by startRound
local round = {}
local bestScore = 0

-- {entity, alive, age, size} for each target
local targets = {}
-- the entities of the interface: hud, title, body, panel, hitmarker
local ui = {}
local hitSound
local hitmarkerTime = 0

------------------------------------------------------------------ helpers

-- Moves a 2D entity on screen. Called everywhere a sprite is placed or hidden.
local function moveTo(gm, entity, x, y)
    local pos = gm:getComponent(entity, 'Position2D')
    pos.x = x
    pos.y = y
end

-- Hides a 2D entity by moving it far outside the window.
-- Called by startRound (panel) and update (hit marker).
local function hide(gm, entity)
    moveTo(gm, entity, -10000, -10000)
end

-- Changes what a text entity shows. Called by the screens and updatePlaying (HUD).
local function setText(gm, entity, str)
    gm:getComponent(entity, 'Text2D').str = str
end

-- Creates a hidden 2D sprite from an image. Called by start.
local function newSprite(gm, path, scale)
    local entity = gm:createEntity()
    gm:addComponent(entity, 'Position2D', {x = -10000})
    gm:addComponent(entity, 'Texture2D', {path = path})
    gm:addComponent(entity, 'Sprite2D', {scale = scale})
    return entity
end

-- Creates an empty text at a place on screen, its size scaled to the screen.
-- Called by start.
local function newText(gm, x, y, size)
    local entity = gm:createEntity()
    gm:addComponent(entity, 'Position2D', {x = x, y = y})
    gm:addComponent(entity, 'Font', {path = 'assets/fonts/font.ttf'})
    gm:addComponent(entity, 'Text2D', {str = '', fontSize = size * UI})
    return entity
end

-- Rounds a number to the nearest integer. Called by shoot, accuracy and endRound.
local function toInt(x)
    return math.floor(x + 0.5)
end

-- The percentage of shots that hit. Called by updatePlaying (HUD) and endRound.
local function accuracy()
    if round.shots == 0 then
        return 100
    end
    return toInt(round.hits * 100 / round.shots)
end

------------------------------------------------------------------ targets

-- Hides a target under the floor until it is used again.
-- Called by shoot (hit), updateTargets (too old) and endRound.
local function removeTarget(gm, target)
    target.alive = false
    gm:getComponent(target.entity, 'Position3D').y = -100
end

-- Puts a target at a random place in front of the player, with a random size.
-- Called by updateTargets when a slot is free.
local function spawnTarget(gm, target)
    local pos = gm:getComponent(target.entity, 'Position3D')
    pos.x = math.random() * 12 - 6
    pos.y = math.random() * 5 + 1
    pos.z = math.random() * 5 - 14

    target.alive = true
    target.age = 0
    target.size = 0.5 + math.random() * 0.4
end

-- The radius of a target now: it shrinks to a third of its size before vanishing.
-- Called by updateTargets (to draw it) and aimedTarget (to hit it).
local function radiusOf(target)
    local timeLeft = 1 - target.age / TARGET_LIFE
    return target.size * (0.35 + 0.65 * timeLeft)
end

-- The target under the crosshair, or nil: a line from the eyes along the
-- camera's direction, tested against each target's sphere. Called by shoot.
local function aimedTarget(gm)
    for _, eye, angle in gm:view({'Position3D', 'CameraAngle'}) do
        -- the direction the camera looks at
        local dirX = math.sin(angle.yaw) * math.cos(angle.pitch)
        local dirY = math.sin(angle.pitch)
        local dirZ = -math.cos(angle.yaw) * math.cos(angle.pitch)

        for _, target in ipairs(targets) do
            if target.alive then
                local pos = gm:getComponent(target.entity, 'Position3D')
                local x, y, z = pos.x - eye.x, pos.y - eye.y, pos.z - eye.z

                -- how far the target is along the aim line, and away from it
                local along = x * dirX + y * dirY + z * dirZ
                local awaySquared = x * x + y * y + z * z - along * along

                if along > 0 and awaySquared < radiusOf(target) ^ 2 then
                    return target
                end
            end
        end
    end
    return nil
end

------------------------------------------------------------------ screens

-- Shows the start menu. Called once by start.
local function showMenu(gm)
    moveTo(gm, ui.panel, PANEL_X, PANEL_Y)
    setText(gm, ui.title, 'AIM TRAINER')
    setText(gm, ui.body,
        'Shoot the targets before they vanish.\n' ..
        'The faster the hit, the more points.\n' ..
        ROUND_TIME .. ' seconds per round.\n\n\n' ..
        '[Left click] start        [Esc] quit')
end

-- Resets the stats and hides the menu: the round begins.
-- Called by updateMenu and updateResults.
local function startRound(gm)
    state = 'playing'
    stateTime = 0
    round = {timeLeft = ROUND_TIME, score = 0, hits = 0, shots = 0, missed = 0,
             reactionTotal = 0, sinceLastHit = 0, nextSpawn = 0}

    hide(gm, ui.panel)
    setText(gm, ui.title, '')
    setText(gm, ui.body, '')
end

-- Removes the targets and shows the results of the round.
-- Called by updatePlaying when the time is up.
local function endRound(gm)
    state = 'results'
    stateTime = 0
    for _, target in ipairs(targets) do
        removeTarget(gm, target)
    end
    bestScore = math.max(bestScore, round.score)

    local reaction = '-'
    if round.hits > 0 then
        reaction = toInt(round.reactionTotal * 1000 / round.hits) .. ' ms'
    end

    moveTo(gm, ui.panel, PANEL_X, PANEL_Y)
    setText(gm, ui.hud, '')
    setText(gm, ui.title, 'SCORE ' .. round.score)
    setText(gm, ui.body,
        'Targets hit: ' .. round.hits .. '\n' ..
        'Targets missed: ' .. round.missed .. '\n' ..
        'Accuracy: ' .. accuracy() .. '%\n' ..
        'Average reaction: ' .. reaction .. '\n' ..
        'Best score: ' .. bestScore .. '\n\n' ..
        '[R] or [Left click] play again      [Q] quit')
end

------------------------------------------------------------------ each frame

-- In the menu: a click starts the round. Called by update.
local function updateMenu(gm)
    if gm:mouse():isPressed(MouseButton.Left) then
        startRound(gm)
    end
end

-- Counts a shot, and if it hits a target: score, reaction time, sound and
-- hit marker. Called by updatePlaying on a left click.
local function shoot(gm)
    round.shots = round.shots + 1

    local target = aimedTarget(gm)
    if target then
        local timeLeft = 1 - target.age / TARGET_LIFE
        round.hits = round.hits + 1
        round.score = round.score + toInt(50 + 100 * timeLeft)
        -- the reaction counts from when the player could start on this target:
        -- when it appeared, or the previous hit if the target was already there
        local reaction = math.min(target.age, round.sinceLastHit)
        round.reactionTotal = round.reactionTotal + reaction
        round.sinceLastHit = 0
        removeTarget(gm, target)

        gm:getComponent(hitSound, 'Sound').state = SoundState.PLAY
        hitmarkerTime = 0.15
    end
end

-- Ages and shrinks the targets, removes the ones too old, and spawns new ones
-- in the free slots. Called by updatePlaying.
local function updateTargets(gm, dt)
    round.nextSpawn = round.nextSpawn - dt
    round.sinceLastHit = round.sinceLastHit + dt

    for _, target in ipairs(targets) do
        if target.alive then
            target.age = target.age + dt
            if target.age >= TARGET_LIFE then
                round.missed = round.missed + 1
                removeTarget(gm, target)
            else
                gm:getComponent(target.entity, 'Sprite3D').scale = radiusOf(target)
            end
        elseif round.nextSpawn <= 0 then
            spawnTarget(gm, target)
            round.nextSpawn = SPAWN_DELAY
        end
    end
end

-- During a round: the timer, the shots, the targets and the HUD. Called by update.
local function updatePlaying(gm, dt)
    round.timeLeft = round.timeLeft - dt
    if round.timeLeft <= 0 then
        endRound(gm)
        return
    end

    if gm:mouse():isPressed(MouseButton.Left) then
        shoot(gm)
    end
    updateTargets(gm, dt)

    setText(gm, ui.hud,
        'SCORE ' .. round.score ..
        '      TIME ' .. math.ceil(round.timeLeft) ..
        '      ACCURACY ' .. accuracy() .. '%')
end

-- On the results: R or a click plays again, Q quits (the sounds are destroyed
-- first, as in render.lua, so the engine does not crash). Called by update.
local function updateResults(gm)
    -- wait a little, so that a last shot does not restart the round at once
    local click = stateTime > 0.8 and gm:mouse():isPressed(MouseButton.Left)

    if click or gm:keyboard():isPressed(Key.R) then
        startRound(gm)
    elseif gm:keyboard():isPressed(Key.Q) then
        for sound in gm:view({'Sound'}) do
            gm:destroyEntity(sound)
        end
        gm:stop()
    end
end

-- The game's system: runs the current state, and shows the hit marker for a
-- short time after a hit. Called by the engine every frame.
local function update(gm)
    local dt = gm:elapsed() / 1000
    stateTime = stateTime + dt

    if state == 'menu' then
        updateMenu(gm)
    elseif state == 'playing' then
        updatePlaying(gm, dt)
    else
        updateResults(gm)
    end

    hitmarkerTime = hitmarkerTime - dt
    if hitmarkerTime > 0 then
        moveTo(gm, ui.hitmarker, SCREEN_W / 2 - 20 * UI, SCREEN_H / 2 - 20 * UI)
    else
        hide(gm, ui.hitmarker)
    end
end

------------------------------------------------------------------ start

-- Creates the targets, the sounds and the interface, shows the menu, and
-- registers update. Called once by the engine at launch.
function start(gm)
    -- the targets are created once, then moved around and hidden
    for i = 1, MAX_TARGETS do
        local entity = gm:createEntity()
        gm:addComponent(entity, 'Position3D', {y = -100})
        gm:addComponent(entity, 'Model3D', {path = 'assets/models/target.glb'})
        gm:addComponent(entity, 'Sprite3D')
        targets[i] = {entity = entity, alive = false, age = 0, size = 1}
    end

    hitSound = gm:createEntity()
    gm:addComponent(hitSound, 'Sound', {path = 'assets/sounds/hit.wav'})

    -- 2D sprites are drawn in creation order: the panel goes over the crosshair
    local crosshair = newSprite(gm, 'assets/sprites/crosshair.png', UI)
    moveTo(gm, crosshair, SCREEN_W / 2 - 16 * UI, SCREEN_H / 2 - 16 * UI)
    ui.hitmarker = newSprite(gm, 'assets/sprites/hitmarker.png', UI)
    ui.panel = newSprite(gm, 'assets/sprites/panel.png', UI)

    ui.hud = newText(gm, 24 * UI, 18 * UI, 28)
    ui.title = newText(gm, PANEL_X + 50 * UI, PANEL_Y + 35 * UI, 56)
    ui.body = newText(gm, PANEL_X + 50 * UI, PANEL_Y + 125 * UI, 26)

    showMenu(gm)
    gm:createSystem(update)
end
