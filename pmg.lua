-- Configuration Variables
local mains_power_gauge_name = "powergrid_power_gauge_0"
local mains_voltage_gauge_name = "powergrid_voltage_gauge_0"
local gen1_voltage_gauge_name  = "powergrid_voltage_gauge_1"
local gen2_voltage_gauge_name  = "powergrid_voltage_gauge_2"
local gen3_voltage_gauge_name  = "powergrid_voltage_gauge_3"
local gen4_voltage_gauge_name  = "powergrid_voltage_gauge_4"
local gen5_voltage_gauge_name  = "powergrid_voltage_gauge_5"

local minimum_mains_voltage = 76000.0
local maximum_mains_power = 1000000.0
local maximum_off_voltage = 5.0

-- Find and Wrap Monitor and Peripherals
local monitor = peripheral.find("monitor")
if not monitor then
    error("No monitor found! Please attach a 3x6 advanced monitor.")
end

if not monitor.isColor() then
    error("An Advanced Monitor is required for this GUI.")
end

monitor.setTextScale(0.5)
local monitorWidth, monitorHeight = monitor.getSize()

local speaker = peripheral.find("speaker")

local function wrapGauge(name)
    local p = peripheral.wrap(name)
    if p then return p end
    return {
        voltage = function() return 400000.0 end,
        power = function() return 600000.0 end
    }
end

local mains_power_gauge = wrapGauge(mains_power_gauge_name)
local mains_voltage_gauge = wrapGauge(mains_voltage_gauge_name)
local gen_gauges = {
    wrapGauge(gen1_voltage_gauge_name),
    wrapGauge(gen2_voltage_gauge_name),
    wrapGauge(gen3_voltage_gauge_name),
    wrapGauge(gen4_voltage_gauge_name),
    wrapGauge(gen5_voltage_gauge_name)
}

local function formatVoltage(v)
    if v >= 1000 then
        return string.format("%.1f KV", v / 1000)
    else
        return string.format("%.0f volt", v)
    end
end

local function formatPower(p)
    if p >= 1000 then
        return string.format("%.1f KW", p / 1000)
    else
        return string.format("%.0fW", p)
    end
end

local btnX1, btnY1, btnX2, btnY2 = 4, 6, 18, 10

local function drawGUI(mainsVolt, mainsPower, genStates, errors, btnState)
    monitor.clear()
    
    local bgCol = colors.black
    local textCol = colors.white
    local blueCol = colors.lightBlue
    local redCol = colors.red
    local greenCol = colors.green
    
    monitor.setBackgroundColor(bgCol)
    
    -- Titles (Centered)
    local title1 = "======= Cosmo Nuclear Systems ======="
    local title2 = "=== Generator Control Panel ==="
    
    monitor.setCursorPos(math.floor((monitorWidth - string.len(title1)) / 2) + 1, 1)
    monitor.setTextColor(blueCol)
    monitor.write(title1)
    
    monitor.setCursorPos(math.floor((monitorWidth - string.len(title2)) / 2) + 1, 2)
    monitor.setTextColor(redCol)
    monitor.write(title2)
    
    local midX = math.floor(monitorWidth / 2)
    local midY = math.floor(monitorHeight / 2) + 1
    
    monitor.setTextColor(blueCol)
    for y = 4, monitorHeight do
        monitor.setCursorPos(midX, y)
        monitor.write("|")
    end
    for x = 1, monitorWidth do
        monitor.setCursorPos(x, midY)
        monitor.write("-")
    end
    
    -- System Controls
    monitor.setCursorPos(3, 4)
    monitor.setTextColor(blueCol)
    monitor.write("System Controls:")
    
    monitor.setBackgroundColor(btnState == "OFF" and greenCol or redCol)
    monitor.setTextColor(colors.white)
    for y = btnY1, btnY2 do
        monitor.setCursorPos(btnX1, y)
        monitor.write(string.rep(" ", btnX2 - btnX1 + 1))
    end
    monitor.setCursorPos(math.floor((btnX1 + btnX2) / 2) - 1, math.floor((btnY1 + btnY2) / 2))
    monitor.write(btnState)
    monitor.setBackgroundColor(bgCol)
    
    -- Output Voltage
    monitor.setCursorPos(midX + 3, 4)
    monitor.setTextColor(blueCol)
    monitor.write("Output Voltage:")
    
    monitor.setCursorPos(midX + 3, 7)
    monitor.setTextColor(textCol)
    monitor.write(formatVoltage(mainsVolt))
    
    if errors.voltage then
        monitor.setCursorPos(midX + 3, 9)
        monitor.setTextColor(redCol)
        monitor.write("Critical Error")
    end
    
    -- Generators Status
    monitor.setCursorPos(3, midY + 1)
    monitor.setTextColor(blueCol)
    monitor.write("Generators status")
    
    for i, state in ipairs(genStates) do
        local gx = (i <= 3) and 3 or (midX - 12)
        local gy = midY + 2 + ((i - 1) % 3)
        monitor.setCursorPos(gx, gy)
        monitor.setTextColor(textCol)
        monitor.write(string.format("G%d: %s", i-1, state))
    end
    
    if errors.gens then
        monitor.setCursorPos(3, monitorHeight - 1)
        monitor.setTextColor(redCol)
        monitor.write("Critical Error")
    end
    
    -- Output Power
    monitor.setCursorPos(midX + 3, midY + 1)
    monitor.setTextColor(blueCol)
    monitor.write("Output Power Cons:")
    
    monitor.setCursorPos(midX + 3, midY + 6)
    monitor.setTextColor(textCol)
    monitor.write(formatPower(mainsPower))
    
    local barX = midX + 22
    local barY1 = midY + 3
    local barY2 = monitorHeight - 2
    local barHeight = barY2 - barY1 + 1
    
    monitor.setTextColor(blueCol)
    for bx = barX, barX + 4 do
        monitor.setCursorPos(bx, barY1)
        monitor.write("-")
        monitor.setCursorPos(bx, barY2)
        monitor.write("-")
    end
    for by = barY1, barY2 do
        monitor.setCursorPos(barX, by)
        monitor.write("|")
        monitor.setCursorPos(barX + 4, by)
        monitor.write("|")
    end
    
    local powerRatio = math.min(math.max(mainsPower / maximum_mains_power, 0), 1)
    local fillHeight = math.floor(barHeight * powerRatio)
    monitor.setBackgroundColor(colors.white)
    for by = barY2 - 1, barY2 - fillHeight, -1 do
        for bx = barX + 1, barX + 3 do
            monitor.setCursorPos(bx, by)
            monitor.write(" ")
        end
    end
    monitor.setBackgroundColor(bgCol)
    
    if errors.power then
        monitor.setCursorPos(midX + 3, monitorHeight - 1)
        monitor.setTextColor(redCol)
        monitor.write("Critical Error")
    end
end

-- Main Event Loop Variables
local alarmTimer = nil

while true do
    local successVolt, mainsVolt = pcall(function() return mains_voltage_gauge.voltage() end)
    if not successVolt then mainsVolt = 0.0 end

    local successPower, mainsPower = pcall(function() return mains_power_gauge.power() end)
    if not successPower then mainsPower = 0.0 end

    local genStates = {}
    local anyGenOff = false
    for i, gauge in ipairs(gen_gauges) do
        local ok, v = pcall(function() return gauge.voltage() end)
        if not ok then v = 0.0 end
        if v <= maximum_off_voltage then
            table.insert(genStates, "OFF")
            anyGenOff = true
        else
            table.insert(genStates, "ON")
        end
    end

    local btnVisualState = (mainsVolt <= maximum_off_voltage) and "OFF" or "ON"

    local voltageError = (mainsVolt > maximum_off_voltage) and (mainsVolt < minimum_mains_voltage)
    local powerError = mainsPower > maximum_mains_power
    local gensError = anyGenOff

    local errors = {
        voltage = voltageError,
        power = powerError,
        gens = gensError
    }

    -- Redstone Output Logic (Left side)
    if voltageError or powerError then
        redstone.setOutput("left", true)
    else
        redstone.setOutput("left", false)
    end

    -- Draw current GUI state
    drawGUI(mainsVolt, mainsPower, genStates, errors, btnVisualState)

    -- Handle Pulsing Alarm Timer for Errors
    if (gensError or voltageError or powerError) then
        if not alarmTimer then
            alarmTimer = os.startTimer(0.4)
        end
    else
        alarmTimer = nil
    end

    -- Event Handling
    local event, p1, p2, p3 = os.pullEvent()
    if event == "monitor_touch" then
        local tSide, tX, tY = p1, p2, p3
        if tX >= btnX1 and tX <= btnX2 and tY >= btnY1 and tY <= btnY2 then
            -- Play beep sound on button click
            if speaker then
                pcall(function() speaker.playNote("bell", 0.5, 1) end)
            end
            -- Emit redstone pulse from the left side regardless of voltage
            redstone.setOutput("left", true)
            os.sleep(0.2)
            redstone.setOutput("left", false)
        end
    elseif event == "timer" then
        if p1 == alarmTimer then
            if speaker then
                pcall(function() speaker.playNote("bell", 0.5, 1) end)
            end
            alarmTimer = os.startTimer(0.4) -- restart timer for next error pulse
        end
    end
end
