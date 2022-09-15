local ffi = require("ffi")
local ffi_string = ffi.string
local _local_1_ = require("parinfer.util")
local path_concat = _local_1_["path-concat"]
local _local_2_ = vim.json
local json_encode = _local_2_["encode"]
local json_decode = _local_2_["decode"]
local get_runtime_file = vim.api.nvim_get_runtime_file
local libparinfer
do
  local _3_ = ffi.os
  if (_3_ == "OSX") then
    libparinfer = "libparinfer_rust.dylib"
  elseif (_3_ == "Windows") then
    libparinfer = "parinfer_rust.dll"
  elseif true then
    local _ = _3_
    libparinfer = "libparinfer_rust.so"
  else
    libparinfer = nil
  end
end
local function parinfer_rust_loaded_3f()
  return (0 < #get_runtime_file(path_concat("src", "parinfer.rs"), true))
end
local function resolve_lib_old()
  return (get_runtime_file(path_concat("target", "release", libparinfer), false))[1]
end
local function try_load_pack()
  if ((0 == vim.fn.exists("g:parinfer_dont_load_rust")) and not parinfer_rust_loaded_3f()) then
    vim.cmd("packadd! parinfer-rust")
    return resolve_lib_old()
  else
    return nil
  end
end
local function resolve_lib_cached()
  local _let_6_ = require("parinfer.cache")
  local installed_3f = _let_6_["installed?"]
  local target_path = _let_6_["target-path"]
  if installed_3f() then
    return target_path
  else
    return nil
  end
end
local function resolve_lib_new()
  return get_runtime_file(libparinfer, false)[1]
end
local function resolve_lib()
  return (resolve_lib_new() or try_load_pack())
end
local function runner(parinfer)
  local function run(request)
    return json_decode(ffi_string(parinfer.run_parinfer(json_encode(request))))
  end
  return run
end
local function load_parinfer(lib_path)
  if (nil == lib_path) then
    return vim.notify("Could not find parinfer library", vim.log.levels.ERROR)
  else
    local function _8_()
      ffi.cdef("char *run_parinfer(const char *json);")
      return ffi.load(lib_path)
    end
    return runner(_8_())
  end
end
local function load_2a(_3fpath)
  local function _11_()
    local _10_ = _3fpath
    if (_10_ == nil) then
      return resolve_lib()
    elseif (_10_ == "managed") then
      return resolve_lib_cached()
    elseif true then
      local _ = _10_
      return _3fpath
    else
      return nil
    end
  end
  return load_parinfer(_11_())
end
return {load = load_2a, ["load-parinfer"] = load_parinfer, libparinfer = libparinfer}
