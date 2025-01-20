
--Config for users to change to their liking.
local CurfewConfig = {
    -- Curfew start time
    startCurfew = {
        hour = 22,
        minute = 15
    },

    -- Curfew end time
    endCurfew = {
        hour = 4,
        minute = 30
    },

    -- Minutes before curfew to send warnings
    warningTimes = {60, 30, 15, 10, 5, 1},

    -- Timezone offset from UTC, in hours 
    TIMEZONE = 0,

    -- Interval in seconds to check for curfew checking
    checkInterval = 5,
}

-----------------------------------------------------
-- DO NOT EDIT BELOW THIS LINE ----------------------
-----------------------------------------------------

--Look up table to track warnings
local curfewWarnings = {};

--String make look up take work better with numbers.
local WARN_LABEL = "WARN-"

local function DoCurfewWarnings(curTime, minutesUntilCurfewStart, minutesUntilCurfewEnd)

    -- Curfew is behind us.
    if (minutesUntilCurfewStart < 0) then
        return
    end

    -- local closestWarningTime = -1;
    local warnSelection = -1;

    -- Find closest warning message interval
    for _, warningTime in ipairs(CurfewConfig.warningTimes) do
        if (minutesUntilCurfewStart <= warningTime) then

            -- If we have not found a warning message yet, 
            -- or if this warning time is closer to the current time than the most recent one, set it as the most recent.
            if (warnSelection == -1 or warningTime < warnSelection) then
                -- closestWarningTime = warningTime
                warnSelection = warningTime
            end
        end
    end

    -- If we don't have a warning message to send, stop here.
    if (warnSelection == -1) then
        return
    end

    -- Reset warnings if we are past curfew
    if ((minutesUntilCurfewEnd < minutesUntilCurfewStart) and (warnSelection == -1)) then
        curfewWarnings = {}
    end

    local lbl = WARN_LABEL .. warnSelection

    if curfewWarnings[lbl] then
        return
    end

    curfewWarnings[lbl] = true;

    print("-----------------------------------------------------")
    print("Current time: " .. curTime.hour .. ":" .. curTime.min)
    print("Curfew start time: " .. CurfewConfig.startCurfew.hour .. ":" .. CurfewConfig.startCurfew.minute)
    print("Curfew end time: " .. CurfewConfig.endCurfew.hour .. ":" .. CurfewConfig.endCurfew.minute)
    print("Minutes until curfew start: " .. minutesUntilCurfewStart)
    print("Minutes until curfew end: " .. minutesUntilCurfewEnd)
    print("-----------------------------------------------------")

    local msg = "Curfew is in less than " .. warnSelection .. " minutes. Please finish up and go to bed."

    print(msg)

    -- Send 8 messages so people can see it fill up in chat.
    for i = 1, 8 do
        SendWorldMessage(msg)
    end
    print("-----------------------------------------------------")
end

local function DoCurfewBans(players, minutesUntilCurfewStart, minutesUntilCurfewEnd)

    -- We are past the end of curfew, allow people to play.
    if ((minutesUntilCurfewEnd <= 0) and (minutesUntilCurfewStart > 0)) then
        return
    end

    -- We are before curfew, allow people to play.
    if (minutesUntilCurfewEnd > minutesUntilCurfewStart) then
        return
    end

    for k, ply in pairs(players) do

        local banTime = minutesUntilCurfewEnd;

        if (banTime < 0) then
            banTime = (24 * 60) + banTime;
        end
        print("Banning " .. ply:GetAccountName() .. " because they were playing past curfew. See them back in " ..
                  banTime .. " minutes (until end of curfew).")
        Ban(0, ply:GetAccountName(), banTime * 60, "You are past curfew! See you in the morning!",
            "DAVDO - Lord of the Lua Domain & Curfew System")
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

    local curTime = os.date("*t", os.time() + (CurfewConfig.TIMEZONE * 60 * 60))

    local minutesUntilCurfewStart = ((CurfewConfig.startCurfew.hour * 60) + CurfewConfig.startCurfew.minute) - ((curTime.hour * 60) + curTime.min)
    local minutesUntilCurfewEnd = ((CurfewConfig.endCurfew.hour * 60) + CurfewConfig.endCurfew.minute) - ((curTime.hour * 60) + curTime.min)

    DoCurfewWarnings(curTime, minutesUntilCurfewStart, minutesUntilCurfewEnd)
    DoCurfewBans(players, minutesUntilCurfewStart, minutesUntilCurfewEnd)
end

CreateLuaEvent(PerformCurfewCheck, CurfewConfig.checkInterval * 1000, 0)
