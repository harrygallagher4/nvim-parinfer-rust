(local (t/ins) (values table.insert))
(local (tbl_extend) (values vim.tbl_extend))

(fn sriapi-it-* [t i]
  (set-forcibly! i (- i 1))
  (when (not= 0 i)
    (values i (. t i))))

(fn sriapi-it- [t i]
  (when (not= 1 i)
    (values (- i 1) (. t (- i 1)))))

(fn sriapi [t]
  (values sriapi-it-* t (+ 1 (length t))))

(fn merge-arg [...]
  (local tbl [])
  (for [i 1 (select "#" ...)]
    (let [v (select i ...)]
      (when (not= nil v) (t/ins tbl v))))
  tbl)

(fn merge-left [...]
  (let [args (merge-arg ...)]
    (if (= 1 (length args))
      (. args 1)
      (tbl_extend "keep" (unpack args)))))

(fn merge-right [...]
  (let [args (merge-arg ...)]
    (if (= 1 (length args))
      (. args 1)
      (tbl_extend "force" (unpack args)))))


{: merge-left : merge-right
 : sriapi :reverse-ipairs sriapi
 :merge merge-right
 :lmerge merge-left
 :rmerge merge-right}

