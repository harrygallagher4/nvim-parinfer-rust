local config_opts = {}
local defaults = {enabled = true, mode = "smart", trail_highlight = true, trail_highlight_group = "Whitespace", commentChar = ";", stringDelimiters = {"\""}, guileBlockComments = false, forceBalance = false, janetLongStrings = false, schemeSexpComments = false, lispBlockComments = false, lispVlineSymbols = false}
local ft_opts = {lisp = {lispVlineSymbols = true, lispBlockComments = true}, scheme = {lispVlineSymbols = true, lispBlockComments = true}, janet = {commentChar = "#", janetLongStrings = true}, yuck = {stringDelimiters = {"\"", "'", "`"}}}
local scoped_opts_2a = {mode = "mode", enabled = "enabled", trail_highlight = "trail_highlight", trail_highlight_group = "trail_highlight_group", force_balance = "forceBalance", comment_char = "commentChar", string_delimiters = "stringDelimiters", lisp_vline_symbols = "lispVlineSymbols", lisp_block_comments = "lispBlockComments", guile_block_comments = "guileBlockComments", scheme_sexp_comments = "schemeSexpComments", janet_long_strings = "janetLongStrings"}
local scoped_opts
do
  local tbl_12_auto = {}
  for k, v in pairs(scoped_opts_2a) do
    local _1_, _2_ = ("parinfer_" .. k), v
    if ((nil ~= _1_) and (nil ~= _2_)) then
      local k_13_auto = _1_
      local v_14_auto = _2_
      tbl_12_auto[k_13_auto] = v_14_auto
    else
    end
  end
  scoped_opts = tbl_12_auto
end
local function extend(base, extension, ...)
  if (0 == select("#", ...)) then
    return vim.tbl_extend("force", base, (extension or {}))
  elseif (nil == extension) then
    return extend(base, ...)
  else
    return extend(extend(base, extension), ...)
  end
end
local function resolve_value(val)
  if ("number" == type(val)) then
    return (1 == val)
  else
    return val
  end
end
local function get_global_vars()
  local tbl_12_auto = {}
  for varname, optname in pairs(scoped_opts) do
    local _6_, _7_ = optname, resolve_value(vim.g[varname])
    if ((nil ~= _6_) and (nil ~= _7_)) then
      local k_13_auto = _6_
      local v_14_auto = _7_
      tbl_12_auto[k_13_auto] = v_14_auto
    else
    end
  end
  return tbl_12_auto
end
local function get_buffer_vars(buf)
  local tbl_12_auto = {}
  for varname, optname in pairs(scoped_opts) do
    local _9_, _10_ = optname, resolve_value(vim.b[(buf or 0)][varname])
    if ((nil ~= _9_) and (nil ~= _10_)) then
      local k_13_auto = _9_
      local v_14_auto = _10_
      tbl_12_auto[k_13_auto] = v_14_auto
    else
    end
  end
  return tbl_12_auto
end
local function get_configured()
  return extend(defaults, config_opts)
end
local function get_options(config)
  return extend(defaults, config_opts, config, get_global_vars())
end
local function get_buf_options(buf, config)
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")
  return extend(defaults, config_opts, config, (ft_opts[ft] or {}), get_global_vars(), get_buffer_vars(buf))
end
local function setup(config)
  config_opts = (config or {})
  return nil
end
local function set_option(opt, v)
  config_opts[opt] = v
  return nil
end
local function update_option(opt, f)
  config_opts[opt] = f(get_configured()[opt])
  return nil
end
return {["get-options"] = get_options, get_options = get_options, ["get-buf-options"] = get_buf_options, get_buf_options = get_buf_options, ["update-option"] = update_option, setup = setup}
