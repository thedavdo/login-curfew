-- Config for users to change to their liking.
local CurfewConfig = {

    -- Schedule for specific days, if not set, the default curfew times will be used.
    -- Sunday = 0, Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6
    scheduledCurfew = {

        -- Friday
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

        -- Saturday
        [6] = {
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

-- Look up table to track warnings
local curfewWarnings = {};

-- String make look up take work better with numbers.
local WARN_LABEL = "WARN-"

local curfewDayCode = nil
local selectedCurfewConfig = CurfewConfig.defaultCurfew

local curfewTimeRanges = nil

local function getCurrentTime()

    return os.time() + (CurfewConfig.TIMEZONE * 60 * 60) -- + (timeAdjust * 60 * 15);
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

local function getCurfewHours()

    local currentTime = getCurrentTime();

    local adjustedDateTime = os.date("*t", currentTime)

    local startMinutes = ((selectedCurfewConfig.start.hour * 60) + selectedCurfewConfig.start.minute) - ((adjustedDateTime.hour * 60) + adjustedDateTime.min)
    local finishMinutes = ((selectedCurfewConfig.finish.hour * 60) + selectedCurfewConfig.finish.minute) - ((adjustedDateTime.hour * 60) + adjustedDateTime.min)

    if (startMinutes <= 0) then
        return
    end

    if (finishMinutes < startMinutes) then
        finishMinutes = (24 * 60) + finishMinutes
    end

    return {
        start = currentTime + (startMinutes * 60),
        finish = currentTime + (finishMinutes * 60)
    }
end

local function getMinutesUntilCurfewHours()

    if (not curfewTimeRanges) then
        return
    end

    local time = getCurrentTime();

    return {
        start = ((curfewTimeRanges.start - time) / 60),
        finish = ((curfewTimeRanges.finish - time) / 60)
    }
end

local function DoCurfewWarnings()

    local timeSeconds = getCurrentTime()

    if(curfewTimeRanges == nil) then
        return
    end

    -- Curfew is behind us.
    if ((curfewTimeRanges.start - timeSeconds) < 0) then
        return
    end

    local minutes = getMinutesUntilCurfewHours()

    local warnSelection = -1;

    -- Find closest warning message interval
    for _, warningTime in ipairs(CurfewConfig.warningTimes) do

        if (minutes.start > warningTime) then
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
    print("Minutes until curfew start: " .. minutes.start)
    print("Minutes until curfew end: " .. minutes.finish)
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

    if(curfewTimeRanges == nil) then
        return
    end

    local timeSeconds = getCurrentTime()

   -- We are past the end of curfew, allow people to play.
    if ((curfewTimeRanges.finish - timeSeconds) < 0) then
        return
    end

    -- We are before curfew, allow people to play.
    if ((curfewTimeRanges.start - timeSeconds) > 0) then
        return
    end

    local minutesUntilCurfewEnd = getMinutesUntilCurfewHours().finish

    local banTime = math.floor(minutesUntilCurfewEnd + 0.5);

    for k, ply in pairs(players) do

        print("Banning " .. ply:GetAccountName() .. " because they were playing past curfew. See them back in " .. banTime .. " minutes (until end of curfew).")
        Ban(0, ply:GetAccountName(), banTime * 60, "You are past curfew! See you in the morning!", "DAVDO - Lord of the Lua Domain & Curfew System")
    end
end

local function DoCurfewCheck()


    local timeSeconds = getCurrentTime()

    if(curfewTimeRanges and (timeSeconds < curfewTimeRanges.finish)) then 
        return
    end

    local dayCode = tonumber(os.date("%w", timeSeconds))

    if (CurfewConfig.scheduledCurfew[dayCode]) then
        curfewDayCode = dayCode
        selectedCurfewConfig = CurfewConfig.scheduledCurfew[dayCode]
    else
        curfewDayCode = nil
        selectedCurfewConfig = CurfewConfig.defaultCurfew
    end

    curfewWarnings = {}
    curfewTimeRanges = getCurfewHours()

    print("Curfew setup for " .. (curfewDayCode or "Default") .. " with start time: " .. selectedCurfewConfig.start.hour .. ":" .. selectedCurfewConfig.start.minute .. " and end time: " .. selectedCurfewConfig.finish.hour .. ":" .. selectedCurfewConfig.finish.minute)
end

local function PerformCurfewCheck(eventid, delay, repeats, worldobject)

    local players = getCurrentPlayers()

    if (not players) then
        return
    end

    DoCurfewCheck()
    DoCurfewWarnings()
    DoCurfewBans(players)
end

CreateLuaEvent(PerformCurfewCheck, CurfewConfig.checkInterval * 1000, 0)
