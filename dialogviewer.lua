
-- dialogviewer.lua
local TextViewer = require("ui/widget/textviewer")
local UIManager = require("ui/uimanager")
local Button = require("ui/widget/button")
local VerticalGroup = require("ui/widget/verticalgroup")

-- Define subclass
local DialogViewer = TextViewer:extend{
    name = "dialogviewer",
    justified = true,
}

function DialogViewer:init()
    -- Call parent constructor (TextViewer)
    TextViewer.init(self)
    -- TODO, we may need to add more buttons.

end

return DialogViewer
