
-- Library
local https = require("ssl.https")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")
local socket = require("socket") -- Add socket for sleep function

-- Local Library
local Config = require("config")

local OpenAI = {
    retry_limit = 3,
    retry_delay = 1,
}
function OpenAI.header(api_key)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. api_key,
    }
    return headers
end
function OpenAI.body(model, messages)
    local body_table = {
        model = model,
        messages = messages,
    }

    local body = json.encode(body_table)
    return body
end

function OpenAI.request(message_history, server_info)
    local server_url = server_info.server_url
    local model = server_info.model
    local api_key = server_info.api_key

    local reqHeaders = OpenAI.header(api_key)
    local reqBody = OpenAI.body(model, message_history)

    local rspBody = {}
    local res, code, rspHeaders

    -- Determine whether to use http or https
    local request_library = server_url:match("^https://") and https or http

    local attempts = 0
    while attempts <= OpenAI.retry_limit do
        attempts = attempts + 1
        rspBody = {} -- Clear response body for each attempt

        -- Make the HTTP/HTTPS request
        res, code, rspHeaders = request_library.request {
            url = server_url,
            method = "POST",
            headers = reqHeaders,
            source = ltn12.source.string(reqBody),
            sink = ltn12.sink.table(rspBody),
        }

        if code == 200 then
            break -- Success, exit loop
        elseif attempts <= OpenAI.retry_limit and code == 503 then
            -- only retry when 503.
            print(string.format("Error querying Server API: %s. Retrying in %d seconds (attempt %d/%d)...", code, OpenAI.retry_delay, attempts, OpenAI.retry_limit + 1))
            socket.sleep(OpenAI.retry_delay)
        else
            -- we return the words to user, not just crash it.
            -- error("Error querying Server API after multiple retries: " .. code)
            return false, code, string.format("Error querying Server API: %s. Retrying attempt %d/%d.\n Respone: %s", code, attempts, OpenAI.retry_limit + 1, table.concat(rspBody))
        end
    end

    -- FIXME, ensure null check before return
    local response = json.decode(table.concat(rspBody))
    if response and response.choices and response.choices[1] and response.choices[1].message and response.choices[1].message.content then
        return true, code, response.choices[1].message.content
    else
        return false, code, "Error: Unexpected response format from Server API.\n Response: " .. table.concat(rspBody)
    end

end
function OpenAI.query(message_history)

    local res, code
    local resp = "No enable server found."

    -- try with main/backup server.
    if Config.config.server.enable then
        local server_info = {
            server_url = Config.config.server.server_url or "https://api.openai.com/v1/chat/completions",
            model = Config.config.server.model or "gpt-4o-mini",
            api_key = Config.config.server.api_key or "",
        }
        res, code, resp = OpenAI.request(message_history, server_info)
        if res then
            return resp
        end
    else
        print('Main server disabled.')
    end

    -- try with ollama server.
    if Config.config.ollama.enable and Config.config.ollama.server_url and Config.config.ollama.server_url ~= "" then
        local server_info = {
            server_url = Config.config.ollama.server_url,
            model = Config.config.ollama.model or "qwen3",
            api_key = Config.config.ollama.api_key or "ollama",
        }
        res, code, resp = OpenAI.request(message_history, server_info)
        if res then
            return resp
        end
    else
        print('Ollama server disabled.')
    end

    return resp

end

return OpenAI
