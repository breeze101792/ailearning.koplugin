local Config = require("utility/config")

local Logger = {
    -- Default to INFO (0: NONE, 1: CRITICAL, 2: ERROR, 3: WARNING, 4: INFO, 6: DEBUG, 7: TRACE, 8: MAX)
    LogLevel = {
        NONE = 0,
        CRITICAL = 1,
        ERROR    = 2,
        WARNING  = 3,
        INFO     = 4,
        DEBUG    = 6,
        TRACE    = 7,
        MAX      = 8, -- Used as an upper bound to show all logging
    }
}

local function log(level, ...)
    if level > tonumber(Config.config.log_level) then
        return
    end

    local level_name = ""
    -- The 'level' parameter passed to this function will always be TRACE, DEBUG, INFO, WARNING, or ERROR
    -- as it's called by Logger.trace, Logger.debug, Logger.info, etc.
    if level == Logger.LogLevel.TRACE then
        level_name = "TRACE"
    elseif level == Logger.LogLevel.DEBUG then
        level_name = "DEBUG"
    elseif level == Logger.LogLevel.INFO then
        level_name = "INFO"
    elseif level == Logger.LogLevel.WARNING then
        level_name = "WARNING"
    elseif level == Logger.LogLevel.ERROR then
        level_name = "ERROR"
    elseif level == Logger.LogLevel.CRITICAL then
        level_name = "CRITICAL"
    end
    local args = {...}
    local formatted_message = table.concat(args, "\t")

    -- Get caller info: level 3 is the caller of log (e.g., Logger.debug), level 4 is the actual user caller
    local info = debug.getinfo(4, "Sl")
    local caller_info = ""
    if info and info.source and info.currentline then
        -- Remove the leading "@" from source if it's a file path
        local source = info.source:gsub("^@", "")
        caller_info = string.format(" (%s:%d)", source, info.currentline)
    end

    print(string.format("[%s]%s %s", level_name, caller_info, formatted_message))
end

function Logger.trace(...)
    log(Logger.LogLevel.TRACE, ...)
end

function Logger.debug(...)
    log(Logger.LogLevel.DEBUG, ...)
end

function Logger.info(...)
    log(Logger.LogLevel.INFO, ...)
end

function Logger.warning(...)
    log(Logger.LogLevel.WARNING, ...)
end

function Logger.error(...)
    log(Logger.LogLevel.ERROR, ...)
end

function Logger.critical(...)
    log(Logger.LogLevel.CRITICAL, ...)
end

return Logger

