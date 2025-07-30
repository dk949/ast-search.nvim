local log = require("ast_search.utils.log")
---@alias ast_search.BufSpec (integer|string)[]


---@class ast_search.Position
---@field line integer # zero-based line number
---@field column integer # zero-based column number

---@class ast_search.ByteOffset
---@field start integer # start is inclusive
---@field end integer   # end is exclusive

---@class ast_search.Range
---@field byteOffset ast_search.ByteOffset
---@field start ast_search.Position
---@field end ast_search.Position

---@class ast_search.MetaVar
---@field text string
---@field range ast_search.Range

---@class ast_search.MetaVariables
---@field single table<string, ast_search.MetaVar>
---@field multi table<string, ast_search.MetaVar[]>
---@field transformed table<string, string>

---@class ast_search.Match
---@field text string
---@field range ast_search.Range
---@field file string # relative path to the file
---@field lines string # surrounding lines of the match
---@field replacement string? # optional replacement if present
---@field replacementOffsets ast_search.ByteOffset?
---@field metaVariables ast_search.MetaVariables?

local M = {}
local TEXT_WIDTH = 40

---@param out vim.SystemCompleted
local function handleError(out)
    if out.code ~= 0 or out.signal ~= 0 then
        log.fatalf("ast-grep failed:\n%s", out.stderr)
    end
end

---comment
---@param text string
---@param len integer
---@return string
local function trimText(text, len)
    assert(len > 3)
    if #text <= len then return text end
    return text:sub(1, len - 3) .. "..."
end

---@param single table<string, ast_search.MetaVar>
---@param multi table<string, ast_search.MetaVar[]>
---@return { name: string, var: ast_search.MetaVar}[]
local function combineMetavars(single, multi)
    ---@type ast_search.MetaVar[]
    local out = {}
    for name, var in pairs(single) do
        var.text = ("(%s): %s"):format(name, var.text)
        table.insert(out, var)
    end
    for name, vars in pairs(multi) do
        for _, var in ipairs(vars) do
            var.text = ("(%s): %s"):format(name, var.text)
            table.insert(out, var)
        end
    end
    table.sort(out, function(a, b)
        if a.range.start.line < b.range.start.line then return true end
        if a.range.start.line > b.range.start.line then return false end
        return a.range.start.column < b.range.start.column
    end)
    return out
end

---comment
---@param entry vim.quickfix.entry
---@param data ast_search.Match|ast_search.MetaVar
---@return vim.quickfix.entry
local function populateEntry(entry, data)
    for key, value in pairs({
        lnum = data.range.start.line + 1,
        col = data.range.start.column + 1,
        end_lnum = data.range["end"].line + 1,
        end_col = data.range["end"].column + 1,
        text = trimText(data.text, TEXT_WIDTH),
    }) do
        entry[key] = value
    end
    return entry
end

---@param out vim.SystemCompleted
---@param cb (fun(matches:ast_search.Match[]):boolean)?
---@return boolean
local function populateQflist(out, cb)
    handleError(out)
    ---@type ast_search.Match[]
    local matches = vim.fn.json_decode(out.stdout)
    local add_to_list = true
    if cb then add_to_list = cb(matches) end
    if not add_to_list then return false end
    ---@type vim.quickfix.entry[]
    local qflist = {}
    for _, match in ipairs(matches) do
        local entry = { filename = match.file, vcol = false, type = "", }
        if match.metaVariables then
            local combined_metavars = combineMetavars(match.metaVariables.single, match.metaVariables.multi)
            for _, var in ipairs(combined_metavars) do
                table.insert(qflist, populateEntry(vim.deepcopy(entry), var))
            end
        else
            table.insert(qflist, populateEntry(entry, match))
        end
    end
    if #qflist == 0 then
        log.warnf("ast-grep did not find anything!")
        return false
    else
        vim.fn.setqflist(qflist)
        return true
    end
end

---comment
---@param rule string|table<string, any>
---@param lang string
---@return string
local function makeInlineRule(rule, lang)
    if type(rule) == "string" then
        return makeInlineRule({ pattern = rule }, lang)
    end
    return vim.fn.json_encode({ id = "inline-rule", language = lang, rule = rule })
end

---@param buf ast_search.BufSpec?
---@return string[]
local function getBufNames(buf)
    if not buf then buf = { vim.fn.bufname('%') } end
    return vim.iter(buf):map(function(b)
        if type(b) == "number" then
            return vim.fn.bufname(b)
        end
        return b
    end):totable()
end


---comment
---@param subcmd string
---@param buf ast_search.BufSpec?
---@param args string[]
---@param cb (fun(matches:ast_search.Match[]):boolean)?
---@param go_to_first boolean?
---@return vim.SystemObj
local function runAstGrep(subcmd, buf, args, cb, go_to_first)
    buf = getBufNames(buf)
    local cmd_args = { "ast-grep" }
    table.insert(cmd_args, subcmd)
    table.insert(cmd_args, "--json=compact")
    vim.list_extend(cmd_args, buf)
    vim.list_extend(cmd_args, args)
    return vim.system(cmd_args, { text = true }, vim.schedule_wrap(function(out)
        if populateQflist(out, cb) and go_to_first then vim.cmd.cfirst() end
    end))
end

---Run ast-grep scan in a given buffer
---@param pattern string
---@param selector string?
---@param buf ast_search.BufSpec?
---@param cb (fun(matches:ast_search.Match[]):boolean)?
---@param go_to_first boolean?
---@return vim.SystemObj
function M.run(pattern, selector, buf, cb, go_to_first)
    local args = { "--pattern", pattern }
    if selector then args = vim.list_extend(args, { "--selector", selector }) end

    return runAstGrep("run", buf, args, cb, go_to_first)
end

---Run ast-grep scan in a given buffer
---@param rule string|table<string,any>
---@param buf ast_search.BufSpec?
---@param lang string?
---@param cb (fun(matches:ast_search.Match[]):boolean)?
---@param go_to_first boolean?
---@return vim.SystemObj
function M.scan(rule, buf, lang, cb, go_to_first)
    if not lang then
        lang = vim.bo.filetype
    end
    return runAstGrep("scan", buf, { "--inline-rules", makeInlineRule(rule, lang) }, cb, go_to_first)
end


return M
