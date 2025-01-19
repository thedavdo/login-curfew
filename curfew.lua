
local startCurfew = {
    hour = 23,
    minute = 0
};

local endCurfew = {
    hour = 5,
    minute = 0
};

--Minutes before curfew to send warnings
local warningTimes = {60, 30, 15, 10, 5, 1}

-- Timezone offset from UTC, in hours 
local TIMEZONE = 0;

local WarnLabel = "WARN-"

local curfewWarnings = {};

local checkInterval = 5;

local function doCurfewWarn(minutes)

    local lbl = WarnLabel .. minutes

    if curfewWarnings[lbl] then
        return
    end

    curfewWarnings[lbl] = true;

    -- Send 8 messages so people can see it fill up in chat.
    for i = 1, 8 do
        SendWorldMessage("Curfew is in less than " .. minutes .. " minutes. Please finish up and go to bed.")
    end
end

local function PerformCurfewCheck(eventid, delay, repeats, worldobject)

    local players = GetPlayersInWorld()

    if not players then
        return
    end

    local playerCount = 0

    for k, ply in pairs(players) do
        playerCount = playerCount + 1
    end

    if (playerCount == 0) then
        return
    end

    local curTime = os.date("*t", os.time() + (TIMEZONE * 60 * 60))

    local minutesUntilCurfewStart = ((startCurfew.hour * 60) + startCurfew.minute) - ((curTime.hour * 60) + curTime.min)
    local minutesUntilCurfewEnd = ((endCurfew.hour * 60) + endCurfew.minute) - ((curTime.hour * 60) + curTime.min)

    print("Current time: " .. curTime.hour .. ":" .. curTime.min)
    print("Curfew start time: " .. startCurfew.hour .. ":" .. startCurfew.minute)
    print("Curfew end time: " .. endCurfew.hour .. ":" .. endCurfew.minute)
    print("Minutes until curfew start: " .. minutesUntilCurfewStart)
    print("Minutes until curfew end: " .. minutesUntilCurfewEnd)

    local warnSelection = -1;

    --Find closest warning message interval
    for _, warningTime in ipairs(warningTimes) do
        if (minutesUntilCurfewStart <= warningTime) then
            warnSelection = warningTime
        end
    end

    -- If we have a warning message to send, send it.
    if (warnSelection ~= -1 and not (minutesUntilCurfewStart < 0)) then
        doCurfewWarn(warnSelection)
    end

    -- Reset warnings if we are past curfew
    if ((minutesUntilCurfewEnd < minutesUntilCurfewStart) and (warnSelection == -1)) then
        curfewWarnings = {}
    end

    -- We are past the end of curfew, allow people to play.
    if ((minutesUntilCurfewEnd <= 0) and (minutesUntilCurfewStart > 0)) then
        return
    end

    -- We are before curfew, allow people to play.
    if (minutesUntilCurfewEnd > minutesUntilCurfewStart) then
        return
    end

    for k, ply in pairs(players) do
        Ban(0, ply:GetAccountName(), minutesUntilCurfewEnd * 60, "You are past curfew! See you in the morning!", "DAVDO - Lord of the Lua Domain & Curfew System")
    end
end

CreateLuaEvent(PerformCurfewCheck, checkInterval * 1000, 0)