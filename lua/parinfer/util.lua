local tbl_extend = vim.tbl_extend
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
  local _2_, _3_ = t2, select("#", ...)
  if ((_2_ == nil) and (_3_ == 0)) then
    return base
  elseif ((_2_ == nil) and true) then
    local _ = _3_
    return extend(base, ...)
  elseif ((nil ~= _2_) and (_3_ == 0)) then
    local ext = _2_
    return tbl_extend("force", base, ext)
  elseif ((nil ~= _2_) and true) then
    local ext = _2_
    local _ = _3_
    return extend(extend(base, ext), ...)
  else
    return nil
  end
end
local function extend_keep(base, t2, ...)
  local _5_, _6_ = t2, select("#", ...)
  if ((_5_ == nil) and (_6_ == 0)) then
    return base
  elseif ((_5_ == nil) and true) then
    local _ = _6_
    return extend_keep(base, ...)
  elseif ((nil ~= _5_) and (_6_ == 0)) then
    local ext = _5_
    return tbl_extend("keep", base, ext)
  elseif ((nil ~= _5_) and true) then
    local ext = _5_
    local _ = _6_
    return extend_keep(extend_keep(base, ext), ...)
  else
    return nil
  end
end
return {sriapi = sriapi, extend = extend, ["extend-keep"] = extend_keep, ["reverse-ipairs"] = sriapi, ["extend-force"] = extend}
