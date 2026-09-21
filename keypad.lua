-- Ultra-Compact Keypad for 1x1 Monitor (Fixed Enter Button)
local monitor = peripheral.find("monitor")
if not monitor then
    error("No monitor attached! Please attach a 1x1 monitor.")
end

local speaker = peripheral.find("speaker")
monitor.setTextScale(0.5)

local correctPassword = "123" -- Password
local inputBuffer = ""

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

    -- Display password feedback at top row
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.yellow)
    monitor.write("PW:" .. string.rep("*", string.len(inputBuffer)))

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
        elseif x >= 5 and x <= 7 then return "0"
        elseif x >= 10 and x <= 12 then return "E" end -- Fixed bounds for [E]
    end
    return nil
end

drawUI()

while true do
    local event, side, x, y = os.pullEvent()
    if event == "monitor_touch" then
        local btn = getButtonClicked(x, y)
        if btn then
            if btn >= "0" and btn <= "9" then
                if string.len(inputBuffer) < 6 then
                    inputBuffer = inputBuffer .. btn
                    playSound("click")
                end
            elseif btn == "L" then
                playSound("lock")
                rs.setOutput("left", true)
                sleep(0.5)
                rs.setOutput("left", false)
                inputBuffer = ""
            elseif btn == "E" then
                if inputBuffer == correctPassword then
                    playSound("correct")
                    monitor.setBackgroundColor(colors.green)
                    monitor.clear()
                    
                    rs.setOutput("back", true)
                    sleep(0.5)
                    rs.setOutput("back", false)
                    inputBuffer = ""
                else
                    playSound("wrong")
                    monitor.setBackgroundColor(colors.red)
                    monitor.clear()
                    sleep(0.5)
                    inputBuffer = ""
                end
            end
            drawUI()
        end
    end
end
