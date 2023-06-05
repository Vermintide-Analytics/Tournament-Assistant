local mod = get_mod("Tournament Assistant")

local DB = {}

local api_url, api_key = dofile("scripts/mods/Tournament Assistant/DB Connection")

local READ_headers = {
    "apikey: " .. api_key,
    "Authorization: Bearer " .. api_key,
    "User-agent: Vermintide"
}
local INSERT_headers = {
    "apikey: " .. api_key,
    "Authorization: Bearer " .. api_key,
    "Content-Type: application/json",
    "User-agent: Vermintide",
    "Prefer: return=representation"
}
local UPSERT_headers = {
    "apikey: " .. api_key,
    "Authorization: Bearer " .. api_key,
    "Content-Type: application/json",
    "User-agent: Vermintide",
    "Prefer: resolution=merge-duplicates,return=representation"
}

DB.status_codes = {
    info = 100,
    success = 200,
    redirect = 300,
    client_error = 400,
    server_error = 500,
}

local get_status_code = function(response_code)
    if not response_code or type(response_code) ~= "number" then
        return nil
    end
    
    -- Positive path (the most common case) comes first to minimize condition evaluation
    if response_code > 199 and response_code < 300 then
        return DB.status_codes.success
    end
    
    if response_code > 499 then
        return DB.status_codes.server_error
    end
    if response_code > 399 then
        return DB.status_codes.client_error
    end
    if response_code > 299 then
        return DB.status_codes.redirect
    end
    if response_code > 99 then
        return DB.status_codes.info
    end
    
    return nil
end

local is_success = function(status)
    return status == DB.status_codes.success
end

local handle_callback = function(success, response_code, headers, data, userdata, callback)
    local status = get_status_code(response_code)
    if not success or not is_success(status) then
        if callback then
            callback(status, data)
        end
        return
    end
    
    if not callback then
        return
    end
    
    if not data then
        callback(nil, nil)
        return
    end
    
    local decoded = cjson.decode(data)
    if not decoded then
        callback(nil, data)
        return
    end
    callback(nil, decoded)
end

-- callback format:
-- function(error_code, data)
--
-- error - nil || DB_status_codes
-- data - object already parsed from json || unparsed response if error is not nil || nil

DB.read = function(table_name, query, callback)
    -- Safely handle invalid usage
    if not table_name or #table_name < 1 then
        mod:echo("Tournament Assistant read requires a table_name")
        return
    end
    
    query = query or "select=*"
    
    local url = api_url .. table_name .. "?" .. query
    Managers.curl:get(url, READ_headers, function(success, response_code, headers, data, userdata)
        handle_callback(success, response_code, headers, data, userdata, callback)
    end)
end

DB.insert = function(table_name, body, callback)
    -- Safely handle invalid usage
    if not table_name then
        mod:echo("Tournament Assistant insert requires a table_name")
        return
    end
    if not body then
        mod:echo("Tournament Assistant insert requires a body")
        return
    end
    
    local url = api_url .. table_name
    Managers.curl:post(url, cjson.encode(body), INSERT_headers, function(success, response_code, headers, data, userdata)
        handle_callback(success, response_code, headers, data, userdata, callback)
    end)
end

DB.upsert = function(table_name, body, callback)
    -- Safely handle invalid usage
    if not table_name then
        mod:echo("Tournament Assistant upsert requires a table_name")
        return
    end
    if not body then
        mod:echo("Tournament Assistant upsert requires a body")
        return
    end
    
    local url = api_url .. table_name
    Managers.curl:post(url, cjson.encode(body), UPSERT_headers, function(success, response_code, headers, data, userdata)
        handle_callback(success, response_code, headers, data, userdata, callback)
    end)
end

return DB