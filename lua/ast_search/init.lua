local M = {}
local cmd =   require("ast_search.cmd")

function M.setup() cmd.createSgCommand() end

return M
