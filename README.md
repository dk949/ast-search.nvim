# ast-search.nvim

Use [`ast-grep`](https://github.com/ast-grep/ast-grep) to search through files.

> [!CAUTION]
> This is still very much under development. The basic functionality works (see
> below), but it's still missing a lot of things (like documentation).

## Install

Using Lazy.nvim:

```lua
{
    "dk949/ast-search.nvim",
    -- If true, will automatically prefetch completion data for each new file type
    opts = { install_fetch_aucmd = nil },
    cmd = "Sg",
}
```

## Usage

```vim
:Sg[!] {pattern} [@ {selector}]
```

The `Sg` command searches the current file for `{pattern}` and populates
quickfix list. When `!` is used searches all files in the current directory.
Only captured matches (`\$[A-Z]+`) will be placed in the quickfix list, to avoid
a match being added to qflist, use a non capturing match (`\$_[A-Z]+`). If no
captures are specified, the whole match is placed in the quickfix list. See
[ast-grep documentation](https://ast-grep.github.io/guide/pattern-syntax.html).

When `@ {selector}` is used, matches the pattern to the selector. A selector is
a treesitter node kind for the current language (use tab completion to see
available kinds). NOTE: This is not part of the `ast-grep` pattern syntax. If
you need to match the `@` character in the pattern, use `\@`. To match the
sequence `\@` in the pattern use `\\\@` (first escape the backslash, then escape
the `@`). This should be pretty rare, a backslash not preceding an `@` doesn't
need to be escaped, but can be.


Examples:

```vim
:Sg $A = $_B
```

This will place all destinations of assignment (but not sources) in the quickfix
list.

```vim
:Sg $A @ initializer_list
```

This will match all C++ initialiser lists (`{1, 2, 3}`). Note that using
`{ $A }` will match compound statements with a single statement, not initialiser
lists. A single selector matches the same kind that the pattern represents.

```vim
hello @ field_initializer_list identifier
```

This will match all instances of identifier `hello` being used in anywhere in
`field_initializer_list` (and no other instances).


> [!NOTE]
> The last example only works with [ESQuery style
> kind](https://ast-grep.github.io/guide/rule-config/atomic-rule.html#esquery-style-kind)
> syntax added in `ast-grep` 0.39.

## API usage

> [!CAUTION]
> API is currently not very stable an subject to change!

### `ast_search.utils.run`

```lua
---@param pattern string
---@param selector string?
---@param buf ast_search.BufSpec?
---@param cb (fun(matches:ast_search.Match[]):boolean)?
---@param go_to_first boolean?
---@return vim.SystemObj
function run(pattern, selector, buf, cb, go_to_first) end
```

This function acts like the `run` subcommand of `ast-grep`. It runs
asynchronously, returning a `vim.SystemObj` handle to the started process.

It takes a `pattern` and optionally a `selector` which will be passed as
`--pattern` and `--selector` arguments to `ast-grep run` respectively.

It takes an optional `ast_search.BufSpec` to determine which buffer to run on.
`nil` indicates current buffer.

The `cb` callback (if supplied) will be executed after the command has
completed, but before the quickfix list is populated. Returning `false` or `nil`
will result in quickfix list not being populated or opened. The callback takes
a list of `ast_search.Match`.

If the search succeeds and `cb` returns true (or is `nil`) the function will
call `:cfirst`. Pass `false` as the last argument to prevent this.

If the search fails, a warning will be printed.

Raises an error if `ast-grep` exits with a non-zero exit code.

### `ast_search.utils.scan`

```lua
---@param rule string|table<string,any>
---@param buf ast_search.BufSpec?
---@param lang string?
---@param cb (fun(matches:ast_search.Match[]):boolean)?
---@param go_to_first boolean?
---@return vim.SystemObj
function scan(rule, buf, lang, cb, go_to_first) end
```

This function acts like the `scan` subcommand of `ast-grep`. It runs
asynchronously, returning a `vim.SystemObj` handle to the started process.

The `rule` argument corresponds to the `rule` key in the inline rule (i.e. you
don't need to specify `id` or language or include the key `rule` itself).

It takes an optional `ast_search.BufSpec` to determine which buffer to run on.
`nil` indicates current buffer.

The optional `lang` argument will be passed as the `language` key in the rule.
If it is omitted, the language of the current buffer is used.

`cb` and `go_to_first` work the same as in `ast_search.utils.run`.


### `ast_search.BufSpec`

A list of buffer IDs or names.

### `ast_search.Position`

```
{
    line: integer # zero-based line number
    column: integer # zero-based column number
}
```

### `ast_search.ByteOffset`

```
    start: integer # start is inclusive
    end: integer   # end is exclusive
```

### `ast_search.Range`

```
    byteOffset: ast_search.ByteOffset
    start: ast_search.Position
    end: ast_search.Position
```

### `ast_search.MetaVar`

```
    text: string
    range: ast_search.Range
```

### `ast_search.MetaVariables`

```
    single: table<string, ast_search.MetaVar>
    multi: table<string, ast_search.MetaVar[]>
    transformed: table<string, string>
```

### `ast_search.Match`

```
{
    text: string
    range: ast_search.Range
    file: string # relative path to the file
    lines: string # surrounding lines of the match
    replacement: string? # optional replacement if present
    replacementOffsets: ast_search.ByteOffset?
    metaVariables: ast_search.MetaVariables?
}
```

## TODO

- [X] Documentation
- [X] Tab completion for kinds used in the selector
- [ ] Support for more rule functionality (e.g. regex)
- [ ] Support selector of the form `kind > *` which would map to `inside: kind`
- [ ] Allow for a keymapping similar to `/` or `?` (maybe `@/` and `@?` by
  default, since that's unlikely to be very useful by itself). Then make
  a buffer local mapping for `n`/`N` which goes through the results
    - `'hlsearch'` integration would be a bonus (even if I don't use it myself)
    - `'incsearch'` would be really nice, but I suspect might be too slow?
