local ffi = require("ffi")
local tbl_extend = vim.tbl_extend
local path_separator
if ("Windows" == ffi.os) then
  path_separator = "\\"
else
  path_separator = "/"
end
local function path_concat(...)
  return table.concat({...}, path_separator)
end
local function sriapi_it_2a(t, i)
  i = (i - 1)
  if (0 ~= i) then
    return i, t[i]
  else
    return nil
  end
end
local function sriapi(t)
  return sriapi_it_2a, t, (1 + #t)
end
local function extend(base, t2, ...)
  local _3_, _4_ = t2, select("#", ...)
  if ((_3_ == nil) and (_4_ == 0)) then
    return base
  elseif ((_3_ == nil) and true) then
    local _ = _4_
    return extend(base, ...)
  elseif ((nil ~= _3_) and (_4_ == 0)) then
    local ext = _3_
    return tbl_extend("force", base, ext)
  elseif ((nil ~= _3_) and true) then
    local ext = _3_
    local _ = _4_
    return extend(extend(base, ext), ...)
  else
    return nil
  end
end
local function extend_keep(base, t2, ...)
  local _6_, _7_ = t2, select("#", ...)
  if ((_6_ == nil) and (_7_ == 0)) then
    return base
  elseif ((_6_ == nil) and true) then
    local _ = _7_
    return extend_keep(base, ...)
  elseif ((nil ~= _6_) and (_7_ == 0)) then
    local ext = _6_
    return tbl_extend("keep", base, ext)
  elseif ((nil ~= _6_) and true) then
    local ext = _6_
    local _ = _7_
    return extend_keep(extend_keep(base, ext), ...)
  else
    return nil
  end
end
return {sriapi = sriapi, extend = extend, ["extend-keep"] = extend_keep, ["path-separator"] = path_separator, ["path-concat"] = path_concat, ["reverse-ipairs"] = sriapi, ["extend-force"] = extend}
