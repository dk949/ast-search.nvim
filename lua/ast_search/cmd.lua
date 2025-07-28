local log = require("ast_search.utils.log")
local command = vim.api.nvim_create_user_command
local ast_grep = require("ast_search.utils")
local splitInput = require("ast_search.utils.split_input")

local M = {}

function M.createSgCommand()
    command("Sg",
        function(opts)
            local buf = nil
            if opts.bang then buf = { '.' } end
            local split = splitInput(opts.args)
            local selector = nil
            local pattern = split[1]
            if #split == 2 then
                selector = split[2]
            elseif #split ~= 1 then
                log.errorf("Incorrect format for Sg: expected `:Sg <pattern> [@ <selector>]`")
                return
            end

            if selector then
                ast_grep.scan({ pattern = pattern, kind = selector }, buf, nil, nil, true)
            else
                ast_grep.run(pattern, selector, buf, nil, true)
            end
        end,
        { nargs = '+', bang = true }
    )
end

return M
