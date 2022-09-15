# nvim-parinfer-rust

Use luajit's ffi to load [parinfer-rust][]'s C bindings in hopes of improving
performance.

This plugin is two things, both of which are experimental.

**Update**: I have been using this plugin for ~5 months now and haven't run
into any issues! Occasionally I run into the same undo issue that parinfer-rust
has, though less often.

### 1

As said above, a lua (fennel) replacement for [parinfer-rust][]'s vimscript
plugin. Writing the plugin in lua should improve performance solely due to how
often `process` is called. In addition to that, luajit's ffi allows the
parinfer-rust library to be loaded and called directly. I'm unsure about ffi
vs. vim's `libcall` performance. Some profiling is probably in order.

### 2

A fix for something that has personally annoyed me about parinfer-rust. The
vimscript plugin built in to parinfer-rust sets the text of the entire buffer
when the library reports changes. This method of setting the text seems to
break neovim's extmarks which in turn breaks Luasnip, and potentially other
plugins relying on extmarks. This behaviour could potentially be fixed by just
using neovim's `buf_set_lines` instead of `setline`, I honestly didn't even
consider testing `buf_set_lines` and just realized this as I write this readme.
I suppose that's worth testing. Anyway, I wrote [incremental-change.fnl][] and
a `buf-apply-diff` function that computes a diff for the entire file, then
another diff for each of the changed lines and finally uses `nvim_buf_set_text`
to make the smallest possible changes. Since parinfer usually only needs to
insert/delete a single bracket or some indentation, this has worked fine so
far. It's possible that this whole process negates any performance gain from
part 1 of this plugin. I found the implementation interesting though. Again,
this plugin is still in what I would consider a *very* experimental stage. It's
possible that `nvim_buf_set_text` on the changed lines, or `nvim_buf_set_lines`
on the entire buffer would preserve extmarks properly. I hope to test the
different methods of text changing for performance and behaviour.


## Installing

This plugin depends on the library from [parinfer-rust][]. In order to prevent
parinfer-rust's vim plugin from loading, it should be installed as an `opt`
plugin with its `target/release` directory added to `runtimepath`.
Alternatively `:ParinferInstall` can download/compile parinfer-rust in nvim's
cache directory which can then be loaded by including `{managed = true}` in
your configuration.


### Using packer.nvim

```lua
use {
  'eraserhd/parinfer-rust',
  opt = true,
  rtp = 'target/release',
  run = 'cargo build --release'
}
use {
  'harrygallagher4/nvim-parinfer-rust',
  config = function()
    vim.api.nvim_create_autocmd(
      'VimEnter',
      { callback = function() require'parinfer'.setup() end}
    )
  end
}
```

### Using vim-plug

```vim
call plug#begin()
" ...
Plug 'eraserhd/parinfer-rust', {'rtp': 'target/release'}
Plug 'harrygallagher4/nvim-parinfer-rust'
" ...
call plug#end()


autocmd VimEnter * lua require('parinfer').setup()
```


[parinfer-rust]: https://github.com/eraserhd/parinfer-rust
[incremental-change.fnl]: fnl/parinfer/incremental-change.fnl
[lib.fnl]: fnl/parinfer/lib.fnl

