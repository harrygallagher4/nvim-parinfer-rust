local uv = vim.loop
local _local_1_ = require("parinfer.util")
local extend = _local_1_["extend-keep"]
local path_concat = _local_1_["path-concat"]
local _local_2_ = require("parinfer.cache")
local cache_path = _local_2_["cache-path"]
local parinfer_path = _local_2_["parinfer-path"]
local target_path = _local_2_["target-path"]
local repo_exists_3f = _local_2_["repo-exists?"]
local installed_3f = _local_2_["installed?"]
local git_bin = vim.fn.exepath("git")
local cargo_bin = vim.fn.exepath("cargo")
local function missing_bins_3f()
  if not git_bin then
    return "git"
  elseif not cargo_bin then
    return "cargo"
  else
    return nil
  end
end
local function runner(path, options)
  local function _4_(done, err)
    local process, status = nil, nil
    local function exit_handler(code, signal)
      local callback
      if (0 == (code + signal)) then
        callback = done
      else
        callback = err
      end
      local res = {process = process, status = status, code = code, signal = signal}
      if callback then
        return callback(res)
      else
        return nil
      end
    end
    process, status = uv.spawn(path, extend(options, {hide = true}), exit_handler)
    return {process = process, status = status}
  end
  return _4_
end
local clone_21 = runner(git_bin, {args = {"clone", "--depth=1", "https://github.com/eraserhd/parinfer-rust", parinfer_path}, cwd = cache_path})
local pull_21 = runner(git_bin, {args = {"pull"}, cwd = parinfer_path})
local build_21 = runner(cargo_bin, {args = {"build", "--release"}, cwd = parinfer_path})
local notify
local function _7_(message, _3flevel)
  return vim.notify(message, (_3flevel or vim.log.levels.INFO))
end
notify = vim.schedule_wrap(_7_)
local function on_lib_ready()
  return notify("Parinfer library is ready")
end
local function err_fn(step)
  local function _10_(_8_)
    local _arg_9_ = _8_
    local code = _arg_9_["code"]
    local base = "Error %s parinfer library!"
    local message
    if (nil == code) then
      message = base
    else
      message = (base .. " (%d)")
    end
    return notify(string.format(message, step, code), vim.log.levels.ERROR)
  end
  return _10_
end
local function clone_and_build()
  local function _12_()
    return build_21(on_lib_ready, err_fn("building"))
  end
  return clone_21(_12_, err_fn("cloning"))
end
local function read_ref(fh)
  return string.match(fh:read(), "^%x+")
end
local function open_git(fname)
  return io.open(path_concat(parinfer_path, ".git", fname))
end
local function post_pull()
  local updated_3f = true
  do
    local oh = open_git("ORIG_HEAD")
    local fh = open_git("FETCH_HEAD")
    local function close_handlers_8_auto(ok_9_auto, ...)
      fh:close()
      oh:close()
      if ok_9_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _14_()
      updated_3f = (read_ref(oh) ~= read_ref(fh))
      return nil
    end
    close_handlers_8_auto(_G.xpcall(_14_, (package.loaded.fennel or debug).traceback))
  end
  if updated_3f then
    return build_21(on_lib_ready, err_fn("rebuilding"))
  elseif not installed_3f() then
    return build_21(on_lib_ready, err_fn("building"))
  elseif installed_3f() then
    return notify("Parinfer is already up to date")
  else
    return nil
  end
end
local function update_rebuild()
  return pull_21(post_pull, err_fn("updating"))
end
local function install()
  local _16_ = {repo_exists_3f(), missing_bins_3f()}
  if ((_G.type(_16_) == "table") and ((_16_)[1] == true)) then
    return vim.notify("Parinfer is already installed", vim.log.levels.WARN)
  elseif ((_G.type(_16_) == "table") and true and (nil ~= (_16_)[2])) then
    local _ = (_16_)[1]
    local bin = (_16_)[2]
    return vim.notify(string.format("Error installing parinfer: could not locate `%s`", bin), vim.log.levels.WARN)
  elseif true then
    local _ = _16_
    return clone_and_build()
  else
    return nil
  end
end
local function update()
  if not repo_exists_3f() then
    return vim.notify("Parinfer is not installed", vim.log.levels.WARN)
  else
    return update_rebuild()
  end
end
return {install = install, update = update}
