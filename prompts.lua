
local Prompts = {}

-- TODO, remove this after we get lang directly from config.
Prompts.target_language = 'English'

function Prompts.getInstruction()
    local loc_general_instruction = "Note:\n" ..
    "1. Do not use markdown syntax; use plain text only. Use spaces for indentation.\n" ..
    "2. Do not reveal spoilers.\n" ..
    "3. Translations and explanations must be provided in " .. Prompts.target_language .. "." ..
    ""
    return loc_general_instruction
end

function Prompts.generateQuestions(question, prompt, text, context, include_highlighted_text)
    -- Default include_highlighted_text to true if not provided
    include_highlighted_text = (include_highlighted_text == nil) or include_highlighted_text

    -- Ensure context is not nil
    if context == nil then
        context = 'Empty'
    end

    local user_content = question
    if include_highlighted_text then
        user_content = user_content .. "\nHighlighted text: '" .. text .. "'"
    end
    user_content = user_content .. "\n" .. context

    local new_message = {
        role = "user",
        content = user_content
    }
    local new_message_history = {
        {
            role = "system",
            content =  prompt ..
            "\n" .. Prompts.getInstruction()
        },
        new_message
    }
    return new_message_history
end
-- Module functions
function Prompts.askText(text, context, question)
    local question_content = question
    local system_prompt = "You are a helpful reading researcher. Your task is to answer user questions, leveraging the highlighted text and its context. If no highlighted text or context is provided, simply answer the user's question."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.syntaxText(text, context)
    local question_content = "Analyze the highlighted text, focusing on sentence structure, and explain it in " .. Prompts.target_language .. "."
    local system_prompt = "You are a helpful language analyst. Provide direct translations and explanations of difficult words, grammar, phrases, and sentence structures clearly and simply."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.translateText(text, context)
    local question_content = "Analyze the highlighted text and explain it in " .. Prompts.target_language .. "."
    local system_prompt = "You are a helpful language analyst. Provide direct translations and explanations of difficult words, grammar, phrases, and sentence structures clearly and simply."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.insightText(text, context)
    local question_content = "Analyze this highlighted text. Use ".. Prompts.target_language .. " to explain the story and purpose behind the author's choices."
    local system_prompt = "You are a helpful reading researcher. Provide insights into the story behind the sentences, including:\n" ..
                          "1. The author's choice of phrases, words, or sentence structures.\n" ..
                          "2. Any underlying stories or cultural contexts."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.exampleText(text, context)
    local question_content = "Based on this highlighted text, create examples that use a similar structure or style. " ..
    "If the selection is a single word, show how it is used in different contexts. " ..
    "Use " .. Prompts.target_language .. " for your response."

    local system_prompt = "You are a helpful language coach and sentence pattern generator. " ..
    "Your task is to help learners understand and practice natural sentence structures. " ..
    "Please:\n" ..
    "1. Identify the grammatical pattern or sentence structure of the highlighted text.\n" ..
    "2. Provide 2–3 new example sentences using a similar structure or tone.\n" ..
    "3. If the text is only one word, give 3–4 example sentences showing different usages or meanings.\n" ..
    "4. Optionally, explain any subtle differences or common learner mistakes."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.dictionaryText(text, context)
    local question_content = "Provide a dictionary entry for '" .. text .. "', explained in " .. Prompts.target_language .. ", and highlight its meaning in the current context."
    local system_prompt = "You are a helpful dictionary checker assistant. Provide a comprehensive dictionary entry for this word, without additional commentary. Include IPA, definitions, usages, and examples to help learners master this word. Also include other meanings, phrases, origin, and related parts if applicable."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, false)
end

function Prompts.originText(text, context)
    local question_content = "Explain the origin of '" .. text .. "' in " .. Prompts.target_language .. "."
    local system_prompt = "You are a helpful dictionary checker assistant. Provide the complete history and origin of this word, without additional commentary. Include its etymology, original language, and forms in other languages."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, false)
end

return Prompts
