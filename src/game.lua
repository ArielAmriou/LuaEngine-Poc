local function update(gm)
    if gm:windowShouldClose() then
        gm:stop()
    end
end

function start(gm)
    gm:createSystem(update)
end
