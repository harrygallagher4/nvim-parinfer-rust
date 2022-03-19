local t_2fins = table.insert
local tbl_extend = vim.tbl_extend
local function sriapi_it__2a(t, i)
  i = (i - 1)
  if (0 ~= i) then
    return i, t[i]
  else
    return nil
  end
end
local function sriapi_it_(t, i)
  if (1 ~= i) then
    return (i - 1), t[(i - 1)]
  else
    return nil
  end
end
local function sriapi(t)
  return sriapi_it__2a, t, (1 + #t)
end
local function merge_arg(...)
  local tbl = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if (nil ~= v) then
      t_2fins(tbl, v)
    else
    end
  end
  return tbl
end
local function merge_left(...)
  local args = merge_arg(...)
  if (1 == #args) then
    return args[1]
  else
    return tbl_extend("keep", unpack(args))
  end
end
local function merge_right(...)
  local args = merge_arg(...)
  if (1 == #args) then
    return args[1]
  else
    return tbl_extend("force", unpack(args))
  end
end
return {["merge-left"] = merge_left, ["merge-right"] = merge_right, sriapi = sriapi, ["reverse-ipairs"] = sriapi, merge = merge_right, lmerge = merge_left, rmerge = merge_right}
