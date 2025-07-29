local M = {}
local log = require("ast_search.utils.log")
M.COMMIT = "32ca1fa06303cda407aef01b6669ae4936d3b041"

---@alias CacheEntry ({state:'done', completions:string[]})|({state:'on_disk', path:string})|({state:'fetching', request:vim.SystemObj})|({state:'failed', reason:string})|({state:'not_found'})

---@alias Cache table<string,CacheEntry>

---@alias CompletionWaiter {wait:fun():string[]}

---@type Cache
local cache = {}


---@alias CompletionJson {['$defs']:{SerializableRule:{properties:{kind:{enum:string[]}}}}}

---@param cb (fun(...:`T`):`R`)?
---@param ... `T`
---@return (`R`)?
local function maybeCall(cb, ...)
    if cb then return cb(...) end
end

local function makeUrl(lang)
    return ("https://raw.githubusercontent.com/ast-grep/ast-grep/%s/schemas/%s_rule.json"):format(M.COMMIT, lang)
end

---@param lang string
---@return string
local function makePath(lang)
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), "ast-search")
    if vim.fn.mkdir(path, "p") ~= 1 then log.fatalf("Could not create directory %s", path) end
    return vim.fs.joinpath(path, lang .. ".data")
end

---@param lang string
---@param path string
---@return boolean
local function diskCacheExists(lang, path)
    if cache[lang] and cache[lang].state == "failed" then return false end
    return vim.fn.filereadable(path) == 1
end

---Asynchronously downloads completions into disk cache
---@param lang string
---@param cb (fun(path:string?, req:vim.SystemObj?, err:string?))?
function M.fetchIntoDiskCache(lang, cb)
    local path = makePath(lang)
    if not cache[lang] or cache[lang].state == 'failed' then
        if diskCacheExists(lang, path) then
            cache[lang] = { state = "on_disk", path = path }
            maybeCall(cb, path, nil, nil)
            return
        end
        local req = vim.system({ "curl", "-fsSL", makeUrl(lang) }, { text = true },
            function(out)
                if out.code == 22 then
                    cache[lang] = { state = "not_found" }
                    maybeCall(cb, nil, nil, nil)
                elseif out.code ~= 0 or out.signal ~= 0 then
                    cache[lang] = { state = "failed", reason = out.stderr }
                    maybeCall(cb, nil, nil, out.stderr)
                    return
                end
                vim.schedule(function()
                    ---@type CompletionJson
                    local decoded = vim.fn.json_decode(out.stdout)
                    vim.fn.writefile(decoded["$defs"].SerializableRule.properties.kind.enum, path, "s")
                    cache[lang] = { state = 'on_disk', path = path }
                    maybeCall(cb, path, nil, nil)
                end)
            end)
        cache[lang] = { state = "fetching", request = req }
        return
    end
    if cache[lang].state == "not_found" then
        maybeCall(cb, nil, nil, nil)
        return
    elseif cache[lang].state == "done" or cache[lang].state == "on_disk" then
        maybeCall(cb, path, nil, nil)
        return
    elseif cache[lang].state == 'fetching' then
        maybeCall(cb, nil, cache[lang].request, nil)
        return
    end
    error("Unreachable, Cache: " .. vim.inspect(cache[lang]))
end

---Returns completion data for the specified language
---If needed the completion data will be fetched from the API, stored in a file and loaded into memory
---THIS IS BLOCKING!
---In order to avoid blocking, call `fetchIntoDiskCache` first as soon as possible
---@param lang string
---@return string[]?
function M.getCompletionsFor(lang)
    M.fetchIntoDiskCache(lang)
    if cache[lang].state == 'fetching' then cache[lang].request:wait() end
    if cache[lang].state == 'on_disk' then
        cache[lang] = { state = 'done', completions = vim.fn.readfile(cache[lang].path) }
        return cache[lang].completions
    elseif cache[lang].state == "done" then
        return cache[lang].completions
    elseif cache[lang].state == 'failed' then
        local reason = cache[lang].reason
        cache[lang] = nil
        log.fatalf("Failed to fetch completions for %s: %s", lang, reason)
    elseif cache[lang].state == "not_found" then
        return nil
    end
    error("Unreachable, Cache: " .. vim.inspect(cache[lang]))
end

return M
