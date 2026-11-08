local Quit = {}

-- Stops the game. Called by render.lua (Escape) and round.lua (Q).
-- The sounds are destroyed first: the engine crashes if it frees them after the audio.
function Quit.now(gm)
    for sound in gm:view({'Sound'}) do
        gm:destroyEntity(sound)
    end
    gm:stop()
end

return Quit
