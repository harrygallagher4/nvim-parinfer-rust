(local ffi (require :ffi))
(local ffi-string ffi.string)
(local {:encode json-encode :decode json-decode} vim.json)

(local state {})
(var parinfer nil)

(fn resolve-lib []
  (let [libname
        (match ffi.os
          "OSX" "libparinfer_rust.dylib"
          "Windows" "parinfer_rust.dll"
          _ "libparinfer_rust.so")]
    (vim.api.nvim_get_runtime_file (.. "target/release/" libname) false)))

(fn runner [parinfer]
  (fn run [request]
    (-> request
        (json-encode)
        (parinfer.run_parinfer)
        (ffi-string)
        (json-decode))))

(fn load-lib []
  (let [[lib-path] (resolve-lib)]
    (when (= nil lib-path)
      (vim.notify "Could not locate parinfer library" vim.log.levels.ERROR))
    (tset state :lib-path lib-path)))

(fn load-parinfer []
  (if (= nil state.lib-path) (print "Cannot load parinfer")
    (do
      (ffi.cdef "char *run_parinfer(const char *json);")
      (let [ns (ffi.load state.lib-path)]
        (set parinfer ns)
        (tset state :interface ns)
        (tset state :run (runner ns))
        state))))

(fn parinfer-rust-loaded? []
  (< 0 (length (vim.api.nvim_get_runtime_file "target/release/*parinfer_rust.*" true))))

; packadd! parinfer-rust will add the plugin to runtimepath without
; sourcing plugin/parinfer.vim. this way the library can still be
; located but parinfer.vim won't interfere
(fn setup []
  (when (and (= 0 (vim.fn.exists "g:parinfer_dont_load_rust"))
             (not (parinfer-rust-loaded?)))
    (vim.cmd "packadd! parinfer-rust"))
  (load-lib)
  (load-parinfer))

(setup)

