local BACKSLASH_BACKSLASH = [[&&ast_grep_backslash_backslash&&]]
local BACKSLASH_AT = [[&&ast_grep_backslash_at&&]]

---comment
---@param input string
---@return string[]
return function(input)
    local components =
        vim.split(
            input
            :gsub([[\\]], BACKSLASH_BACKSLASH)
            :gsub([[\@]], BACKSLASH_AT)
            , "@", { plain = true }
        )
    for i, comp in ipairs(components) do
        ---@type string
        local trimmed = comp:match("^%s*(.-)%s*$")
        components[i], _ = trimmed:gsub(BACKSLASH_BACKSLASH, "\\"):gsub(BACKSLASH_AT, "@")
    end
    return components
end
