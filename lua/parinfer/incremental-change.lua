local _local_1_ = require("parinfer.util")
local merge = _local_1_["merge"]
local sriapi = _local_1_["sriapi"]
local t_2fins, t_2fcat = table.insert, table.concat
local sub = string.sub
local max = math.max
local diff = vim.diff
local split = vim.split
local buf_set_text = vim.api.nvim_buf_set_text
local buf_get_lines = vim.api.nvim_buf_get_lines
local buf_set_lines = vim.api.nvim_buf_set_lines
local create_buf = vim.api.nvim_create_buf
local d_line_opts = {result_type = "indices", ignore_cr_at_eol = true}
local d_opts = {result_type = "indices"}
local function set_line_text(buf, line, cs, ce, replacement)
  return buf_set_text(buf, line, cs, line, ce, {replacement})
end
local function diff_line(a, b)
  local inputA = t_2fcat(split(a, ""), "\n")
  local inputB = t_2fcat(split(b, ""), "\n")
  return diff(inputA, inputB, d_line_opts)
end
local function transform_range(i, j)
  if (0 == j) then
    return i, i
  else
    return (i - 1), (i + j + -1)
  end
end
local function hunk2lines(i, j)
  if (0 == j) then
    return {-1}
  else
    local range = {}
    for x = i, (i + j + -1) do
      t_2fins(range, x)
    end
    return range
  end
end
local function dl2bst_multi(strA, strB)
  local tbl_15_auto = {}
  local i_16_auto = #tbl_15_auto
  for _, _4_ in sriapi(diff_line(strA, strB)) do
    local _each_5_ = _4_
    local i = _each_5_[1]
    local j = _each_5_[2]
    local u = _each_5_[3]
    local v = _each_5_[4]
    local val_17_auto
    do
      local cs, ce = transform_range(i, j)
      val_17_auto = {cs, ce, sub(strB, u, max((u + v + -1), 0))}
    end
    if (nil ~= val_17_auto) then
      i_16_auto = (i_16_auto + 1)
      do end (tbl_15_auto)[i_16_auto] = val_17_auto
    else
    end
  end
  return tbl_15_auto
end
local function buf_apply_diff(buf, prev, prevLines, text, textLines)
  for _7_, _10_ in ipairs(diff(prev, text, d_opts)) do
    local _each_11_ = _10_
    local hl = _each_11_[1]
    local hn = _each_11_[2]
    local hle = _each_11_[3]
    local hne = _each_11_[4]
    for _8_, l in ipairs(hunk2lines(hl, hn)) do
      for _9_, _12_ in ipairs(dl2bst_multi(prevLines[l], textLines[l])) do
        local _each_13_ = _12_
        local cs = _each_13_[1]
        local ce = _each_13_[2]
        local replacement = _each_13_[3]
        set_line_text(buf, (l - 1), cs, ce, replacement)
      end
    end
  end
  return nil
end
return {["buf-apply-diff"] = buf_apply_diff}
