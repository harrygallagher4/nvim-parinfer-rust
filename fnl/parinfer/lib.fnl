(local ffi (require :ffi))
(local ffi-string ffi.string)
(local {: path-concat} (require :parinfer.util))
(local {:encode json-encode :decode json-decode} vim.json)
(local get_runtime_file vim.api.nvim_get_runtime_file)

(local libparinfer (match ffi.os
                     :OSX :libparinfer_rust.dylib
                     :Windows :parinfer_rust.dll
                     _ :libparinfer_rust.so))


;; Old method of locating the parinfer-rust library
;; ------------------------------------------------
(fn parinfer-rust-loaded? []
  (< 0 (length (get_runtime_file (path-concat :src :parinfer.rs) true))))

(fn resolve-lib-old []
  (. (get_runtime_file (path-concat :target :release libparinfer) false) 1))

(fn try-load-pack []
  (when (and (= 0 (vim.fn.exists "g:parinfer_dont_load_rust"))
             (not (parinfer-rust-loaded?)))
    (vim.cmd "packadd! parinfer-rust")
    (resolve-lib-old)))
;; ------------------------------------------------

(fn resolve-lib-cached []
  (let [{: installed? : target-path} (require :parinfer.cache)]
    (when (installed?) target-path)))

;; Eventually this will be the only variant of `resolve-lib`
;;
;; Searching for the library file itself relies on
;; `parinfer-rust/target/release` rather than just `parinfer-rust/` being in the
;; runtimepath. This also ensures that `plugin/parinfer.vim` isn't loaded
(fn resolve-lib-new []
  (. (get_runtime_file libparinfer false) 1))

(fn resolve-lib []
  (or (resolve-lib-new)
      (try-load-pack)))

(fn runner [parinfer]
  (fn run [request]
    (-> request
        (json-encode)
        (parinfer.run_parinfer)
        (ffi-string)
        (json-decode))))

(fn load-parinfer [lib-path]
  (if (= nil lib-path)
      (vim.notify "Could not find parinfer library" vim.log.levels.ERROR)
      (-> (do (ffi.cdef "char *run_parinfer(const char *json);")
              (ffi.load lib-path))
          (runner))))

(fn load* [?path]
  (load-parinfer (match ?path
                   nil (resolve-lib)
                   :managed (resolve-lib-cached)
                   _ ?path)))


{:load load*
 : load-parinfer
 : libparinfer}

;; vim: cc=81
