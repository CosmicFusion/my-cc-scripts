while true do
    -- 1. Read the current signal strength
    local input = rs.getAnalogueInput("back") -- Change "back" to your input side
    local output

    -- 2. Apply your inverted logic with the 0 exception
    if input == 0 then
        output = 14
    else
        output = 15 - input
    end

    -- 3. Update the output signal
    rs.setAnalogueOutput("front", output) -- Change "front" to your output side

    -- 4. Sleep/Wait until a redstone update happens elsewhere
    os.pullEvent("redstone")
end

