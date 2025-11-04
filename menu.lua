-- File: dialogviewer.lua

local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local util = require("util")
local _ = require("gettext")

local Prompts = require("prompts")
local DialogViewer = require("dialogviewer")
local OpenAI = require("openai")
-- local queryChatGPT = require("gpt_query")

-- Define a new class called QuestionMenu inheriting from ButtonDialog
local QuestionMenu = ButtonDialog:extend{
    title = "AI Question Menu.",

    width_factor = 0.8, -- number between 0 and 1, factor to the smallest of screen width and height
}

-- Constructor (optional)
function QuestionMenu:init(text)
    self.text = text or "Hello, world!"

    ButtonDialog.init(self)  -- call parent constructor

end

-- Custom render or open function
--[[
function QuestionMenu:showDialog()
    -- You can use inherited `show()` to display it
    UIManager:show(self)
end
--]]

return QuestionMenu
