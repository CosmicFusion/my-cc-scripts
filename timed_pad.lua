-- Ultra-Compact Keypad for 1x1 Monitor (Fixed '0' button & Masking timer)
local monitor = peripheral.find("monitor")
if not monitor then
    error("No monitor attached! Please attach a 1x1 monitor.")
end

local speaker = peripheral.find("speaker")
monitor.setTextScale(0.5)

local correctPassword = "696942" -- Password
local inputBuffer = ""
local clearTimes = {}         -- Stores expiration time for each character to handle masking
local showDuration = 0.5      -- How many seconds characters remain visible before turning into '*'
local outputDuration = 0.5	-- How long the redstone signal is active.

local function playSound(name)
    if not speaker then return end
    if name == "click" then
        speaker.playNote("pling", 0.5, 12)
    elseif name == "correct" then
        speaker.playNote("bell", 1.0, 18)
    elseif name == "wrong" then
        speaker.playNote("bass", 1.0, 3)
    elseif name == "lock" then
        speaker.playNote("snare", 0.8, 10)
    end
end

local function drawUI()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    -- Build the display string based on expiration timers
    local displayStr = ""
    local currentTime = os.clock()
    for i = 1, string.len(inputBuffer) do
        if clearTimes[i] and currentTime < clearTimes[i] then
            displayStr = displayStr .. string.sub(inputBuffer, i, i)
        else
            displayStr = displayStr .. "*"
        end
    end

    -- Display password feedback at top row
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.yellow)
    monitor.write("PW:" .. displayStr .. "      ") -- trailing spaces to clear old text

    -- Compact 3x3 digit layout + Lock/Enter
    monitor.setCursorPos(2, 3); monitor.setTextColor(colors.white); monitor.write("[1][2][3]")
    monitor.setCursorPos(2, 5); monitor.setTextColor(colors.white); monitor.write("[4][5][6]")
    monitor.setCursorPos(2, 7); monitor.setTextColor(colors.white); monitor.write("[7][8][9]")
    monitor.setCursorPos(2, 9); monitor.setTextColor(colors.red);   monitor.write("[L]")
    monitor.setCursorPos(6, 9); monitor.setTextColor(colors.white); monitor.write("[0]")
    monitor.setCursorPos(10, 9); monitor.setTextColor(colors.green); monitor.write("[E]")
end

local function getButtonClicked(x, y)
    if y == 3 then
        if x >= 2 and x <= 4 then return "1"
        elseif x >= 5 and x <= 7 then return "2"
        elseif x >= 8 and x <= 10 then return "3" end
    elseif y == 5 then
        if x >= 2 and x <= 4 then return "4"
        elseif x >= 5 and x <= 7 then return "5"
        elseif x >= 8 and x <= 10 then return "6" end
    elseif y == 7 then
        if x >= 2 and x <= 4 then return "7"
        elseif x >= 5 and x <= 7 then return "8"
        elseif x >= 8 and x <= 10 then return "9" end
    elseif y == 9 then
        if x >= 2 and x <= 4 then return "L"
        elseif x >= 5 and x <= 7 then return "0"             -- Fixed hitbox for [0]
        elseif x >= 10 and x <= 12 then return "E" end
    end
    return nil
end

drawUI()

while true do
    -- We use a timer pull so the screen can refresh to mask characters when their time expires
    local timerId = os.startTimer(0.1)
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "monitor_touch" then
        local side, x, y = p1, p2, p3
        local btn = getButtonClicked(x, y)
        if btn then
            if btn >= "0" and btn <= "9" then
                if string.len(inputBuffer) < 6 then
                    inputBuffer = inputBuffer .. btn
                    -- Set expiration time for this newly added character
                    clearTimes[string.len(inputBuffer)] = os.clock() + showDuration
                    playSound("click")
                end
            elseif btn == "L" then
                playSound("lock")
                rs.setOutput("left", true)
                sleep(outputDuration)
                rs.setOutput("left", false)
                inputBuffer = ""
                clearTimes = {}
            elseif btn == "E" then
                if inputBuffer == correctPassword then
                    -- First Right Flash
                    playSound("correct")
                    monitor.setBackgroundColor(colors.green)
                    monitor.clear()
                    sleep(0.25)
                    drawUI()
                    sleep(0.25)
                    -- Second Right Flash
                    playSound("correct")
                    monitor.setBackgroundColor(colors.green)
                    monitor.clear()
                    sleep(0.25)
                    drawUI()
                    -- Output and Clear Buffers
                    rs.setOutput("back", true)
                    sleep(outputDuration)
                    rs.setOutput("back", false)
                    inputBuffer = ""
                    clearTimes = {}
                else
                    -- First Wrong Flash
                    playSound("wrong")
                    monitor.setBackgroundColor(colors.red)
                    monitor.clear()
                    sleep(0.25)
                    drawUI()
                    sleep(0.25)
                    -- Second Wrong Flash
                    playSound("wrong")
                    monitor.setBackgroundColor(colors.red)
                    monitor.clear()
                    sleep(0.25)
                    drawUI()
                    -- Clear Buffers
                    inputBuffer = ""
                    clearTimes = {}
                end
            end
            drawUI()
        end
    elseif event == "timer" then
        -- Periodically redraw to handle character masking expiration
        drawUI()
    end
end

