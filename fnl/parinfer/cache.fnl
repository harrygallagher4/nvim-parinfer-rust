(local stat vim.loop.fs_stat)
(local {: path-concat} (require :parinfer.util))
(local {: libparinfer} (require :parinfer.lib))

(local cache-path (vim.fn.stdpath :cache))
(local parinfer-path (path-concat cache-path :parinfer-rust))
(local target-path (path-concat parinfer-path :target :release libparinfer))

(fn exists? [filename]
  (let [(f? err) (stat filename)]
    (or (and f? f?.type) false)))
(fn dir?  [filename] (= :directory (exists? filename)))
(fn file? [filename] (= :file (exists? filename)))

(fn repo-exists? [] (dir? parinfer-path))
(fn installed? [] (file? target-path))


{: cache-path
 : parinfer-path
 : target-path
 : repo-exists?
 : installed?}

