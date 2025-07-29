local M = {}
local splt_input = require("ast_search.utils.split_input")

local fetch = require("ast_search.completion.fetch")
local grp = nil
function M.installAucmd()
    if not grp then grp = vim.api.nvim_create_augroup("ast-search", {}) end
    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args) M.prefetch(args.match) end,
        group = grp,
        desc = "When a new file type is opened, prefetch",
    })
end

---Prefetch completion data for a specific language
---If `lang` is not specified, uses current `'filetype'`
---Calls `cb` on completion if it is passed.
---@param lang string?
---@param cb (fun(path?: string, req?: vim.SystemObj, err?: string))?
function M.prefetch(lang, cb)
    if not lang then lang = vim.bo.filetype end
    fetch.fetchIntoDiskCache(lang, cb)
end

---To be used as a customlist completion handler
---TODO(dk949): support wildmenu
---@param lead string
---@param line string
---@return string[]
function M.complete(lead, line)
    if #splt_input(line) == 1 then return {} end
    local cmp = fetch.getCompletionsFor(vim.bo.filetype)
    return vim.iter(cmp)
        :filter(function(l) return vim.startswith(l, lead) end)
        :totable()
end

return M
