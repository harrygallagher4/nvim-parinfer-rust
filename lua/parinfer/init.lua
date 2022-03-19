local incr_bst = require("parinfer.incremental-change")
local _local_1_ = require("parinfer.lib")
local run_parinfer = _local_1_["run"]
local _local_2_ = require("parinfer.util")
local lmerge = _local_2_["lmerge"]
local rmerge = _local_2_["rmerge"]
local buf_apply_diff = incr_bst["buf-apply-diff"]
local t_2fcat, t_2fins = table.concat, table.insert
local json, split, cmd = vim.json, vim.split, vim.cmd
local ns = vim.api.nvim_create_namespace("parinfer")
local settings = {mode = "smart", trail_highlight = true, trail_highlight_group = "Whitespace"}
local expand = vim.fn.expand
local win_gettype = vim.fn.win_gettype
local str2nr = vim.fn.str2nr
local create_augroup = vim.api.nvim_create_augroup
local create_autocmd = vim.api.nvim_create_autocmd
local del_augroup_by_id = vim.api.nvim_del_augroup_by_id
local del_autocmd = vim.api.nvim_del_autocmd
local win_get_cursor = vim.api.nvim_win_get_cursor
local win_set_cursor = vim.api.nvim_win_set_cursor
local get_current_buf = vim.api.nvim_get_current_buf
local buf_get_changedtick = vim.api.nvim_buf_get_changedtick
local buf_set_lines = vim.api.nvim_buf_set_lines
local buf_get_lines = vim.api.nvim_buf_get_lines
local buf_add_highlight = vim.api.nvim_buf_add_highlight
local buf_clear_namespace = vim.api.nvim_buf_clear_namespace
local process_events = {"CursorMoved", "InsertEnter", "TextChanged", "TextChangedI", "TextChangedP"}
local cursor_events = {"BufEnter", "WinEnter"}
local state = {mode = settings.mode, augroup = nil}
local function notify_error(buf, request, response)
  local function _4_()
    local t_3_ = response
    if (nil ~= t_3_) then
      t_3_ = (t_3_).error
    else
    end
    return t_3_
  end
  return vim.notify(t_2fcat({("[Parinfer] error in buffer " .. buf), json.encode((_4_() or {})), json.encode(request), json.encode((response or {}))}, "\n"), vim.log.levels.ERROR)
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
  return create_autocmd(events, lmerge(opts, {group = "parinfennel"}))
end
local function buf_autocmd(buf, events, func)
  return t_2fins(state[buf].autocmds, autocmd(events, {callback = func, buffer = buf}))
end
local function abuf()
  return str2nr(expand("<abuf>"))
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
    do end (bufstate)["cursorX"] = cx
    bufstate["cursorLine"] = cl
    return nil
  end
  return _14_
end
local function refresh_text(buf)
  local bufstate = state[buf]
  local function _15_()
    local ct = buf_get_changedtick(buf)
    if (ct ~= bufstate.changedtick) then
      bufstate["changedtick"] = ct
      bufstate["text"] = get_buf_content(buf)
      return nil
    else
      return nil
    end
  end
  return _15_
end
local function refresher(buf)
  local ref_t = refresh_text(buf)
  local ref_c = refresh_cursor(buf)
  local function _17_()
    ref_t()
    return ref_c()
  end
  return _17_
end
local function make_processor(buf, mode)
  local bufstate = state[buf]
  local commentChar = ";"
  local stringDelimiters = {"\""}
  local forceBalance = false
  local lispVlineSymbols = false
  local lispBlockComments = false
  local guileBlockComments = false
  local schemeSexpComments = false
  local janetLongStrings = false
  local refresh_cursor0 = refresh_cursor(buf)
  local refresh_text0 = refresh_text(buf)
  local refresh_changedtick0 = refresh_changedtick(buf)
  local trails_func
  if settings.trail_highlight then
    trails_func = handle_trails(settings.trail_highlight_group)
  else
    trails_func = nil
  end
  local function process()
    if (bufstate.changedtick ~= buf_get_changedtick(buf)) then
      do
        local cl, cx = get_cursor()
        local original_text, original_lines = get_buf_content(buf)
        local req = {mode = mode, text = original_text, options = {commentChar = commentChar, stringDelimiters = stringDelimiters, forceBalance = forceBalance, lispVlineSymbols = lispVlineSymbols, lispBlockComments = lispBlockComments, guileBlockComments = guileBlockComments, schemeSexpComments = schemeSexpComments, janetLongStrings = janetLongStrings, cursorX = cx, cursorLine = cl, prevCursorX = bufstate.cursorX, prevCursorLine = bufstate.cursorLine, prevText = bufstate.text}}
        local response = run_parinfer(req)
        if response.success then
          if (response.text ~= original_text) then
            cmd("silent! undojoin")
            buf_apply_diff(buf, original_text, original_lines, response.text, split(response.text, "\n"))
          else
          end
          set_cursor(response.cursorLine, response.cursorX)
          do end (bufstate)["text"] = response.text
          if (nil ~= trails_func) then
            trails_func(buf, response.parenTrails)
          else
          end
        else
          notify_error(buf, req, response)
          do end (bufstate)["error"] = response.error
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
    local process = make_processor(buf, "smart")
    local process_paren = make_processor(buf, "paren")
    for k, v in pairs({process = process, ["process-paren"] = process_paren, text = get_buf_content(buf), autocmds = {}, changedtick = -1, cursorX = cx, cursorLine = cl}) do
      state[buf][k] = v
    end
    buf_autocmd(buf, process_events, process)
    buf_autocmd(buf, cursor_events, refresh_cursor(buf))
    buf_autocmd(buf, "InsertCharPre", refresher(buf))
  else
  end
  return state[buf]["process-paren"]()
end
local function initialize_buffer()
  if ("" == win_gettype()) then
    return enter_buffer(abuf())
  else
    return nil
  end
end
local function detach_buffer(buf)
  local _26_
  do
    local t_25_ = state
    if (nil ~= t_25_) then
      t_25_ = (t_25_)[buf]
    else
    end
    if (nil ~= t_25_) then
      t_25_ = (t_25_).autocmds
    else
    end
    _26_ = t_25_
  end
  if _26_ then
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
    for k, v in pairs(rmerge(settings, conf)) do
      settings[k] = v
    end
  else
  end
  ensure_augroup()
  return autocmd("FileType", {pattern = {"clojure", "scheme", "lisp", "racket", "hy", "fennel", "janet", "carp", "wast", "yuck", "dune"}, callback = initialize_buffer})
end
local function cleanup_21()
  return del_augroup()
end
local function attach_current_buf_21()
  disable_parinfer_rust()
  ensure_augroup()
  local buf = get_current_buf()
  return enter_buffer(buf)
end
local function detach_current_buf_21()
  local buf = get_current_buf()
  return detach_buffer(buf)
end
local function refresh_current_buf_21()
  local buf = get_current_buf()
  detach_buffer(buf)
  return enter_buffer(buf)
end
local function toggle_trails_21()
  settings["trail_highlight"] = not settings.trail_highlight
  return refresh_current_buf_21()
end
local function cmd_str(s)
  local prefix
  if (1 == vim.fn.exists("g:parinfer_enabled")) then
    prefix = "ParinferFnl"
  else
    prefix = "Parinfer"
  end
  return (prefix .. s)
end
local function parinfer_command_21(s, f, opts)
  return vim.api.nvim_add_user_command(cmd_str(s), f, (opts or {}))
end
parinfer_command_21("On", attach_current_buf_21)
parinfer_command_21("Off", detach_current_buf_21)
parinfer_command_21("Refresh", refresh_current_buf_21)
parinfer_command_21("Trails", toggle_trails_21)
parinfer_command_21("Setup", setup_21)
parinfer_command_21("Cleanup", cleanup_21)
local function toggle_paren_hl()
  local hl = vim.api.nvim__get_hl_defs(0)
  local fnlP = hl.fennelTSPunctBracket.link
  if (fnlP == "TSPunctBracket") then
    vim.cmd("highlight! link fennelTSPunctBracket Whitespace")
  else
  end
  if (fnlP == "Whitespace") then
    return vim.cmd("highlight! link fennelTSPunctBracket TSPunctBracket")
  else
    return nil
  end
end
vim.api.nvim_add_user_command("Phl", toggle_paren_hl, {})
return {["setup!"] = setup_21, ["cleanup!"] = cleanup_21, ["attach-current-buf!"] = attach_current_buf_21, ["detach-current-buf!"] = detach_current_buf_21, ["refresh-current-buf!"] = refresh_current_buf_21, ["toggle-trails!"] = toggle_trails_21, ["toggle-paren-hl"] = toggle_paren_hl, setup = setup_21, cleanup = cleanup_21, ["attach-current-buf"] = attach_current_buf_21, ["detach-current-buf"] = detach_current_buf_21, ["refresh-current-buf"] = refresh_current_buf_21, ["toggle-trails"] = toggle_trails_21}
