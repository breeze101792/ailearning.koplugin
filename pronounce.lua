local os = require("os")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")

local Pronounce = {}

--[[
function Pronounce.init()
    -- TODO, remove this after we get lang directly from config.
end
--]]

function Pronounce.showInfoDialog(text)
    text = text or 'Generating...'
    local info_diag = InfoMessage:new{
        text = text,
        timeout = 0.1,
    }
    UIManager:show(info_diag)
    return info_diag
end

function Pronounce.execute(command)
    -- Simple execution
    os.execute("echo test")

    -- Checking if it worked (Lua 5.2+)
    -- The first result is true/false, the third is the exit code (0 usually means success)
    local success, type, code = os.execute("ls -la")

    if success then
        print("Command successful!")
    else
        print("Command failed with code: " .. code)
    end
end

function Pronounce.pronounceText(selected_text, context)
    Pronounce.showInfoDialog()
    UIManager:scheduleIn(0.1, function()
        local command = "echo test"
        Pronounce.execute(command)

    end)
end
return Pronounce
