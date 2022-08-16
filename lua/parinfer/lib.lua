local ffi = require("ffi")
local ffi_string = ffi.string
local _local_1_ = vim.json
local json_encode = _local_1_["encode"]
local json_decode = _local_1_["decode"]
local get_runtime_file = vim.api.nvim_get_runtime_file
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
  return get_runtime_file(("target/release/" .. libname), false)
end
local function runner(parinfer)
  local function run(request)
    return json_decode(ffi_string(parinfer.run_parinfer(json_encode(request))))
  end
  return run
end
local function load_lib()
  local _let_4_ = resolve_lib()
  local lib_path = _let_4_[1]
  return lib_path
end
local function load_parinfer(lib_path)
  if (nil == lib_path) then
    return vim.notify("Could not load parinfer library", vim.log.levels.ERROR)
  else
    ffi.cdef("char *run_parinfer(const char *json);")
    local ns = ffi.load(lib_path)
    return {interface = ns, run = runner(ns)}
  end
end
local function parinfer_rust_loaded_3f()
  return (0 < #get_runtime_file("target/release/*parinfer_rust.*", true))
end
local function setup()
  if ((0 == vim.fn.exists("g:parinfer_dont_load_rust")) and not parinfer_rust_loaded_3f()) then
    vim.cmd("packadd! parinfer-rust")
  else
  end
  return load_parinfer(load_lib())
end
return setup()
