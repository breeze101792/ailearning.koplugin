
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local util = require("util")
local _ = require("gettext")

local Prompts = require("prompts")
local DialogViewer = require("dialogviewer")
local Menu = require("menu")
local OpenAI = require("openai")
local Config = require("utility/config")

local Questions = {}

function Questions.init()
    -- TODO, remove this after we get lang directly from config.
    Prompts.target_language = Config.config.language
end

-- Local functions
function Questions.MsgToText(message_history)
    local question_text = ""
    for i = 1, #message_history do
        if message_history[i] then
            if message_history[i].role == "user" then
                question_text = question_text .. _("User: ") .. message_history[i].content .. "\n\n"
            elseif message_history[i].role == "system" then
                question_text = question_text .. _("System: ") .. message_history[i].content .. "\n\n"
            elseif message_history[i].role == "assistant" then
                question_text = question_text .. _("Assistant: ") .. message_history[i].content .. "\n\n"
            else
                question_text = question_text .. message_history[i].role .. _(": ") .. message_history[i].content .. "\n\n"
            end
        end
    end
    return question_text
end

function Questions.generateResponse(question, message, selected_text, title)
    title = title or "AI Response"
    -- question_text = MsgToText(message)

    response = OpenAI.query(message)

    local dialogviewer = DialogViewer:new{
        title = title,
        text = "Selected Text: " .. selected_text .. "\n" ..
        "\nUser: " .. question .. "\n" ..
        "\nAssistant: \n" .. response,
    }
    UIManager:show(dialogviewer)
end

function Questions.showInfoDialog(text)
    text = text or _('Thinking...')
    local info_diag = InfoMessage:new{
        text = text,
        timeout = 0.1,
    }
    UIManager:show(info_diag)
    return info_diag
end

-- Questions
function Questions.originText(selected_text, context)
    text = "Word origin"
    Questions.showInfoDialog()
    UIManager:scheduleIn(0.1, function()
        question_message = Prompts.originText(selected_text, context )
        Questions.generateResponse("Provide the word origin to user.", question_message, selected_text, text)
    end)
end
function Questions.dictionaryText(selected_text, context)
    text = "Dictionary"
    Questions.showInfoDialog()
    UIManager:scheduleIn(0.1, function()
        question_message = Prompts.dictionaryText(selected_text, context )
        Questions.generateResponse("Provide the dictionary to user.", question_message, selected_text, text)
    end)
end
function Questions.translateText(selected_text, context)
    text = "Translation"
    Questions.showInfoDialog()
    UIManager:scheduleIn(0.1, function()
        question_message = Prompts.translateText(selected_text, context )
        Questions.generateResponse("Provide the translation to user.", question_message, selected_text, text)
    end)
end
function Questions.menu(selected_text, context)
    menu = nil
    menu_buttons = {
        {
            {
                text = "Insight",
                callback = function()
                    Questions.showInfoDialog()
                    UIManager:scheduleIn(0.1, function()
                        question_message = Prompts.insightText(selected_text, context )
                        Questions.generateResponse("Provide the insight to user.", question_message, selected_text, text)
                    end)

                end,
                -- hold_callback = function() end
            },
            {
                text = "Syntax",
                callback = function()
                    Questions.showInfoDialog()
                    UIManager:scheduleIn(0.1, function()
                        question_message = Prompts.syntaxText(selected_text, context )
                        Questions.generateResponse("Provide the syntax to user.", question_message, selected_text, text)
                    end)
                end
            },
            {
                text = "Translate",
                callback = function()
                    Questions.showInfoDialog()
                    UIManager:scheduleIn(0.1, function()
                        question_message = Prompts.translateText(selected_text, context )
                        Questions.generateResponse("Provide the translation to user.", question_message, selected_text, text)
                    end)
                end
            },
            {
                text = "Example",
                callback = function()
                    Questions.showInfoDialog()
                    UIManager:scheduleIn(0.1, function()
                        question_message = Prompts.exampleText(selected_text, context )
                        Questions.generateResponse("Provide the example usage to user.", question_message, selected_text, text)
                    end)
                end
            },
        },
        {
            {
                text = "Dictionary",
                callback = function()
                    Questions.showInfoDialog()
                    UIManager:scheduleIn(0.1, function()
                        question_message = Prompts.dictionaryText(selected_text, context )
                        Questions.generateResponse("Provide the dictionary content of this word to user.", question_message, selected_text, text)
                    end)
                end,
                hold_callback = function() end
            },
            {
                text = "Origin",
                callback = function()
                    Questions.showInfoDialog()
                    UIManager:scheduleIn(0.1, function()
                        question_message = Prompts.originText(selected_text, context )
                        Questions.generateResponse("Provide the origin of this word to user.", question_message, selected_text, text)
                    end)
                end,
                hold_callback = function() end
            },
        },
        {
            {
                text = "Debug MSG",
                callback = function()
                    question_message = Prompts.dictionaryText(selected_text, context )
                    question_text = Questions.MsgToText(question_message)

                    local dialogviewer = DialogViewer:new{
                        title = _("AI Dialog."),
                        text = "Context: " .. context .. "\nSelected Text: " .. selected_text .. "\nQuestion: " .. question_text,
                    }
                    UIManager:show(dialogviewer)
                end,
                hold_callback = function() end
            },
            {
                text = "Ask",
                callback = function()
                    input_dialog = InputDialog:new {
                        title = _("Ask Question."),
                        input = "",
                        input_type = "text",
                        description = _("Enter your question about the highlighted words."),
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
                                        local user_question = input_dialog:getInputText()
                                        Questions.showInfoDialog()
                                        UIManager:scheduleIn(0.1, function()
                                            question_message = Prompts.askText(selected_text, context, user_question )
                                            Questions.generateResponse(user_question, question_message, selected_text, _("User Question"))
                                        end)
                                        UIManager:close(input_dialog)
                                    end,
                                },
                            },
                        },
                    }
                    UIManager:show(input_dialog)
                end,
                hold_callback = function() end
            }
        },
    }
    menu = Menu:new{
        buttons = menu_buttons,
    }
    UIManager:show(menu)
end
return Questions
