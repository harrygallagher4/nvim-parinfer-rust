local incr_bst = require("parinfer.incremental-change")
local _local_1_ = require("parinfer.lib")
local run_parinfer = _local_1_["run"]
local _local_2_ = require("parinfer.util")
local extend_keep = _local_2_["extend-keep"]
local _local_3_ = require("parinfer.options")
local get_options = _local_3_["get-options"]
local get_buf_options = _local_3_["get-buf-options"]
local update_option = _local_3_["update-option"]
local opts_setup = _local_3_["setup"]
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
  local function _4_()
    local t_5_ = res
    if (nil ~= t_5_) then
      t_5_ = (t_5_).error
    else
    end
    return t_5_
  end
  return vim.notify(t_2fcat({("[Parinfer] error in buffer " .. buf), json.encode((_4_() or {})), json.encode(request), json.encode((res or {}))}, "\n"), vim.log.levels.ERROR)
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
  local function _9_(buf, trails)
    buf_clear_namespace(buf, ns, 0, -1)
    if trails then
      for _, _10_ in ipairs(trails) do
        local _each_11_ = _10_
        local startX = _each_11_["startX"]
        local endX = _each_11_["endX"]
        local lineNo = _each_11_["lineNo"]
        buf_add_highlight(buf, ns, group, lineNo, startX, endX)
      end
      return nil
    else
      return nil
    end
  end
  return _9_
end
local function get_cursor()
  local _let_13_ = win_get_cursor(0)
  local row = _let_13_[1]
  local col = _let_13_[2]
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
  local function _14_()
    bufstate["changedtick"] = buf_get_changedtick(buf)
    return nil
  end
  return _14_
end
local function refresh_cursor(buf)
  local bufstate = state[buf]
  local function _15_()
    local cl, cx = get_cursor()
    local _16_ = bufstate
    _16_["cursorX"] = cx
    _16_["cursorLine"] = cl
    return _16_
  end
  return _15_
end
local function refresh_text(buf)
  local bufstate = state[buf]
  local function _17_()
    local ct = buf_get_changedtick(buf)
    if (ct ~= bufstate.changedtick) then
      local _18_ = bufstate
      _18_["changedtick"] = ct
      _18_["text"] = get_buf_content(buf)
      return _18_
    else
      return nil
    end
  end
  return _17_
end
local function refresher(buf)
  local ref_t = refresh_text(buf)
  local ref_c = refresh_cursor(buf)
  local function _20_()
    ref_t()
    return ref_c()
  end
  return _20_
end
local function make_processor(buf, mode, buf_opts)
  local bufstate = state[buf]
  local _let_21_ = buf_opts
  local commentChar = _let_21_["commentChar"]
  local stringDelimiters = _let_21_["stringDelimiters"]
  local forceBalance = _let_21_["forceBalance"]
  local lispVlineSymbols = _let_21_["lispVlineSymbols"]
  local lispBlockComments = _let_21_["lispBlockComments"]
  local guileBlockComments = _let_21_["guileBlockComments"]
  local schemeSexpComments = _let_21_["schemeSexpComments"]
  local janetLongStrings = _let_21_["janetLongStrings"]
  local trail_highlight = _let_21_["trail_highlight"]
  local trail_highlight_group = _let_21_["trail_highlight_group"]
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
          notify_error(buf, req, res)
          do end (bufstate)["error"] = res.error
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
    local _27_ = buf
    buf_autocmd(_27_, process_events, processors[buf_opts.mode])
    buf_autocmd(_27_, cursor_events, refresh_cursor(buf))
    buf_autocmd(_27_, "InsertCharPre", refresher(buf))
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
  local _31_
  do
    local t_30_ = state
    if (nil ~= t_30_) then
      t_30_ = (t_30_)[buf]
    else
    end
    if (nil ~= t_30_) then
      t_30_ = (t_30_).autocmds
    else
    end
    _31_ = t_30_
  end
  if _31_ then
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
local function setup_21(conf)
  if conf then
    opts_setup(conf)
  else
  end
  ensure_augroup()
  return autocmd("FileType", {callback = initialize_buffer, pattern = {"clojure", "scheme", "lisp", "racket", "hy", "fennel", "janet", "carp", "wast", "yuck", "dune"}})
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
  local _37_ = get_current_buf()
  detach_buffer(_37_)
  enter_buffer(_37_)
  return _37_
end
local function toggle_trails_21()
  local function _38_(_241)
    return not _241
  end
  update_option("trail_highlight", _38_)
  return refresh_current_buf_21()
end
local function cmd_str(cmd_name)
  local function _39_()
    if (1 == vim.fn.exists("g:parinfer_enabled")) then
      return "ParinferFnl"
    else
      return "Parinfer"
    end
  end
  return (_39_() .. cmd_name)
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
return {["setup!"] = setup_21, ["cleanup!"] = cleanup_21, ["attach-current-buf!"] = attach_current_buf_21, ["detach-current-buf!"] = detach_current_buf_21, ["refresh-current-buf!"] = refresh_current_buf_21, ["toggle-trails!"] = toggle_trails_21, setup = setup_21, cleanup = cleanup_21, attach_current_buf = attach_current_buf_21, detach_current_buf = detach_current_buf_21, refresh_current_buf = refresh_current_buf_21, toggle_trails = toggle_trails_21}
