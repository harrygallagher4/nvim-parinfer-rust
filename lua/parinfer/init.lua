local incr_bst = require("parinfer.incremental-change")
local lib = require("parinfer.lib")
local run_parinfer = nil
local _local_1_ = require("parinfer.util")
local extend_keep = _local_1_["extend-keep"]
local _local_2_ = require("parinfer.options")
local get_options = _local_2_["get-options"]
local get_buf_options = _local_2_["get-buf-options"]
local update_option = _local_2_["update-option"]
local opts_setup = _local_2_["setup"]
local buf_apply_diff = incr_bst["buf-apply-diff"]
local t_2fcat, t_2fins = table.concat, table.insert
local json, split, cmd = vim.json, vim.split, vim.cmd
local ns = vim.api.nvim_create_namespace("parinfer")
local state = {}
local expand = vim.fn.expand
local win_gettype = vim.fn.win_gettype
local create_augroup = vim.api.nvim_create_augroup
local create_autocmd = vim.api.nvim_create_autocmd
local del_augroup_by_id = vim.api.nvim_del_augroup_by_id
local del_autocmd = vim.api.nvim_del_autocmd
local win_get_cursor = vim.api.nvim_win_get_cursor
local win_set_cursor = vim.api.nvim_win_set_cursor
local get_current_buf = vim.api.nvim_get_current_buf
local buf_get_changedtick = vim.api.nvim_buf_get_changedtick
local buf_get_option = vim.api.nvim_buf_get_option
local buf_set_lines = vim.api.nvim_buf_set_lines
local buf_get_lines = vim.api.nvim_buf_get_lines
local buf_add_highlight = vim.api.nvim_buf_add_highlight
local buf_clear_namespace = vim.api.nvim_buf_clear_namespace
local process_events = {"CursorMoved", "InsertEnter", "TextChanged", "TextChangedI", "TextChangedP"}
local cursor_events = {"BufEnter", "WinEnter"}
local function notify_error(buf, request, res)
  local function _3_()
    local t_4_ = res
    if (nil ~= t_4_) then
      t_4_ = (t_4_).error
    else
    end
    return t_4_
  end
  return vim.notify(t_2fcat({("[Parinfer] error in buffer " .. buf), json.encode((_3_() or {})), json.encode(request), json.encode((res or {}))}, "\n"), vim.log.levels.ERROR)
end
local function ensure_augroup()
  if (nil == state.augroup) then
    state["augroup"] = create_augroup("parinfennel", {clear = true})
    return nil
  else
    return nil
  end
end
local function del_augroup()
  if (nil ~= state.augroup) then
    del_augroup_by_id(state.augroup)
    do end (state)["augroup"] = nil
    return nil
  else
    return nil
  end
end
local function autocmd(events, opts)
  return create_autocmd(events, extend_keep(opts, {group = "parinfennel"}))
end
local function buf_autocmd(buf, events, func)
  return t_2fins(state[buf].autocmds, autocmd(events, {callback = func, buffer = buf}))
end
local function abuf()
  return tonumber(expand("<abuf>"))
end
local function handle_trails(group)
  local function _8_(buf, trails)
    buf_clear_namespace(buf, ns, 0, -1)
    if trails then
      for _, _9_ in ipairs(trails) do
        local _each_10_ = _9_
        local startX = _each_10_["startX"]
        local endX = _each_10_["endX"]
        local lineNo = _each_10_["lineNo"]
        buf_add_highlight(buf, ns, group, lineNo, startX, endX)
      end
      return nil
    else
      return nil
    end
  end
  return _8_
end
local function get_cursor()
  local _let_12_ = win_get_cursor(0)
  local row = _let_12_[1]
  local col = _let_12_[2]
  return (row - 1), col
end
local function set_cursor(row, col)
  return win_set_cursor(0, {(row + 1), col})
end
local function get_buf_content(buf)
  local lines = buf_get_lines(buf, 0, -1, false)
  return t_2fcat(lines, "\n"), lines
end
local function refresh_changedtick(buf)
  local bufstate = state[buf]
  local function _13_()
    bufstate["changedtick"] = buf_get_changedtick(buf)
    return nil
  end
  return _13_
end
local function refresh_cursor(buf)
  local bufstate = state[buf]
  local function _14_()
    local cl, cx = get_cursor()
    local _15_ = bufstate
    _15_["cursorX"] = cx
    _15_["cursorLine"] = cl
    return _15_
  end
  return _14_
end
local function refresh_text(buf)
  local bufstate = state[buf]
  local function _16_()
    local ct = buf_get_changedtick(buf)
    if (ct ~= bufstate.changedtick) then
      local _17_ = bufstate
      _17_["changedtick"] = ct
      _17_["text"] = get_buf_content(buf)
      return _17_
    else
      return nil
    end
  end
  return _16_
end
local function refresher(buf)
  local ref_t = refresh_text(buf)
  local ref_c = refresh_cursor(buf)
  local function _19_()
    ref_t()
    return ref_c()
  end
  return _19_
end
local function make_processor(buf, mode, buf_opts)
  local bufstate = state[buf]
  local _let_20_ = buf_opts
  local commentChar = _let_20_["commentChar"]
  local stringDelimiters = _let_20_["stringDelimiters"]
  local forceBalance = _let_20_["forceBalance"]
  local lispVlineSymbols = _let_20_["lispVlineSymbols"]
  local lispBlockComments = _let_20_["lispBlockComments"]
  local guileBlockComments = _let_20_["guileBlockComments"]
  local schemeSexpComments = _let_20_["schemeSexpComments"]
  local janetLongStrings = _let_20_["janetLongStrings"]
  local trail_highlight = _let_20_["trail_highlight"]
  local trail_highlight_group = _let_20_["trail_highlight_group"]
  local refresh_cursor0 = refresh_cursor(buf)
  local refresh_text0 = refresh_text(buf)
  local refresh_changedtick0 = refresh_changedtick(buf)
  local trails_fn
  if trail_highlight then
    trails_fn = handle_trails(trail_highlight_group)
  else
    trails_fn = nil
  end
  local function process()
    if (bufstate.changedtick ~= buf_get_changedtick(buf)) then
      do
        local cl, cx = get_cursor()
        local text, lines = get_buf_content(buf)
        local req = {mode = mode, text = text, options = {commentChar = commentChar, stringDelimiters = stringDelimiters, forceBalance = forceBalance, lispVlineSymbols = lispVlineSymbols, lispBlockComments = lispBlockComments, guileBlockComments = guileBlockComments, schemeSexpComments = schemeSexpComments, janetLongStrings = janetLongStrings, cursorX = cx, cursorLine = cl, prevCursorX = bufstate.cursorX, prevCursorLine = bufstate.cursorLine, prevText = bufstate.text}}
        local res = run_parinfer(req)
        if res.success then
          if (res.text ~= text) then
            cmd("silent! undojoin")
            buf_apply_diff(buf, text, lines, res.text, split(res.text, "\n"))
          else
          end
          set_cursor(res.cursorLine, res.cursorX)
          do end (bufstate)["text"] = res.text
          if (nil ~= trails_fn) then
            trails_fn(buf, res.parenTrails)
          else
          end
        else
          bufstate["error"] = res.error
          refresh_text0()
        end
      end
      refresh_changedtick0()
    else
    end
    return refresh_cursor0()
  end
  return process
end
local function enter_buffer(buf)
  if (nil == state[buf]) then
    state[buf] = {}
    local cl, cx = get_cursor()
    local buf_opts = get_buf_options(buf)
    local processors = {smart = make_processor(buf, "smart", buf_opts), indent = make_processor(buf, "indent", buf_opts), paren = make_processor(buf, "paren", buf_opts)}
    for k, v in pairs({processors = processors, text = get_buf_content(buf), autocmds = {}, changedtick = -1, cursorX = cx, cursorLine = cl}) do
      state[buf][k] = v
    end
    local _26_ = buf
    buf_autocmd(_26_, process_events, processors[buf_opts.mode])
    buf_autocmd(_26_, cursor_events, refresh_cursor(buf))
    buf_autocmd(_26_, "InsertCharPre", refresher(buf))
  else
  end
  return state[buf].processors.paren()
end
local function initialize_buffer()
  if ("" == win_gettype()) then
    return enter_buffer(abuf())
  else
    return nil
  end
end
local function detach_buffer(buf)
  local _30_
  do
    local t_29_ = state
    if (nil ~= t_29_) then
      t_29_ = (t_29_)[buf]
    else
    end
    if (nil ~= t_29_) then
      t_29_ = (t_29_).autocmds
    else
    end
    _30_ = t_29_
  end
  if _30_ then
    for _, v in ipairs(state[buf].autocmds) do
      del_autocmd(v)
    end
  else
  end
  buf_clear_namespace(buf, ns, 0, -1)
  do end (state)[buf] = nil
  return nil
end
local function disable_parinfer_rust()
  if (1 == vim.fn.exists("g:parinfer_enabled")) then
    vim.g["parinfer_enabled"] = 0
    return nil
  else
    return nil
  end
end
local function setup_2a(conf)
  if conf then
    opts_setup(conf)
  else
  end
  ensure_augroup()
  return autocmd("FileType", {callback = initialize_buffer, pattern = {"clojure", "scheme", "lisp", "racket", "hy", "fennel", "janet", "carp", "wast", "yuck", "dune"}})
end
local function setup_21(conf)
  local _3frun
  local function _37_()
    local _36_ = conf
    if ((_G.type(_36_) == "table") and ((_36_).managed == true)) then
      return "managed"
    elseif ((_G.type(_36_) == "table") and (nil ~= (_36_).path)) then
      local p = (_36_).path
      return p
    else
      return nil
    end
  end
  _3frun = lib.load(_37_())
  if _3frun then
    run_parinfer = _3frun
    return setup_2a(conf)
  else
    return nil
  end
end
local function cleanup_21()
  return del_augroup()
end
local function attach_current_buf_21()
  disable_parinfer_rust()
  ensure_augroup()
  return enter_buffer(get_current_buf())
end
local function detach_current_buf_21()
  return detach_buffer(get_current_buf())
end
local function refresh_current_buf_21()
  local _40_ = get_current_buf()
  detach_buffer(_40_)
  enter_buffer(_40_)
  return _40_
end
local function toggle_trails_21()
  local function _41_(_241)
    return not _241
  end
  update_option("trail_highlight", _41_)
  return refresh_current_buf_21()
end
local function cmd_str(cmd_name)
  local function _42_()
    if (1 == vim.fn.exists("g:parinfer_enabled")) then
      return "ParinferFnl"
    else
      return "Parinfer"
    end
  end
  return (_42_() .. cmd_name)
end
local function parinfer_command_21(s, f, opts)
  return vim.api.nvim_create_user_command(cmd_str(s), f, (opts or {}))
end
parinfer_command_21("On", attach_current_buf_21)
parinfer_command_21("Off", detach_current_buf_21)
parinfer_command_21("Refresh", refresh_current_buf_21)
parinfer_command_21("Trails", toggle_trails_21)
parinfer_command_21("Setup", setup_21)
parinfer_command_21("Cleanup", cleanup_21)
local function _43_()
  local function _44_(_2410)
    return _2410.install()
  end
  return _44_(require("parinfer.install"))
end
parinfer_command_21("Install", _43_)
local function _45_()
  local function _46_(_2410)
    return _2410.update()
  end
  return _46_(require("parinfer.install"))
end
parinfer_command_21("Update", _45_)
return {["setup!"] = setup_21, ["cleanup!"] = cleanup_21, ["attach-current-buf!"] = attach_current_buf_21, ["detach-current-buf!"] = detach_current_buf_21, ["refresh-current-buf!"] = refresh_current_buf_21, ["toggle-trails!"] = toggle_trails_21, setup = setup_21, cleanup = cleanup_21, attach_current_buf = attach_current_buf_21, detach_current_buf = detach_current_buf_21, refresh_current_buf = refresh_current_buf_21, toggle_trails = toggle_trails_21}
