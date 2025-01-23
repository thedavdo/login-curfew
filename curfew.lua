-- Config for users to change to their liking.
local CurfewConfig = {

    -- Schedule for specific days, if not set, the default curfew times will be used.
    -- Sunday = 0, Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6
    scheduledCurfew = {

        -- Tuesday
        [2] = {
            start = {
                hour = 23,
                minute = 40
            },
            finish = {
                hour = 5,
                minute = 30
            }
        },

        -- Thursday
        [4] = {
            start = {
                hour = 23,
                minute = 30
            },
            finish = {
                hour = 5,
                minute = 30
            }
        }
    },

    defaultCurfew = {
        -- Curfew start time
        start = {
            hour = 19,
            minute = 5
        },
        -- Curfew end time
        finish = {
            hour = 4,
            minute = 30
        }
    },

    -- Minutes before curfew to send warnings
    warningTimes = {60, 30, 15, 10, 5, 1},

    -- Timezone offset from whatever the host machine is set to.
    TIMEZONE = 0,

    -- Interval in seconds to check for curfew checking
    checkInterval = 5
}

-----------------------------------------------------

-----------------------------------------------------
-- DO NOT EDIT BELOW THIS LINE ----------------------
-----------------------------------------------------

local debug = false

if (debug) then
    require("debugging")
end

-- Look up table to track warnings
local curfewWarnings = {};

-- String make look up take work better with numbers.
local WARN_LABEL = "WARN-"

local curfewDayCode = nil
local selectedCurfewConfig = CurfewConfig.defaultCurfew

local curfewTimes = nil

-- Only for debugging purposes, to simulate time passing.
local timeOffest = 0
local timeScale = 10

local function getCurrentTimeSeconds()

    return os.time() + (CurfewConfig.TIMEZONE * 60 * 60) + (timeOffest * 60 * timeScale);
end

local function getCurrentPlayers()

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

    return players
end

local function getCurfewTimes(inConfig, inTimeSeconds)

    local curfewConfig = inConfig or selectedCurfewConfig
    local currentTimeSeconds = inTimeSeconds or getCurrentTimeSeconds();

    local currentDateTime = os.date("*t", currentTimeSeconds)

    local dayStartSeconds = os.time({
        year = currentDateTime.year,
        month = currentDateTime.month,
        day = currentDateTime.day,
        hour = 0,
        sec = 0
    })

    local curfewStartSeconds = dayStartSeconds + (curfewConfig.start.hour * 60 * 60) + (curfewConfig.start.minute * 60)
    local curfewFinishSeconds = dayStartSeconds + (curfewConfig.finish.hour * 60 * 60) + (curfewConfig.finish.minute * 60)

    if (curfewConfig.start.hour > curfewConfig.finish.hour) then
        curfewFinishSeconds = curfewFinishSeconds + (24 * 60 * 60)
    end

    return {
        start = curfewStartSeconds,
        finish = curfewFinishSeconds
    }
end

local function DoCurfewWarnings()

    local timeSeconds = getCurrentTimeSeconds()

    if (curfewTimes == nil) then
        return
    end

    local secondsUntilCurfewStart = curfewTimes.start - timeSeconds;
    local secondsUntilCurfewFinish = curfewTimes.finish - timeSeconds;

    -- Curfew is behind us.
    if (secondsUntilCurfewStart < 0) then
        return
    end

    local warnSelection = -1;

    -- Find closest warning message interval
    for _, warningTime in ipairs(CurfewConfig.warningTimes) do

        if (secondsUntilCurfewStart > (warningTime * 60)) then
            break
        end

        if (warnSelection ~= -1 and warningTime >= warnSelection) then
            break
        end

        -- If we have not found a warning message yet, 
        -- or if this warning time is closer to the current time than the most recent one, set it as the most recent.
        warnSelection = warningTime

    end

    -- If we don't have a warning message to send, stop here.
    if (warnSelection == -1) then
        return
    end

    local lbl = WARN_LABEL .. warnSelection

    if curfewWarnings[lbl] then
        return
    end

    curfewWarnings[lbl] = true;

    local adjustedDateTime = os.date("*t", timeSeconds)

    print("-----------------------------------------------------")
    print("Curfew Selection: " .. (curfewDayCode or "Default"))
    print("Current time: " .. adjustedDateTime.hour .. ":" .. adjustedDateTime.min)
    print("Curfew start time: " .. selectedCurfewConfig.start.hour .. ":" .. selectedCurfewConfig.start.minute)
    print("Curfew end time: " .. selectedCurfewConfig.finish.hour .. ":" .. selectedCurfewConfig.finish.minute)
    print("Minutes until curfew start: " .. math.floor((secondsUntilCurfewStart / 60) + 0.5))
    print("Minutes until curfew end: " .. math.floor((secondsUntilCurfewFinish / 60) + 0.5))
    print("-----------------------------------------------------")

    local msg = "Curfew is in less than " .. warnSelection .. " minutes. Please finish up and go to bed."

    print(msg)

    -- Send 8 messages so people can see it fill up in chat.
    for i = 1, 8 do
        SendWorldMessage(msg)
    end
    print("-----------------------------------------------------")
end

local function DoCurfewBans(players)

    -- Curfew times aren't setup yet
    if (curfewTimes == nil) then
        return
    end

    local timeSeconds = getCurrentTimeSeconds()

    -- We are before curfew, allow people to play.
    if (curfewTimes.start > timeSeconds) then
        return
    end

    -- We are past the end of curfew, allow people to play.
    if (curfewTimes.finish < timeSeconds) then
        return
    end

    local minutesUntilCurfewEnd = (curfewTimes.finish - timeSeconds) / 60

    local banTime = math.floor(minutesUntilCurfewEnd + 0.5);

    print("Current time: " .. os.date("%H:%M", timeSeconds))

    for k, ply in pairs(players) do
        print("Banning " .. ply:GetAccountName() .. " because they were playing past curfew. See them back in " .. banTime .. " minutes (until end of curfew).")
        Ban(0, ply:GetAccountName(), banTime * 60, "You are past curfew! See you in the morning!", "DAVDO - Lord of the Lua Domain & Curfew System")
    end
end

local function DoCurfewCheck()

    local timeSeconds = getCurrentTimeSeconds()

    -- If we have a curfew time set and we are not yet past the end of curfew, don't reset the curfew times.
    if (curfewTimes and (timeSeconds < curfewTimes.finish)) then
        return
    end

    local dayCode = tonumber(os.date("%w", timeSeconds))

    local newDayCode = nil
    local newCurfew = nil

    --First time setup, no curfew times set yet. 
    if (not curfewTimes) then

        print("Curfew times not set. Setting up curfew for the first time.")

        local prevDayTimeSeconds = timeSeconds - (24 * 60 * 60)
        local prevDayCode = tonumber(os.date("%w", prevDayTimeSeconds))

        local scheduledConfig = CurfewConfig.scheduledCurfew[prevDayCode];
        local prevDayConfig = scheduledConfig or CurfewConfig.defaultCurfew

        print("Checking schedule for previous day: " .. (scheduledConfig and "Scheduled" or "Default"))    
        local prevDayTimes = getCurfewTimes(prevDayConfig, prevDayTimeSeconds)

        if (prevDayTimes.finish > timeSeconds) then

            if (scheduledConfig) then
                newDayCode = prevDayCode
            end

            newCurfew = prevDayConfig
            curfewTimes = prevDayTimes
            print("Curfew times from previous day are still active. Using those.")
        end
    end

    if (not newCurfew or (curfewTimes and timeSeconds > curfewTimes.finish)) then

        print("Selecting curfew for " .. (dayCode or "Default") .. " day.")

        if (CurfewConfig.scheduledCurfew[dayCode]) then
            -- Check for a specific curfew for this day in the schedule, else use default
            newDayCode = dayCode
            newCurfew = CurfewConfig.scheduledCurfew[dayCode]

        else
            -- If we don't have a specific curfew for this day, use the default.
            newDayCode = nil
            newCurfew = CurfewConfig.defaultCurfew
        end

        curfewTimes = getCurfewTimes()
    end

    curfewWarnings = {}
    curfewDayCode = newDayCode
    selectedCurfewConfig = newCurfew

    print("Curfew setup for " .. (curfewDayCode or "Default") .. " with start time: " .. selectedCurfewConfig.start.hour .. ":" .. selectedCurfewConfig.start.minute .. " and end time: " .. selectedCurfewConfig.finish.hour .. ":" .. selectedCurfewConfig.finish.minute)
end

local function PerformCurfewCheck(eventid, delay, repeats, worldobject, debugTimeOffset)

    timeOffest = debugTimeOffset or 0

    local players = getCurrentPlayers()

    if (not players) then
        return
    end

    DoCurfewCheck()
    DoCurfewWarnings()
    DoCurfewBans(players)
end

CreateLuaEvent(PerformCurfewCheck, CurfewConfig.checkInterval * 1000, 0)
