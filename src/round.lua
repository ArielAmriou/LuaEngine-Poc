-- Menu, rounds and score. The modes (lib/gridshot.lua, lib/peek.lua) all have:
-- create(gm), start(gm), clear(gm), shoot(gm, round) -> points, reaction | nil,
-- update(gm, round, dt), results(round) -> text.

local Ui = dofile('lib/ui.lua')
local Quit = dofile('lib/quit.lua')
local MODES = {
    gridshot = dofile('lib/gridshot.lua'),
    peek = dofile('lib/peek.lua'),
}

-- seconds
local ROUND_TIME = 30
local HITMARKER_TIME = 0.15

-- image sizes in the 720 px layout
local CROSSHAIR_SIZE = 32
local HITMARKER_SIZE = 40
local PANEL_W, PANEL_H = 720, 420
local PANEL_X = (Ui.SCREEN_W - Ui.px(PANEL_W)) / 2
local PANEL_Y = (Ui.SCREEN_H - Ui.px(PANEL_H)) / 2
local TEXT_X = PANEL_X + Ui.px(50)

-- 'menu', 'playing' or 'results'
local state = 'menu'
local mode = 'gridshot'

local round = {}
local bestScore = {gridshot = 0, peek = 0}

local hud, title, body, panel, hitmarker
local hitSound
local hitmarkerTime = 0

-- Rounds to the nearest integer. Called by scoreHit, accuracy and endRound.
local function toInt(x)
    return math.floor(x + 0.5)
end

-- Percentage of shots that hit. Called by updatePlaying and endRound.
local function accuracy()
    if round.shots == 0 then
        return 100
    end
    return toInt(round.hits * 100 / round.shots)
end

-- Counts a hit, plays its sound and shows the hit marker. Called by updatePlaying.
local function scoreHit(gm, points, reaction)
    round.hits = round.hits + 1
    round.score = round.score + toInt(points)
    round.reactionTotal = round.reactionTotal + math.max(0, reaction)
    round.sinceLastHit = 0
    gm:getComponent(hitSound, 'Sound').state = SoundState.PLAY
    hitmarkerTime = HITMARKER_TIME
end

-- Shows the menu. Called by start and updateResults.
local function showMenu(gm)
    state = 'menu'
    Ui.center(gm, panel, PANEL_W, PANEL_H)
    Ui.setText(gm, title, 'AIM TRAINER')
    Ui.setText(gm, body,
        '[1] Gridshot\n' ..
        '     Shoot the targets before they shrink away.\n' ..
        '[2] Peek\n' ..
        '     Shoot the mannequins running between crates.\n' ..
        '     A headshot scores more.\n' ..
        '     [Z Q S D] move, [Space] jump.\n\n' ..
        ROUND_TIME .. ' seconds per round.          [Esc] quit')
end

-- Resets the stats and starts a round of a mode. Called by updateMenu and updateResults.
local function startRound(gm, newMode)
    MODES[mode].clear(gm)
    mode = newMode
    state = 'playing'
    round = {
        timeLeft = ROUND_TIME,
        score = 0,
        shots = 0,
        hits = 0,
        headshots = 0,
        missed = 0,
        reactionTotal = 0,
        sinceLastHit = 0,
        -- seconds before the mode may spawn something
        spawnIn = 0,
    }
    MODES[mode].start(gm)

    Ui.hide(gm, panel)
    Ui.setText(gm, title, '')
    Ui.setText(gm, body, '')
end

-- Clears the arena and shows the results. Called by updatePlaying.
local function endRound(gm)
    state = 'results'
    MODES[mode].clear(gm)
    bestScore[mode] = math.max(bestScore[mode], round.score)

    local reaction = '-'
    if round.hits > 0 then
        reaction = toInt(round.reactionTotal * 1000 / round.hits) .. ' ms'
    end

    Ui.center(gm, panel, PANEL_W, PANEL_H)
    Ui.setText(gm, hud, '')
    Ui.setText(gm, title, 'SCORE ' .. round.score)
    Ui.setText(gm, body,
        MODES[mode].results(round) ..
        'Accuracy: ' .. accuracy() .. '%\n' ..
        'Average reaction: ' .. reaction .. '\n' ..
        'Best score: ' .. bestScore[mode] .. '\n\n' ..
        '[R] play again     [M] menu     [Q] quit')
end

-- [1] or [2] starts a round. Called by update.
local function updateMenu(gm)
    local keyboard = gm:keyboard()
    if keyboard:isPressed(Key.Num1) or keyboard:isPressed(Key.Numpad1) then
        startRound(gm, 'gridshot')
    elseif keyboard:isPressed(Key.Num2) or keyboard:isPressed(Key.Numpad2) then
        startRound(gm, 'peek')
    end
end

-- Runs the timer, the shots, the mode and the HUD. Called by update.
local function updatePlaying(gm, dt)
    round.timeLeft = round.timeLeft - dt
    if round.timeLeft <= 0 then
        endRound(gm)
        return
    end

    if gm:mouse():isPressed(MouseButton.Left) then
        round.shots = round.shots + 1
        local points, reaction = MODES[mode].shoot(gm, round)
        if points then
            scoreHit(gm, points, reaction)
        end
    end

    round.spawnIn = round.spawnIn - dt
    round.sinceLastHit = round.sinceLastHit + dt
    MODES[mode].update(gm, round, dt)

    Ui.setText(gm, hud,
        'SCORE ' .. round.score ..
        '      TIME ' .. math.ceil(round.timeLeft) ..
        '      ACCURACY ' .. accuracy() .. '%')
end

-- [R] replays, [M] goes to the menu, [Q] quits. Called by update.
local function updateResults(gm)
    local keyboard = gm:keyboard()
    if keyboard:isPressed(Key.R) then
        startRound(gm, mode)
    elseif keyboard:isPressed(Key.M) then
        showMenu(gm)
    elseif keyboard:isPressed(Key.Q) then
        Quit.now(gm)
    end
end

-- Shows the hit marker for a moment after a hit. Called by update.
local function updateHitmarker(gm, dt)
    hitmarkerTime = hitmarkerTime - dt
    if hitmarkerTime > 0 then
        Ui.center(gm, hitmarker, HITMARKER_SIZE, HITMARKER_SIZE)
    else
        Ui.hide(gm, hitmarker)
    end
end

-- Runs the current screen. Called by the engine every frame.
local function update(gm)
    local dt = gm:elapsed() / 1000

    if state == 'menu' then
        updateMenu(gm)
    elseif state == 'playing' then
        updatePlaying(gm, dt)
    else
        updateResults(gm)
    end
    updateHitmarker(gm, dt)
end

-- Creates the modes, the interface and the systems. Called by the engine at launch.
function start(gm)
    for _, m in pairs(MODES) do
        m.create(gm)
    end

    hitSound = gm:createEntity()
    gm:addComponent(hitSound, 'Sound', {path = 'assets/sounds/hit.wav'})

    -- sprites are drawn in creation order: the panel covers the crosshair
    local crosshair = Ui.newSprite(gm, 'assets/sprites/crosshair.png')
    Ui.center(gm, crosshair, CROSSHAIR_SIZE, CROSSHAIR_SIZE)
    hitmarker = Ui.newSprite(gm, 'assets/sprites/hitmarker.png')
    panel = Ui.newSprite(gm, 'assets/sprites/panel.png')

    hud = Ui.newText(gm, Ui.px(24), Ui.px(18), 28)
    title = Ui.newText(gm, TEXT_X, PANEL_Y + Ui.px(35), 56)
    body = Ui.newText(gm, TEXT_X, PANEL_Y + Ui.px(125), 26)

    showMenu(gm)
    gm:createSystem(update)
    gm:addSystem('MasterAnimateSpriteSheet3D')
    gm:addSystem('Sound2D')
end
