-- ============================================================================
-- Cosmo Nuclear Systems - Reactor Control Panel
-- Target: 3x6 Advanced Monitor
-- ============================================================================

-- CONFIGURATION VARIABLES
local TARGET_PERIPHERAL = "create_target"
local STRESS_PERIPHERAL = "Create_Stressometer"
local SPEED_PERIPHERAL = "Create_Speedometer"
local SPEAKER_PERIPHERAL = "speaker"
local MONITOR_PERIPHERAL = "monitor"

local SU_PER_REACTOR = 2068480  -- SU capacity supplied by a single subreactor
local TOTAL_SUBREACTORS = 8     -- Expected total amount of subreactors
local REFRESH_RATE = 5.0        -- Update interval in seconds
local MAX_RPM_SCALE = 512       -- Max RPM scale for the visual progress bar

-- WRAP PERIPHERALS
local targetBlock = peripheral.find(TARGET_PERIPHERAL)
local stressometer = peripheral.find(STRESS_PERIPHERAL)
local speedometer = peripheral.find(SPEED_PERIPHERAL)
local speaker = peripheral.find(SPEAKER_PERIPHERAL)
local monitor = peripheral.find(MONITOR_PERIPHERAL)

if not monitor then
    error("Advanced monitor not found! Please attach one.")
end

monitor.setTextScale(0.5)
local width, height = monitor.getSize()

-- HELPER: Get fuel percentages using getLine()
local function getFuelPercentages()
    local uraniumPercent = 0
    local graphitePercent = 0

    if targetBlock and targetBlock.getLine then
        pcall(function()
            local uLine = targetBlock.getLine(1)
            if uLine then
                uraniumPercent = tonumber(string.match(uLine, "(%d+)%%")) or 0
            end

            local gLine = targetBlock.getLine(2)
            if gLine then
                graphitePercent = tonumber(string.match(gLine, "(%d+)%%")) or 0
            end
        end)
    end

    return uraniumPercent, graphitePercent
end

-- HELPER: Draw a vertical progress bar (fills from bottom to top)
local function drawVerticalBar(startX, startY, barHeight, current, maxVal, barColor, emptyColor)
    current = current or 0
    if not maxVal or maxVal <= 0 then maxVal = 1 end
    
    local filledRows = math.floor((current / maxVal) * barHeight + 0.5)
    if filledRows > barHeight then filledRows = barHeight end
    if filledRows < 0 then filledRows = 0 end

    for i = 0, barHeight - 1 do
        local yPos = (startY + barHeight - 1) - i
        monitor.setCursorPos(startX, yPos)
        
        if i < filledRows then
            monitor.setTextColor(barColor)
            monitor.write("[||]")
        else
            monitor.setTextColor(emptyColor)
            monitor.write("[  ]")
        end
    end
end

-- HELPER: Draw custom UI layout
local function drawUI(uraniumPct, graphitePct, stressUsed, stressCap, rpm, onlineReactors, hasError)
    monitor.clear()
    
    -- Title Banner (Centered dynamically)
    local title1 = "======== Cosmo Nuclear Systems ========"
    local title2 = "=== Reactor Control Panel ==="
    
    monitor.setCursorPos(math.floor((width - string.len(title1)) / 2) + 1, 1)
    monitor.setTextColor(colors.cyan)
    monitor.write(title1)
    
    monitor.setCursorPos(math.floor((width - string.len(title2)) / 2) + 1, 2)
    monitor.setTextColor(colors.yellow)
    monitor.write(title2)

    -- Dividers (Cross layout)
    local midX = math.floor(width / 2)
    for y = 3, height do
        monitor.setCursorPos(midX, y)
        monitor.setTextColor(colors.blue)
        monitor.write("|")
    end
    for x = 1, width do
        monitor.setCursorPos(x, 11)
        monitor.setTextColor(colors.blue)
        monitor.write("-")
    end

    -- ----------------------------------------------------
    -- TOP-LEFT: Fuel Info
    -- ----------------------------------------------------
    monitor.setCursorPos(3, 4)
    monitor.setTextColor(colors.lightBlue)
    monitor.write("Fuel Info")

    -- Uranium Bar (Column 3, height 4) - Using 100 max scale for percentage
    drawVerticalBar(3, 6, 4, uraniumPct, 100, colors.green, colors.gray)

    -- Graphite Bar (Column 12, height 4) - Using 100 max scale for percentage
    drawVerticalBar(12, 6, 4, graphitePct, 100, colors.white, colors.gray)

    monitor.setCursorPos(2, 10)
    monitor.setTextColor(colors.green)
    monitor.write(string.format("Uranium: %d%%", uraniumPct))
    
    monitor.setCursorPos(18, 10)
    monitor.setTextColor(colors.white)
    monitor.write(string.format("Graphite: %d%%", graphitePct))

    -- ----------------------------------------------------
    -- TOP-RIGHT: Stress Info
    -- ----------------------------------------------------
    monitor.setCursorPos(midX + 6, 4)
    monitor.setTextColor(colors.lightBlue)
    monitor.write("Stress Info:")

    local stressPercent = 0
    if stressCap and stressCap > 0 then
        stressPercent = math.floor(((stressUsed or 0) / stressCap) * 100)
    end

    monitor.setCursorPos(midX + 4, 7)
    monitor.setTextColor(colors.cyan)
    monitor.write(string.format("%d%% SU", stressPercent))

    local safeStressCap = (stressCap and stressCap > 0) and stressCap or 100
    drawVerticalBar(midX + 13, 5, 5, stressUsed, safeStressCap, colors.blue, colors.gray)

    -- ----------------------------------------------------
    -- BOTTOM-LEFT: Sub Reactor Status
    -- ----------------------------------------------------
    monitor.setCursorPos(3, 13)
    monitor.setTextColor(colors.lightBlue)
    monitor.write("Sub reactor status")

    monitor.setCursorPos(6, 15)
    monitor.setTextColor(colors.cyan)
    monitor.write("Online Sub reactors:")

    monitor.setCursorPos(11, 18)
    monitor.setTextColor(colors.white)
    monitor.write(string.format("%d/%d", onlineReactors, TOTAL_SUBREACTORS))

    -- Critical Error Box / Text
    if hasError then
        monitor.setCursorPos(5, 21)
        monitor.setTextColor(colors.red)
        monitor.write("Critical Error")
    end

    -- ----------------------------------------------------
    -- BOTTOM-RIGHT: Reactor RPM
    -- ----------------------------------------------------
    monitor.setCursorPos(midX + 6, 13)
    monitor.setTextColor(colors.lightBlue)
    monitor.write("Reactor RPM:")

    monitor.setCursorPos(midX + 4, 17)
    monitor.setTextColor(colors.cyan)
    monitor.write(string.format("%d RPM", rpm))

    drawVerticalBar(midX + 13, 14, 5, rpm, MAX_RPM_SCALE, colors.blue, colors.gray)
end

-- SHARED STATE FOR ERROR / BEEPING
local currentHasError = false

-- THREAD 1: Alarm Sound Loop (Beeps independently every 0.8 seconds if in error)
local function alarmLoop()
    while true do
        if currentHasError and speaker then
            pcall(function()
                speaker.playNote("pling", 1.0, 1.0)
            end)
        end
        sleep(0.8)
    end
end

-- THREAD 2: Main Data Gathering & UI Refresh Loop
local function monitorLoop()
    while true do
        local uraniumPct, graphitePct = getFuelPercentages()

        -- Gather Stress Data
        local stressUsed = 0
        local stressCap = 0
        local isOverstressed = false

        if stressometer then
            pcall(function()
                if stressometer.getStress then stressUsed = stressometer.getStress()
                elseif stressometer.getNetworkStress then stressUsed = stressometer.getNetworkStress() end
                
                if stressometer.getStressCapacity then stressCap = stressometer.getStressCapacity()
                elseif stressometer.getMaxStress then stressCap = stressometer.getMaxStress()
                elseif stressometer.getCapacity then stressCap = stressometer.getCapacity() end
            end)
        end

        if stressCap and stressCap > 0 and (stressUsed or 0) > stressCap then
            isOverstressed = true
        end

        -- Gather Speed Data (Robust fallbacks)
        local rpm = 0
        if speedometer then
            pcall(function()
                if speedometer.getSpeed then rpm = speedometer.getSpeed()
                elseif speedometer.getRPM then rpm = speedometer.getRPM()
                elseif speedometer.getSpeedometerSpeed then rpm = speedometer.getSpeedometerSpeed() end
            end)
        end

        -- Calculate Subreactor Status
        local onlineReactors = 0
        if stressCap and stressCap > 0 and SU_PER_REACTOR > 0 then
            onlineReactors = math.floor(stressCap / SU_PER_REACTOR)
        end
        
        if onlineReactors > TOTAL_SUBREACTORS then
            onlineReactors = TOTAL_SUBREACTORS
        elseif onlineReactors < 0 then
            onlineReactors = 0
        end

        currentHasError = (onlineReactors < TOTAL_SUBREACTORS) or isOverstressed

        drawUI(uraniumPct, graphitePct, stressUsed, stressCap, rpm, onlineReactors, currentHasError)

        sleep(REFRESH_RATE)
    end
end

-- Run both tasks concurrently using the parallel API
parallel.waitForAll(monitorLoop, alarmLoop)
