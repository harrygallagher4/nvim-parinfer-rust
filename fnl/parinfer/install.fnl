(local uv vim.loop)
(local {:extend-keep extend
        : path-concat} (require :parinfer.util))

(local {: cache-path
        : parinfer-path
        : target-path
        : repo-exists?
        : installed?} (require :parinfer.cache))

(local git-bin (vim.fn.exepath :git))
(local cargo-bin (vim.fn.exepath :cargo))

(fn missing-bins? []
  (if (not git-bin) "git"
      (not cargo-bin) "cargo"
      nil))

(fn runner [path options]
  (fn [done err]
    (var (process status) (values nil nil))
    (fn exit-handler [code signal]
      (let [callback (if (= 0 (+ code signal)) done err)
            res {: process : status : code : signal}]
        (when callback (callback res))))
    (set (process status)
         (uv.spawn path
                   (extend options {:hide true})
                   exit-handler))
    {: process : status}))

(local clone!
  (runner git-bin {:args [:clone
                          :--depth=1
                          :https://github.com/eraserhd/parinfer-rust
                          parinfer-path]
                   :cwd cache-path}))

(local pull!
  (runner git-bin {:args [:pull]
                   :cwd parinfer-path}))

(local build!
  (runner cargo-bin {:args [:build :--release]
                     :cwd parinfer-path}))

(local notify
  (vim.schedule_wrap
    (fn [message ?level]
      (vim.notify message (or ?level vim.log.levels.INFO)))))

(fn on-lib-ready []
  (notify "Parinfer library is ready"))

(fn err-fn [step]
  (fn [{: code}]
    (let [base "Error %s parinfer library!"
          message (if (= nil code) base (.. base " (%d)"))]
      (notify (string.format message step code)
              vim.log.levels.ERROR))))

(fn clone-and-build []
  (clone! #(build! on-lib-ready (err-fn :building))
          (err-fn :cloning)))

(fn read-ref [fh]
  (string.match (fh:read) "^%x+"))

(fn open-git [fname]
  (io.open (path-concat parinfer-path :.git fname)))

;; `updated?` is true by default here so that the library gets built even
;; if there's an error reading the git files
(fn post-pull []
  (var updated? true)
  (with-open [oh (open-git :ORIG_HEAD) fh (open-git :FETCH_HEAD)]
    (set updated? (not= (read-ref oh) (read-ref fh))))
  (if updated?
      (build! on-lib-ready (err-fn :rebuilding))
      (not (installed?))
      (build! on-lib-ready (err-fn :building))
      (installed?)
      (notify "Parinfer is already up to date")))

(fn update-rebuild []
  (pull! post-pull (err-fn :updating)))

(fn install []
  (match [(repo-exists?) (missing-bins?)]
    [true] (vim.notify "Parinfer is already installed" vim.log.levels.WARN)
    [_ bin] (vim.notify
              (string.format
                "Error installing parinfer: could not locate `%s`"
                bin)
              vim.log.levels.WARN)
    _ (clone-and-build)))

(fn update []
  (if (not (repo-exists?))
      (vim.notify "Parinfer is not installed" vim.log.levels.WARN)
      (update-rebuild)))


{: install
 : update}

;; vim: cc=81
