-- Configuration: Change these sides to match your setup
local inputSide = "front"
local outputSide = "back"

print("Redstone Inverter Active")
print("Listening on: " .. inputSide)
print("Outputting to: " .. outputSide)

-- Run the loop forever
while true do
    -- Read the current input (true if powered, false if not)
    local inputSignal = redstone.getInput(inputSide)
    
    -- Invert the signal using 'not'
    local invertedSignal = not inputSignal
    
    -- Output the inverted signal
    redstone.setOutput(outputSide, invertedSignal)
    
    -- Wait efficiently until any redstone state changes in the world
    os.pullEvent("redstone")
end
z
