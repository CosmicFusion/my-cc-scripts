-- Configuration
local TARGET_VOLTAGE = 240
local HEADROOM = 10
local TOLERANCE = 1.5  -- Buffer zone around the target
local LOOP_DELAY = 1.0 -- Time in seconds between updates
local GAUGE = "powergrid_voltage_gauge_4"

-- Locate the peripheral
local gauge = peripheral.wrap(GAUGE)

if not gauge then
    error("Error: voltage gauge peripheral not found! Please check your connections.")
end

print("=== Cosmo Voltage Regulation Controller Active ===")
print("Target: " .. TARGET_VOLTAGE .. "V | Headroom: " .. HEADROOM .. "V | Tolerance: " .. TOLERANCE .. "V")
print("Press Ctrl+T to exit.\n")

-- Continuous Loop
while true do
    local success, voltage = pcall(function() return gauge.voltage() end)

    if success and voltage then
        print(string.format("Current Voltage: %.1fV", voltage))

        -- Default all states to false (off)
        local left = false
        local right = false
        local back = false

        -- Calculate explicit boundaries
        local max_acceptable = TARGET_VOLTAGE + TOLERANCE
        local min_acceptable = TARGET_VOLTAGE - TOLERANCE

        if voltage > max_acceptable then
            -- Voltage is explicitly too high -> force right side to turn on and bring it down
            right = true
        elseif voltage < min_acceptable then
            -- Voltage is explicitly too low -> force left side to turn on
            left = true
            
            -- If it's low, but within the 10V headroom (e.g., between 230V and 238.5V)
            if voltage >= (TARGET_VOLTAGE - HEADROOM) then
                back = true
            end
        else
            -- Voltage is within the perfect target zone (e.g., 238.5V to 241.5V)
            back = true
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

