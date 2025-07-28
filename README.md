# ast-search.nvim

Use [`ast-grep`](https://github.com/ast-grep/ast-grep) to search through files.

> [!CAUTION]
> This is still very much under development. The basic functionality works (see
> below), but it's still missing a lot of things (like documentation).

## Usage

**Search for a simple pattern**

```vim
:Sg $SOME_PATTERN
```

**Search for a pattern with a kind**

> [!NOTE]
> This requires the [ESQuery style
> kind](https://ast-grep.github.io/guide/rule-config/atomic-rule.html#esquery-style-kind)
> syntax added in `ast-grep` 0.39.


```vim
Sg: $SOME_PATTERN @ some_selector
```

**Going through found items**

If `ast-grep` finds matches, they will be placed in a quickfix list (you can
navigate it with `]q` and `[q`). This is similar to how `:vimgrep` works. Each
capture will have it's own entry in the list.

**Using the `@` character in a pattern**

Since the `@` character is used to separate the pattern from the selector, it
has to be escaped to appear in a pattern: Use `\@` to escape `@` and `\\` to
escape `\`.


## TODO

- [ ] Documentation
- [ ] Tab completion for kinds used in the selector
- [ ] Support for more rule functionality (e.g. regex)
