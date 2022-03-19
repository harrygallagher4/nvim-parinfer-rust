local ffi = require("ffi")
local ffi_string = ffi.string
local _local_1_ = vim.json
local json_encode = _local_1_["encode"]
local json_decode = _local_1_["decode"]
local state = {}
local parinfer = nil
local function resolve_lib()
  local libname
  do
    local _2_ = ffi.os
    if (_2_ == "OSX") then
      libname = "libparinfer_rust.dylib"
    elseif (_2_ == "Windows") then
      libname = "parinfer_rust.dll"
    elseif true then
      local _ = _2_
      libname = "libparinfer_rust.so"
    else
      libname = nil
    end
  end
  return vim.api.nvim_get_runtime_file(("target/release/" .. libname), false)
end
local function runner(parinfer0)
  local function run(request)
    return json_decode(ffi_string(parinfer0.run_parinfer(json_encode(request))))
  end
  return run
end
local function load_lib()
  local _let_4_ = resolve_lib()
  local lib_path = _let_4_[1]
  if (nil == lib_path) then
    vim.notify("Could not locate parinfer library", vim.log.levels.ERROR)
  else
  end
  state["lib-path"] = lib_path
  return nil
end
local function load_parinfer()
  if (nil == state["lib-path"]) then
    return print("Cannot load parinfer")
  else
    ffi.cdef("char *run_parinfer(const char *json);")
    local ns = ffi.load(state["lib-path"])
    parinfer = ns
    state["interface"] = ns
    state["run"] = runner(ns)
    return state
  end
end
local function parinfer_rust_loaded_3f()
  return (0 < #vim.api.nvim_get_runtime_file("target/release/*parinfer_rust.*", true))
end
local function setup()
  if ((0 == vim.fn.exists("g:parinfer_dont_load_rust")) and not parinfer_rust_loaded_3f()) then
    vim.cmd("packadd! parinfer-rust")
  else
  end
  load_lib()
  return load_parinfer()
end
return setup()
