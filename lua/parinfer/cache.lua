local stat = vim.loop.fs_stat
local _local_1_ = require("parinfer.util")
local path_concat = _local_1_["path-concat"]
local _local_2_ = require("parinfer.lib")
local libparinfer = _local_2_["libparinfer"]
local cache_path = vim.fn.stdpath("cache")
local parinfer_path = path_concat(cache_path, "parinfer-rust")
local target_path = path_concat(parinfer_path, "target", "release", libparinfer)
local function exists_3f(filename)
  local f_3f, err = stat(filename)
  return ((f_3f and f_3f.type) or false)
end
local function dir_3f(filename)
  return ("directory" == exists_3f(filename))
end
local function file_3f(filename)
  return ("file" == exists_3f(filename))
end
local function repo_exists_3f()
  return dir_3f(parinfer_path)
end
local function installed_3f()
  return file_3f(target_path)
end
return {["cache-path"] = cache_path, ["parinfer-path"] = parinfer_path, ["target-path"] = target_path, ["repo-exists?"] = repo_exists_3f, ["installed?"] = installed_3f}
