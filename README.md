# nvim-parinfer-rust

Use luajit's ffi to load [parinfer-rust][]'s C bindings in hopes of
improving performance.

This plugin is two things, both of which are experimental.

### 1

As said above, a lua (fennel) replacement for [parinfer-rust][]'s
vimscript plugin. Writing the plugin in lua should improve performance
solely due to how often `process` is called. In addition to that,
luajit's ffi allows the parinfer-rust library to be loaded and called
directly. I'm unsure about ffi vs. vim's `libcall` performance. Some
profiling is probably in order.

### 2

A fix for something that has personally annoyed me about parinfer-rust.
The vimscript plugin built in to parinfer-rust sets the text of the
entire buffer when the library reports changes. This method of setting
the text seems to break neovim's extmarks which in turn breaks Luasnip,
and potentially other plugins relying on extmarks. This behaviour could
potentially be fixed by just using neovim's `buf_set_lines` instead of
`setline`, I honestly didn't even consider testing `buf_set_lines` and
just realized this as I write this readme. I suppose that's worth
testing. Anyway, I wrote
[src/incremental-change.fnl](src/incremental-change.fnl) and a
`buf-apply-diff` function that computes a diff for the entire file, then
another diff for each of the changed lines and finally uses
`nvim_buf_set_text` to make the smallest possible changes. Since
parinfer usually only needs to insert/delete a single bracket or some
indentation, this has worked fine so far. It's possible that this whole
process negates any performance gain from part 1 of this plugin. I found
the implementation interesting though. Again, this plugin is still in
what I would consider a *very* experimental stage. It's possible that
`nvim_buf_set_text` on the changed lines, or `nvim_buf_set_lines` on the
entire buffer would preserve extmarks properly. I hope to test the
different methods of text changing for performance and behaviour.

## Installing

Since this plugin depends on [parinfer-rust][], you need to have that
installed as well. In order to prevent interference, I recommend
installing that as an `opt` plugin. There is specific logic in
[lib.fnl][] that will handle adding [parinfer-rust][] to the runtimepath
without loading its vimscript plugin. `require'parinfer'.setup()` should
be called *after* vim's startup so that `packadd! parinfer-rust` works
properly.

```lua
-- calling require'parinfer' before VimEnter will not work, it must be
-- called inside of the VimEnter callback.
local function load_parinfer()
  require("parinfer").setup()
end

vim.api.nvim_create_autocmd("VimEnter", {callback = load_parinfer})
```


[parinfer-rust]: https://github.com/eraserhd/parinfer-rust

