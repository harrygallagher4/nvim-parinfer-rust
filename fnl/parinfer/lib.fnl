(local ffi (require :ffi))
(local ffi-string ffi.string)
(local {:encode json-encode :decode json-decode} vim.json)

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
  (let [[lib-path] (resolve-lib)] lib-path))

(fn load-parinfer [lib-path]
  (if (= nil lib-path) (vim.notify "Could not load parinfer library" vim.log.levels.ERROR)
    (do (ffi.cdef "char *run_parinfer(const char *json);")
        (let [ns (ffi.load lib-path)]
          {:interface ns :run (runner ns)}))))

(fn parinfer-rust-loaded? []
  (< 0 (length (vim.api.nvim_get_runtime_file "target/release/*parinfer_rust.*" true))))

; packadd! parinfer-rust will add the plugin to runtimepath without
; sourcing plugin/parinfer.vim. this way the library can still be
; located but parinfer.vim won't interfere
(fn setup []
  (when (and (= 0 (vim.fn.exists "g:parinfer_dont_load_rust"))
             (not (parinfer-rust-loaded?)))
    (vim.cmd "packadd! parinfer-rust"))
  (-> (load-lib) (load-parinfer)))

(setup)

