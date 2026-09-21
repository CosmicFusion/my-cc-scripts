-- Configuration
local TARGET_VOLTAGE = 240
local HEADROOM = 10
local TOLERANCE = 2.0   
local LOOP_DELAY = 0.15  
local MIN_PULSE = 0.05   
local GAUGE = "powergrid_voltage_gauge_4"

-- Locate the peripheral
local gauge = peripheral.wrap(GAUGE)

if not gauge then
    error("Error: voltage gauge peripheral not found! Please check your connections.")
end

-- Force fresh baseline on startup
rs.setOutput("left", false)
rs.setOutput("right", false)
rs.setOutput("back", false)

print("=== Cosmo High-Efficiency Voltage Controller ===")
print("Target: " .. TARGET_VOLTAGE .. "V | Headroom: " .. HEADROOM .. "V | Tolerance: " .. TOLERANCE .. "V")
print("Press Ctrl+T to exit.\n")

-- Continuous Loop
while true do
    local success, voltage = pcall(function() return gauge.voltage() end)

    if success and voltage then
        local error_val = voltage - TARGET_VOLTAGE
        local abs_error = math.abs(error_val)
        
        print(string.format("Current Voltage: %.1fV (Error: %.1fV)", voltage, error_val))

        -- 1. FIXED SOLID BACK SIGNAL LOGIC
        -- Engages if we are within the stable target zone...
        -- OR if we are under-voltage but strictly inside the headroom window (between 230V and 240V)
        local back = false
        if abs_error <= TOLERANCE or (voltage >= (TARGET_VOLTAGE - HEADROOM) and voltage <= TARGET_VOLTAGE) then
            back = true
        end
        rs.setOutput("back", back)

        -- 2. PROPULSIVE ADJUSTMENT EVALUATION
        if abs_error <= TOLERANCE then
            -- System is stable inside target zone: Shut down adjustments immediately
            rs.setOutput("left", false)
            rs.setOutput("right", false)
            os.sleep(LOOP_DELAY)
        else
            -- Proportional pulse calculation
            local pulse_duration = LOOP_DELAY * (abs_error / 12)
            
            if pulse_duration < MIN_PULSE then pulse_duration = MIN_PULSE end
            if pulse_duration > LOOP_DELAY then pulse_duration = LOOP_DELAY end

            -- Asymmetrical execution directions
            if error_val < 0 then
                rs.setOutput("right", false) -- Interlock safety
                rs.setOutput("left", true)
            else
                rs.setOutput("left", false)  -- Interlock safety
                rs.setOutput("right", true)
            end
            
            -- Active modification step
            os.sleep(pulse_duration)

            -- Kill lines instantly to let Variac machinery glide safely
            rs.setOutput("left", false)
            rs.setOutput("right", false)
            
            -- Rest for whatever remainder time is left in the loop step
            local remainder = LOOP_DELAY - pulse_duration
            if remainder > 0 then
                os.sleep(remainder)
            end
        end
    else
        print("Error: Could not read voltage from gauge peripheral.")
        rs.setOutput("left", false)
        rs.setOutput("right", false)
        os.sleep(1.0)
    end
end

