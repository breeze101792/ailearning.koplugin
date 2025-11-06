--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--


local Device = require("device")
local NetworkMgr = require("ui/network/manager")
local Dispatcher = require("dispatcher")  -- luacheck:ignore
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local CheckButton = require("ui/widget/checkbutton")
-- local TextViewer = require("ui.widget.textviewer")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

-- local modules
local Config = require("config")
local DialogViewer = require("dialogviewer")
-- local Dialog = require("dialogs")
-- local QuestionMenu = require("questionmenu")
local Questions = require("questions")
local Prompts = require("prompts")

local AILearning = WidgetContainer:extend{
    name = "hello",
    is_doc_only = true,
}

local function get_full_context(ui, selected_text)
    local title, author =
    ui.document:getProps().title or _("Unknown Title"),
    ui.document:getProps().authors or _("Unknown Author")

    local prev_context, next_context
    if ui.highlight then
        prev_context, next_context = ui.highlight:getSelectedWordContext(32)
    end
    local full_context = ""

    full_context = "Book: " .. title .. ", Author: " .. author .. ". \nFull Context: "

    if prev_context then
        full_context = full_context .. prev_context .. " "
    end
    full_context = full_context .. selected_text
    if next_context then
        full_context = full_context .. " " .. next_context
    end
    return full_context
end
local function showAbout()
    about_text = "" ..
    "Version 0.1\n" ..
    "Thank you for using this plugin. Enjoy!\n" ..
    "\n" ..
    "[Config]\n" ..
    "The configuration file can be found at: \n" ..
    "/mnt/us/koreader/data/ailearning_config.json\n" ..
    "If the file is not found, you can create it via the 'Configs Save' menu option.\n" ..
    "Before using AI features, please set up your server_url, api_key, and model.\n" ..
    "\n" ..
    "Note: If you want to use Ollama, make sure the firewall allows port 11434.\n"..
    "If you fail to connect, you could try the following command to allow from others devices.\n"..
    "OLLAMA_HOST=0.0.0.0:11434 ollama serve \n" ..
    ""

    local dialogviewer = DialogViewer:new{
        title = _("About"),
        text = _(about_text),
    }
    UIManager:show(dialogviewer)
end

local function showAILearningMenu(ui, selected_text)
    context = get_full_context(ui, selected_text) or _("")

    Questions.menu(selected_text, context)
end

local function showAILearningQuestion(ui, selected_text, question_callback)
    full_context = get_full_context(ui, selected_text) or _("")

    question_callback(selected_text, full_context)
end

function AILearning:init()

    -- module init
    Config.init()
    Questions.init()

    -- register functions
    self.ui.menu:registerToMainMenu(self)

    self.ui.highlight:addToHighlightDialog("ailearning_menu", function(_reader_highlight_instance)
        return {
            text = _("AI Menu"),
            enabled = Device:hasClipboard(),
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningMenu(self.ui, _reader_highlight_instance.selected_text.text)
                end)
            end,
        }
    end)
    self.ui.highlight:addToHighlightDialog("ailearning_explain", function(_reader_highlight_instance)
        return {
            text = _("AITranslate"),
            enabled = Device:hasClipboard(),
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningQuestion(self.ui, _reader_highlight_instance.selected_text.text, Questions.translateText)
                end)
            end,
        }
    end)
end

local function getSubMenuConfig()
    config_sub_menu_table = {
        {
            text = _("# Config Actions"),
            keep_menu_open = true,
        },
        {
            text = _("Configs Load"),
            keep_menu_open = true,
            callback = function()
                Config.save()
                local info_diag = InfoMessage:new{
                    text = _("Config loaded."),
                    timeout = 1,
                }
                UIManager:show(info_diag)
            end,
        },
        {
            text = _("Configs Save"),
            keep_menu_open = true,
            callback = function()
                Config.save()
                local info_diag = InfoMessage:new{
                    text = _("Config saved."),
                    timeout = 1,
                }
                UIManager:show(info_diag)
            end,
            separator = true,
        },
        {
            text = _("# Config Parameters"),
            keep_menu_open = true,
        },
        {
            text = _("Language"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Enter your Language.."),
                    input = _(Config.config.language),
                    input_type = "text",
                    description = _("Enter Language you want AI to speak. "),
                    buttons = {
                        {
                            {
                                text = _("Cancel"),
                                callback = function()
                                    UIManager:close(input_dialog)
                                end,
                            },
                            {
                                text = _("Ok"),
                                is_enter_default = true,
                                callback = function()
                                    local input_lang = input_dialog:getInputText()
                                    Config.config.language = input_lang
                                    Prompts.target_language = input_lang
                                    Config.save()
                                    UIManager:close(input_dialog)
                                end,
                            },
                        },
                    },
                }
                UIManager:show(input_dialog)
            end,
            separator = true,
        },
        {
            text = _("# server configs"),
            keep_menu_open = true,
        },
        {
            text = _("Ollama url"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Please input ollama server url"),
                    input = _(Config.config.ollama.server_url),
                    input_type = "text",
                    description = _("Enter your server url, you could just enter\n ex. ip/ip:port/full url.\n"),
                    buttons = {
                        {
                            {
                                text = _("Cancel"),
                                callback = function()
                                    UIManager:close(input_dialog)
                                end,
                            },
                            {
                                text = _("Ok"),
                                is_enter_default = true,
                                callback = function()
                                    local input_text = input_dialog:getInputText()
                                    local server_address = input_text
                                    if not (string.find(input_text, "http://") or string.find(input_text, "https://")) then
                                        if not string.find(input_text, ":") then
                                            server_address = input_text .. ":11434"
                                        end
                                        Config.config.ollama.server_url = "http://" .. server_address .. "/v1/chat/completions"
                                    else
                                        -- Config.config.ollama.server_url = input_text .. "/v1/chat/completions"
                                        Config.config.ollama.server_url = input_text
                                    end
                                    Config.save()
                                    UIManager:close(input_dialog)
                                end,
                            },
                        },
                    },
                }
                UIManager:show(input_dialog)
            end,
        },
        {
            text = _("Ollama Model"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Please input ollama model"),
                    input = _(Config.config.ollama.model),
                    input_type = "text",
                    description = _("Enter ollama local model."),
                    buttons = {
                        {
                            {
                                text = _("Cancel"),
                                callback = function()
                                    UIManager:close(input_dialog)
                                end,
                            },
                            {
                                text = _("Ok"),
                                is_enter_default = true,
                                callback = function()
                                    local ollama_model = input_dialog:getInputText()
                                    Config.config.ollama.model = ollama_model
                                    Config.save()
                                    UIManager:close(input_dialog)
                                end,
                            },
                        },
                    },
                }
                UIManager:show(input_dialog)
            end,
        },
    }
    return config_sub_menu_table
end
local function getSubMenuDebug()
    debug_sub_menu_table = {
        {
            text = _("Dump Configs"),
            keep_menu_open = true,
            callback = function()
                local dialogviewer = DialogViewer:new{
                    title = _("Dump Configs."),
                    text = Config.dump()
                }
                UIManager:show(dialogviewer)
            end,
            separator = true,
        },
        {
            text = _("Test Dialog"),
            callback = function()
                local dialogviewer = DialogViewer:new{
                    title = _("AI Dialog."),
                    text = _("I'll need to be longer than this example to scroll."),
                }
                UIManager:show(dialogviewer)
            end,
        },
    }

    return debug_sub_menu_table
end
function AILearning:addToMainMenu(menu_items)
    config_sub_menu_table = getSubMenuConfig()
    debug_sub_menu_table = getSubMenuDebug()

    menu_items.ai_learning_menu = {
        -- its name is "calibre", but all our top menu items are uppercase.
        text = _("AILearning"),
        -- sorting_hint = "more_tools",
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Configs"),
                keep_menu_open = true,
                sub_item_table = config_sub_menu_table,
            },
            {
                text = _("Debug"),
                keep_menu_open = true,
                sub_item_table = debug_sub_menu_table,
            },
            {
                text = _("About"),
                keep_menu_open = true,
                callback = function()
                    showAbout()
                end,
                separator = true,
            },
            {
                text = _("# Toggle servers"),
                keep_menu_open = true,
            },
            {
                text = _("Enable main server"),
                keep_menu_open = true,
                checked_func = function()
                    return Config.config.server.enable
                end,
                callback = function(touchmenu_instance)
                    if Config.config.server.enable then
                        Config.config.server.enable = false
                    else
                        Config.config.server.enable = true
                    end
                    -- ignore for now, so we need to do it every boot up.
                    -- Config.save()
                end,
            },
            {
                text = _("Enable ollama"),
                keep_menu_open = true,
                checked_func = function()
                    return Config.config.ollama.enable
                end,
                callback = function(touchmenu_instance)
                    if Config.config.ollama.enable then
                        Config.config.ollama.enable = false
                    else
                        Config.config.ollama.enable = true
                    end
                    -- Config.save()
                end,
            },
        }
    }
    -- table.insert(menu_items, 1, ai_learning_menu)
end

function AILearning:onDictButtonsReady(dict_popup, buttons)
    if dict_popup.is_wiki_fullpage then
        return
    end

    gpt_buttons = {
        {
            text = _("AI Menu"),
            font_bold = false,
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningMenu(self.ui, dict_popup.lookupword)
                end)
                dict_popup:onClose()
            end
        },
        {
            text = _("Word Origin"),
            font_bold = false,
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningQuestion(self.ui, dict_popup.lookupword, Questions.originText)
                end)
                dict_popup:onClose()
            end
        },
        {
            text = _("Dictionary"),
            font_bold = false,
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningQuestion(self.ui, dict_popup.lookupword, Questions.dictionaryText)
                end)
                dict_popup:onClose()
            end
        }
    }
    table.insert(buttons, 1, gpt_buttons)
end

return AILearning
