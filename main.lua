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
local Config = require("utility/config")
local DialogViewer = require("dialogviewer")
-- local Dialog = require("dialogs")
-- local QuestionMenu = require("questionmenu")
local Questions = require("questions")
local Pronounce = require("pronounce")
local Prompts = require("prompts")

local AILearning = WidgetContainer:extend{
    name = "hello",
    is_doc_only = true,
}

local function showAbout()
    about_text = "" ..
    "Version 0.1\n" ..
    "Thank you for using this plugin. Enjoy!\n" ..
    "\n" ..
    "  [Configuration]\n" ..
    "    Menu:\n" ..
    "      Changes made in the menu will not be saved until you click 'Configs Save'.\n" ..
    "      Please test your settings before saving.\n" ..
    "\n" ..
    "    File:\n" ..
    "      The configuration file can be found at:\n" ..
    "      /mnt/us/koreader/data/ailearning.json\n" ..
    "      If the file is not found, you can create it using the 'Configs Save' menu option.\n" ..
    "      Before using AI features, please set up your server_url, api_key, and model.\n" ..
    "\n" ..
    "  Note: \n" ..
    "    If you want to use Ollama, ensure your firewall allows port 11434.\n" ..
    "    If you fail to connect, you can try the following command to allow connections from other devices:\n" ..
    "    OLLAMA_HOST=0.0.0.0:11434 ollama serve \n" ..
    "\n" ..
    "\n" ..
    "For the latest updates, visit: \n" ..
    "https://github.com/breeze101792/ailearning.koplugin \n" ..
    ""

    local dialogviewer = DialogViewer:new{
        title = _("About"),
        text = _(about_text),
    }
    UIManager:show(dialogviewer)
end

local function get_selection_info(ui)
    local context_window = Config.config.context_window

    local title, author =
    ui.document:getProps().title or _("Unknown Title"),
    ui.document:getProps().authors or _("Unknown Author")
    
    selected_text = ui.highlight.selected_text.text

    local prev_context, next_context
    if ui.highlight then
        prev_context, next_context = ui.highlight:getSelectedWordContext(context_window)
    end
    local full_context = ""

    full_context = "Book: " .. title .. ", Author: " .. author .. ". \nContext: "

    if prev_context then
        full_context = full_context .. prev_context .. " "
    end
    full_context = full_context .. selected_text
    if next_context then
        full_context = full_context .. " " .. next_context
    end
    return selected_text, full_context
end

local function showAIMenu_GeneralAsk(ui)
    local title, author =
    ui.document:getProps().title or _("Unknown Title"),
    ui.document:getProps().authors or _("Unknown Author")

    context = "Book: " .. title .. ", Author: " .. author
    selected_text = ""

    Questions.menu(selected_text, context)
end

local function showAILearningMenu(ui)
    selected_text, context = get_selection_info(ui, selected_text)

    Questions.menu(selected_text, context)
end

local function showAILearningQuestion(ui, question_callback)
    selected_text, context = get_selection_info(ui)

    question_callback(selected_text, context)
end

function AILearning:init()

    -- module init
    Config.init()
    Questions.init()

    -- register functions
    self.ui.menu:registerToMainMenu(self)

    self.ui.highlight:addToHighlightDialog("ailearning_menu", function(highlight_dialog)
        return {
            text = _("AI Menu"),
            enabled = Device:hasClipboard(),
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningMenu(self.ui)
                end)
                highlight_dialog:onClose()
            end,
        }
    end)
    self.ui.highlight:addToHighlightDialog("ailearning_explain", function(highlight_dialog)
        return {
            text = _("AI Translate"),
            enabled = Device:hasClipboard(),
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningQuestion(self.ui, Questions.translateText)
                end)
            end,
        }
    end)
end

local function getSubMenuConfig_configServers()
    server_config_menu = {
        {
            text = _("# Config Servers"),
            keep_menu_open = true,
            separator = true,
        },
        {
            text = _("Main Server URL"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Please input main server URL"),
                    input = _(Config.config.main.server_url),
                    input_type = "text",
                    description = _("Enter your server URL, you could just enter\n ex. ip/ip:port/full URL.\n"),
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
                                        Config.config.main.server_url = "https://" .. server_address .. "/v1/chat/completions"
                                    else
                                        -- Config.config.main.server_url = input_text .. "/v1/chat/completions"
                                        Config.config.main.server_url = input_text
                                    end
                                    -- Config.save()
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
            text = _("Main Server Model"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Please input main server model"),
                    input = _(Config.config.main.model),
                    input_type = "text",
                    description = _("Enter main server model."),
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
                                    Config.config.main.model = ollama_model
                                    -- Config.save()
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
            text = _("Ollama URL"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Please input ollama server URL"),
                    input = _(Config.config.ollama.server_url),
                    input_type = "text",
                    description = _("Enter your server URL, you could just enter\n ex. ip/ip:port/full URL.\n"),
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
                                    -- Config.save()
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
                                    -- Config.save()
                                    UIManager:close(input_dialog)
                                end,
                            },
                        },
                    },
                }
                UIManager:show(input_dialog)
            end,
            separator = true,
        }
    }

    return server_config_menu
end
local function getSubMenuConfig_sortingServers()
    current_idx_cnt = 0
    server_toogle_menu = {
        {
            text = _("# Sorting Servers (Toggle server by orders)"),
            keep_menu_open = true,
        },
        --[[
        -- need to find a way to update menu.
        {
            text = _("Reset server index"),
            keep_menu_open = true,
            callback = function(touchmenu_instance)
                current_idx_cnt = 0
                for server_name, server_config in pairs(Config.config.servers) do
                    Config.config.servers[server_name].index = nil
                end
            end,
        },
        --]]
    }

    -- Dynamically add user-defined servers from Config.config.servers
    if Config.config.servers then
        local sorted_servers = {}
        for server_name, server_config in pairs(Config.config.servers) do
            server_config.name = server_name -- Keep track of the original name for logging

            table.insert(sorted_servers, server_config)
        end

        -- Sort servers by index, handling cases where index might be nil
        table.sort(sorted_servers, function(a, b)
            -- return a.index and (not b.index or a.index < b.index)
            return (a.index or 999) < (b.index or 999)
        end)

        for idx, server_config in ipairs(sorted_servers) do

            if Config.config.servers[server_config.name].index ~= nil then
                Config.config.servers[server_config.name].index = current_idx_cnt
                current_idx_cnt = current_idx_cnt + 1
            end
            table.insert(server_toogle_menu, {
                text = server_config.name .. _(" server"),
                keep_menu_open = true,
                checked_func = function()
                    if Config.config.servers[server_config.name].index == nil then
                        Config.config.servers[server_config.name].index = nil
                        return false
                    else
                        return true
                    end
                end,
                callback = function(touchmenu_instance)
                    if Config.config.servers[server_config.name].index == nil then
                        Config.config.servers[server_config.name].index = current_idx_cnt
                        current_idx_cnt = current_idx_cnt + 1
                    else
                        Config.config.servers[server_config.name].index = nil
                    end

                    -- Config.save()
                end,
            })
        end
    end

    return server_toogle_menu
end
local function getSubMenuConfig_toggleServers()
    server_toogle_menu = {
        {
            text = _("# Toogle Servers"),
            keep_menu_open = true,
        },
        {
            text = _("Enable main server"),
            keep_menu_open = true,
            checked_func = function()
                return Config.config.main.enable
            end,
            callback = function(touchmenu_instance)
                if Config.config.main.enable then
                    Config.config.main.enable = false
                else
                    Config.config.main.enable = true
                end
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

    -- Dynamically add user-defined servers from Config.config.servers
    if Config.config.servers then
        for server_name, server_config in pairs(Config.config.servers) do
            table.insert(server_toogle_menu, {
                text = _("Enable ") .. server_name .. _(" server"),
                keep_menu_open = true,
                checked_func = function()
                    if server_config.enable == nil then
                        server_config.enable = false
                        -- Config.save()
                    end
                    return server_config.enable
                end,
                callback = function(touchmenu_instance)
                    server_config.enable = not server_config.enable
                    -- Config.save()
                end,
            })
        end
    end

    return server_toogle_menu
end
local function getSubMenuConfig()
    sorting_server_menu = getSubMenuConfig_sortingServers()
    toggle_server_menu = getSubMenuConfig_toggleServers()
    toggle_config_menu = getSubMenuConfig_configServers()

    config_sub_menu_table = {
        {
            text = _("# Configs (Please test before saving)"),
            keep_menu_open = true,
        },
        {
            text = _("Configs Reload"),
            keep_menu_open = true,
            callback = function()
                Config.load()
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
                    title = _("Enter your Language."),
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
                                    -- Config.save()
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
            text = _("Context Window"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Enter your context window."),
                    input = Config.config.context_window,
                    input_type = "number",
                    description = _("Enter the desired context window size for the AI. "),
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
                                    local context_window = input_dialog:getInputText()
                                    Config.config.context_window = tonumber(context_window)
                                    -- Config.save()
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
            text = _("# Server Configs"),
            keep_menu_open = true,
        },
        {
            text = _("Toggle Servers"),
            sub_item_table = toggle_server_menu
        },
        {
            text = _("Sorting Servers"),
            sub_item_table = sorting_server_menu
        },
        {
            text = _("Config Servers"),
            sub_item_table = toggle_config_menu
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
        },
        {
            text = _("Debug Level"),
            keep_menu_open = true,
            callback = function()
                input_dialog = InputDialog:new {
                    title = _("Set debug level."),
                    input = _(Config.config.log_level),
                    input_type = "number",
                    description = _("0: NONE, 1: CRITICAL, 2: ERROR, 3: WARNING, 4: INFO, 5: DEBUG, 6: TRACE, 7: MAX"),
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
                                    local log_level = input_dialog:getInputText()
                                    Config.config.log_level = tonumber(log_level)
                                    -- Config.save()
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
            text = _("Show AI Menu"),
            keep_menu_open = true,
            callback = function()
                showAIMenu_GeneralAsk(self.ui)
            end,
            separator = true,
        },
        {
            text = _("# Tasting zone(Don't try it at home.)"),
            keep_menu_open = true,
            callback = function()
                showAIMenu_GeneralAsk(self.ui)
            end,
        },
        {
            text = _("Pronounce"),
            font_bold = false,
            callback = function()
                Pronounce.pronounceText('Test', "")
            end
        },
    }

    return debug_sub_menu_table
end
function AILearning:addToMainMenu(menu_items)
    config_sub_menu_table = getSubMenuConfig()
    debug_sub_menu_table = getSubMenuDebug()

    menu_items.ai_learning_menu = {
        -- its name is "calibre", but all our top menu items are uppercase.
        text = _("AI Learning"),
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
                text = _("# Toggle servers temporally"),
                keep_menu_open = true,
            },
            {
                text = _("Enable main server"),
                keep_menu_open = true,
                checked_func = function()
                    return Config.config.main.enable
                end,
                callback = function(touchmenu_instance)
                    if Config.config.main.enable then
                        Config.config.main.enable = false
                    else
                        Config.config.main.enable = true
                    end
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
                    showAILearningMenu(self.ui)
                end)
                dict_popup:onClose()
            end
        },
        {
            text = _("Insight"),
            font_bold = false,
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningQuestion(self.ui, Questions.insightText)
                end)
            end
        },
        {
            text = _("Dictionary"),
            font_bold = false,
            callback = function()
                NetworkMgr:runWhenOnline(function()
                    showAILearningQuestion(self.ui, Questions.dictionaryText)
                end)
            end
        }
    }
    table.insert(buttons, 1, gpt_buttons)
end

return AILearning
