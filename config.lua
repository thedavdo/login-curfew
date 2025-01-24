-- Config for users to change to their liking.
local CurfewConfig = {

    -- Minutes before curfew to send warnings
    warningTimes = {60, 30, 15, 10, 5, 1},

    -- Timezone offset from whatever the host machine is set to.
    TIMEZONE = 0,

    -- Interval in seconds to check for curfew checking
    checkInterval = 5,

    defaultCurfew = {
        -- Curfew start time
        start = {
            hour = 23,
            minute = 0
        },
        -- Curfew end time
        finish = {
            hour = 5,
            minute = 30
        }
    },

    -- Schedule for specific days, if not set, the default curfew times will be used.
    -- Sunday = 0, Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6
    scheduledCurfew = {

        -- Tuesday
        -- [2] = {
        --     start = {
        --         hour = 23,
        --         minute = 40
        --     },
        --     finish = {
        --         hour = 5,
        --         minute = 30
        --     }
        -- },
    }
}

return CurfewConfig
