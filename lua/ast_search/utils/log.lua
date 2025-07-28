local M = {}

---@param level vim.log.levels
---@param fmt string
---@param ... unknown
local function logf(level, fmt, ...)
    vim.notify(fmt:format(...), level)
end

---@param fmt string
---@param ... unknown
function M.infof(fmt, ...) logf(vim.log.levels.INFO, fmt, ...) end

---@param fmt string
---@param ... unknown
function M.warnf(fmt, ...) logf(vim.log.levels.WARN, fmt, ...) end

---@param fmt string
---@param ... unknown
function M.errorf(fmt, ...) logf(vim.log.levels.ERROR, fmt, ...) end

---@param fmt string
---@param ... unknown
function M.fatalf(fmt, ...) error(fmt:format(...), 2) end

return M
