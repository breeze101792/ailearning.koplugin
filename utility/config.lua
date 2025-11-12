
-- Save this as write_config.lua
local json = require("dkjson")  -- or use cjson if available
-- copy config under koreader/data/
local default_config_path = './data/ailearning.json'

local Config = {}
-- Note. you could use qwen3 for offline model.
Config.config = {
    main = {
        enable = true,
        api_key = "your_api_key_here",
        model = "gpt-5",
        server_url = "https://api.example.com/v1"
    },
    ollama = {
        enable = false,
        api_key = "ollama",
        model = "",
        server_url = ""
    },
    servers = {
        -- Example of a user-added server
        -- You can add more servers here, e.g., server1, server2, etc.
        -- Each server should have 'enable', 'api_key', 'model', and 'server_url' fields.
        --[[
        example = {
            enable = false, -- Set to true to enable this backup server
            api_key = "",
            model = "",
            server_url = ""
        },
        --]]
    },
    language = "English",
    log_level = 3, -- (0: NONE, 1: CRITICAL, 2: ERROR, 3: WARNING, 4: INFO, 6: DEBUG, 7: TRACE, 8: MAX)
}

-- Helper function to deeply merge two tables
local function merge_tables(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dest[k]) == "table" then
            -- Recursively merge nested tables
            merge_tables(dest[k], v)
        else
            -- Overwrite or set new value
            dest[k] = v
        end
        -- Add a debug message here, controlled by a 'debug_mode' flag in the global Config.config table.
        -- This assumes 'Config.config.debug_mode' is defined elsewhere in the Config table.
        if false then
            local debug_message = string.format("DEBUG (merge_tables): Merged key '%s'(%s). New value type: %s", tostring(k),type(k), type(dest[k]))
            if type(dest[k]) == "string" then
                debug_message = debug_message .. string.format(", Value: '%s'", dest[k])
            end
            print(debug_message)
        end
    end
end

function Config.init()
    Config.load()
    if not io.open(default_config_path, "r") then
        Config.save()
    end
end
function Config.save()
    local file = io.open(default_config_path, "w")
    if file then
        local content = json.encode(Config.config, { indent = true })  -- pretty-print
        file:write(content)
        file:close()
        -- print("✅ config.json written successfully")
    else
        print("[ailearning] Failed to open file for writing")
    end
end

-- Helper function to format table to string for human reading
local function format_table_for_reading(tbl, indent)
    indent = indent or 0
    local result = {}
    local indent_str = string.rep("  ", indent)

    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys) -- Sort keys for consistent output

    for _, k in ipairs(keys) do
        local v = tbl[k]
        if type(v) == "table" then
            table.insert(result, string.format("%s%s:", indent_str, tostring(k)))
            table.insert(result, format_table_for_reading(v, indent + 1))
        else
            local value_str = tostring(v)
            if type(v) == "string" then
                value_str = string.format("'%s'", v)
            end
            table.insert(result, string.format("%s%s: %s", indent_str, tostring(k), value_str))
        end
    end
    return table.concat(result, "\n")
end

function Config.dump()
    return format_table_for_reading(Config.config)
end
function Config.load()
    local file = io.open(default_config_path, "r")
    if file then
        local content = file:read("*a")
        file:close()

        local data = json.decode(content)
        -- Deeply merge loaded data into the Config.config table
        merge_tables(Config.config, data)
    --[[
        print("✅ config.json loaded successfully")
    else
        print("⚠️ config.json not found, using default configuration.")
    --]]
    end
    -- Config.dump()

end

return Config
