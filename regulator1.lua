-- Configuration
local TARGET_VOLTAGE = 240
local HEADROOM = 10
local TOLERANCE = 1.5  -- Adjust this if the arm still bounces (e.g., 2.0 or 3.0)
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

        -- Check if we are inside the acceptable "Target Zone"
        local is_equalized = math.abs(voltage - TARGET_VOLTAGE) <= TOLERANCE

        if is_equalized then
            -- Voltage is close enough to target; turn off adjustments and activate back
            back = true
        elseif voltage > TARGET_VOLTAGE then
            -- Voltage is too high (above target + tolerance)
            right = true
        else
            -- Voltage is lower than target (below target - tolerance)
            left = true
            
            -- If it's lower, but within the 10V headroom
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

