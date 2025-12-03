
local Prompts = {}

-- TODO, remove this after we get lang directly from config.
Prompts.target_language = 'English'

function Prompts.getSystemInstruction()
    local loc_general_instruction = "Rules:\n" ..
    "1. Do not use markdown syntax; use plain text only. Use spaces for indentation.\n" ..
    "2. Do not reveal spoilers.\n" ..
    "3. Reply without commentary.\n" ..
    "4. When showing Chinese, do NOT use Pinyin.\n" ..
    "5. All provided examples are in English. You must reply in the user's language.\n" ..
    ""
    return loc_general_instruction
end
function Prompts.getUserInstruction()
    local loc_general_instruction = "Note:\n" ..
    " Please use " .. Prompts.target_language .. " to reply the question." ..
    ""
    -- "1. I am learning a language. Please use my native language, " .. Prompts.target_language .. ", to explain and reply about this (selected) word." ..
    -- "3. Translations and explanations must be provided in " .. Prompts.target_language .. "." ..
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
        content = user_content ..
            "\n" .. Prompts.getUserInstruction()
    }
    local new_message_history = {
        {
            role = "system",
            content =  prompt ..
            "\n" .. Prompts.getSystemInstruction()
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
    local question_content = "Analyze the highlighted text, focusing on sentence structure."
    local system_prompt = "You are a helpful language analyst. Provide direct translations and explanations of difficult words, grammar, phrases, and sentence structures clearly and simply."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.translateText(text, context)
    local question_content = "Analyze the highlighted text."
    local system_prompt = "You are a helpful language analyst. Provide direct translations and explanations of difficult words, grammar, phrases, and sentence structures clearly and simply.\n" ..
                          "Example: For the highlighted text 'Si hubiera sabido que venías, te habría preparado una cena.', assume the user's language is English and reply in English.\n" ..
                          "Translation: If I had known you were coming, I would have prepared dinner for you.\n" ..
                          "Analysis:\n" ..
                          "- 'Si': Conjunction, meaning 'if'.\n" ..
                          "- 'hubiera sabido': Pluperfect subjunctive of 'saber' (to know), meaning 'I had known'.\n" ..
                          "- 'que venías': Subordinate clause, 'que' (that) + 'venías' (imperfect indicative of 'venir', you were coming).\n" ..
                          "- 'te': Indirect object pronoun, meaning 'for you'.\n" ..
                          "- 'habría preparado': Conditional perfect of 'preparar' (to prepare), meaning 'I would have prepared'.\n" ..
                          "- 'una cena': Noun phrase, meaning 'a dinner'.\n" ..
                          "Syntax:\n" ..
                          "- This sentence is a third conditional, expressing a hypothetical past situation and its unreal past result.\n" ..
                          "- The structure is 'Si + [pluperfect subjunctive], [conditional perfect]'.\n" ..
                          "Note:\n" ..
                          "- This structure is often used to express regret.\n" ..
                          "- The '-se' form of the subjunctive ('hubiese sabido') can also be used with the same meaning."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.insightText(text, context)
    local question_content = "Analyze this highlighted text. Explain the story and purpose behind the author's choices."
    local system_prompt = "You are a helpful reading researcher. Provide insights into the story behind the sentences, including:\n" ..
                          "1. The author's choice of phrases, words, or sentence structures.\n" ..
                          "2. Any underlying stories or cultural contexts."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, true)
end

function Prompts.exampleText(text, context)
    local question_content = "Based on this highlighted text, create examples that use a similar structure or style. " ..
    "If the selection is a single word, show how it is used in different contexts. " ..
    "Please reply question with " .. Prompts.target_language .. "."

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
    local question_content = "Provide a dictionary entry for '" .. text .. "', explained and highlight its meaning in the current context."
    local system_prompt = "You are a helpful dictionary checker assistant. Provide a comprehensive dictionary entry for this word, without additional commentary. Include base form, IPA, definitions, usages, and examples to help learners master this word. Also include other meanings, phrases, origin, and related parts if applicable.\n" ..
                          "Example: For the selected word 'corrieron', assume the user's language is English and reply in English.\n" ..
                          "(Optional) Form of: 'corrieron' is the third-person plural preterite indicative of 'correr'.\n" ..
                          "Word: 'correr' (verb)\n" ..
                          "IPA: /koˈreɾ/\n" ..
                          "Definitions: (list all meanings)\n" ..
                          "1. (Verb) To run, to move at a speed faster than walking.\n" ..
                          "   Examples:\n" ..
                          "   1. 'Él corre en el parque todas las mañanas.' (He runs in the park every morning.)\n" ..
                          "   2. 'Los niños corrieron a casa.' (The children ran home.)\n" ..
                          "2. (Verb) To flow (for liquids).\n" ..
                          "   Examples:\n" ..
                          "   1. 'El agua corre por el río.' (The water flows down the river.)\n" ..
                          "   2. 'Las lágrimas corrían por sus mejillas.' (Tears were running down her cheeks.)\n" ..
                          "Phrases:\n" ..
                          "- 'correr el riesgo': to run the risk.\n" ..
                          "- 'a todo correr': at full speed.\n" ..
                          "Origin: From Latin 'currere'.\n" ..
                          "Related parts: corredor (noun, runner), carrera (noun, race/career), corriendo (gerund)\n" ..
                          "Note: The verb 'correr' is highly versatile and can also mean 'to flow' (for liquids) or 'to slide' depending on the context."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, false)
end

function Prompts.etymologyText(text, context)
    local question_content = "Explain the origin of '" .. text .. "."
    local system_prompt = "You are a helpful dictionary checker assistant. Provide the complete history and origin of this word, without additional commentary. Include its etymology, original language, and forms in other languages."
    return Prompts.generateQuestions(question_content, system_prompt, text, context, false)
end

function Prompts.morphologyText(text, context)
    local question_content = "List all morphological forms of the word '" .. text ..
        ". Include the base form, all verb conjugations, noun/adjective variations, and any irregular forms."
    local system_prompt = "You are a morphology assistant. Provide the complete set of morphological forms of the word. " ..
        "Always begin by clearly stating the base form (lemma). Then list all inflected forms such as verb tenses, " ..
        "participles, plural forms, comparison forms, and any irregular variants. "
        -- "Do not include meaning, etymology, example sentences, or commentary."

    return Prompts.generateQuestions(question_content, system_prompt, text, context, false)
end
function Prompts.synonymsText(text, context)
    local question_content = "Provide synonyms for the word '" .. text ..
        ". For each synonym, include a short definition, explain how it differs from the original word, " ..
        "and give one example sentence. If there are multiple main meanings, group the synonyms by meaning."
    local system_prompt = "You are a precise synonym and usage assistant. For the target word, list only relevant synonyms. " ..
        "For each synonym, include: (1) a short and simple definition, (2) a clear explanation of how it differs " ..
        "from the original word or from other similar synonyms, and (3) one example sentence showing typical usage(And provide the translation if needed.). " ..
        "If the word has multiple distinct meanings, separate them into meaning groups for clarity. "
        -- "Do not include etymology, history, unnecessary commentary, or unrelated linguistic information."

    return Prompts.generateQuestions(question_content, system_prompt, text, context, false)
end
return Prompts
