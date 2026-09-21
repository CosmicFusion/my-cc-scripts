-- Configuration
local TARGET_VOLTAGE = 240
local HEADROOM = 10
local LOOP_DELAY = 1.0 -- Time in seconds between updates

-- Locate the peripheral
local gauge = peripheral.find("power_grid_voltage_gauge")

if not gauge then
    error("Error: 'power_grid_voltage_gauge' peripheral not found! Please check your connections.")
end

print("=== Power Grid Controller Active ===")
print("Target: " .. TARGET_VOLTAGE .. "V | Headroom: " .. HEADROOM .. "V")
print("Press Ctrl+T to exit.\n")

-- Continuous Loop
while true do
    -- Wrap in a pcall to prevent crashes if the method name varies slightly in your modpack
    local success, voltage = pcall(function() return gauge.getVoltage() end)
    
    if not success then
        -- Fallback: try common alternatives like .getVoltageValue() or .get() if needed
        success, voltage = pcall(function() return gauge.getVoltageValue() end)
    end

    if success and voltage then
        print(string.format("Current Voltage: %.1fV", voltage))

        -- Default all states to false (off)
        local left = false
        local right = false
        local back = false

        if voltage == TARGET_VOLTAGE then
            -- Perfectly equalized
            back = true
        elseif voltage > TARGET_VOLTAGE then
            -- Voltage is too high
            right = true
        else
            -- Voltage is lower than target
            left = true
            
            -- If it's lower, but within the 10V headroom (e.g., 230 to 239.9)
            if voltage >= (TARGET_VOLTAGE - HEADROOM) then
                back = true
            end
        end

        -- Output the Redstone Signals
        rs.setOutput("left", left)
        rs.setOutput("right", right)
        rs.setOutput("back", back)
    else
        print("Error: Could not read voltage from gauge peripheral.")
    end

    -- Wait before looping again to prevent lagging the game
    os.sleep(LOOP_DELAY)
end

