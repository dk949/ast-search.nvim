local M = {}
local cmd = require("ast_search.cmd")
local cmp = require("ast_search.completion")

---@param opts {install_fetch_aucmd: boolean?}
function M.setup(opts)
    if not opts then opts = {} end
    if opts.install_fetch_aucmd then cmp.installAucmd() end
    cmp.prefetch()
    cmd.createSgCommand()
end

return M
