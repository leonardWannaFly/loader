--[[
  Nocturne Key Check Library by (Luarmor)
  Host this file (GitHub raw / your CDN) and load it from your loader.

  Usage:
    local api = loadstring(game:HttpGet("https://YOUR_HOST/sdk/nocturne_library.lua"))()
    api.api_url = "https://YOUR_SERVER:PORT"  -- tanpa slash di akhir
    local status = api.check_key(script_key)
    if status.code == "KEY_VALID" then
        -- load script
    end
]]

local HttpService = game:GetService("HttpService")

local api = {}
api.api_url = "http://127.0.0.1:3000" -- GANTI ke URL API bot kamu
api.script_id = "nocturne"            -- opsional, untuk multi-project nanti

local function request(path, body)
    local url = api.api_url .. path
    local ok, res = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(body or {})
        })
    end)

    if not ok then
        return { code = "UNKNOWN_ERROR", message = "Request failed: " .. tostring(res) }
    end

    if not res.Success then
        local decoded
        pcall(function()
            decoded = HttpService:JSONDecode(res.Body)
        end)
        if decoded and decoded.code then
            return decoded
        end
        return { code = "UNKNOWN_ERROR", message = "HTTP " .. tostring(res.StatusCode) }
    end

    local decoded
    local decodeOk, decodeErr = pcall(function()
        decoded = HttpService:JSONDecode(res.Body)
    end)
    if not decodeOk or type(decoded) ~= "table" then
        return { code = "UNKNOWN_ERROR", message = "Invalid JSON response" }
    end
    return decoded
end

--- Ambil HWID dari executor (fallback string)
function api.get_hwid()
    local candidates = {
        function() return gethwid and gethwid() end,
        function() return get_hwid and get_hwid() end,
        function() return game:GetService("RbxAnalyticsService"):GetClientId() end,
    }
    for _, fn in ipairs(candidates) do
        local ok, val = pcall(fn)
        if ok and type(val) == "string" and #val > 4 then
            return val
        end
    end
    return "unknown-hwid"
end

--- Check key — response Luarmor
--- @return table { code, message, data? }
function api.check_key(user_key)
    if type(user_key) ~= "string" or #user_key < 8 then
        return {
            code = "KEY_INVALID",
            message = "The provided key is in an invalid format."
        }
    end

    local hwid = api.get_hwid()
    return request("/api/v1/check_key", {
        key = user_key,
        hwid = hwid
    })
end

--- Contoh helper: cek + load loader utama kamu
function api.load_script(loader_url)
    loader_url = loader_url or "https://raw.githubusercontent.com/x2arne/loader/refs/heads/main/Mainloader.lua"
    local src = game:HttpGet(loader_url)
    local fn, err = loadstring(src)
    if not fn then
        error("Failed to load script: " .. tostring(err))
    end
    return fn()
end

return api
