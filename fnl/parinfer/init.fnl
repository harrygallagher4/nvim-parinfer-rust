(local incr-bst (require :parinfer.incremental-change))
(local {:run run-parinfer} (require :parinfer.lib))
(local {: lmerge : rmerge} (require :parinfer.util))

(local buf-apply-diff incr-bst.buf-apply-diff)
(local (t/cat t/ins) (values table.concat table.insert))
(local (json split cmd) (values vim.json vim.split vim.cmd))
(local ns (vim.api.nvim_create_namespace "parinfer"))
(local
  settings
  {:mode "smart"
   :trail_highlight true
   :trail_highlight_group "Whitespace"})

; I've heard that enclosing functions can slightly improve speed due to
; reducing the number of table lookups, but who knows. I figure if
; there's a small performance gain it's worth it since a lot of these
; will be called very often
;
; vim.fn functions
(local expand vim.fn.expand)
(local win_gettype vim.fn.win_gettype)
(local str2nr vim.fn.str2nr)
; api functions
(local create_augroup vim.api.nvim_create_augroup)
(local create_autocmd vim.api.nvim_create_autocmd)
(local del_augroup_by_id vim.api.nvim_del_augroup_by_id)
(local del_autocmd vim.api.nvim_del_autocmd)
(local win_get_cursor vim.api.nvim_win_get_cursor)
(local win_set_cursor vim.api.nvim_win_set_cursor)
(local get_current_buf vim.api.nvim_get_current_buf)
(local buf_get_changedtick vim.api.nvim_buf_get_changedtick)
(local buf_set_lines vim.api.nvim_buf_set_lines)
(local buf_get_lines vim.api.nvim_buf_get_lines)
(local buf_add_highlight vim.api.nvim_buf_add_highlight)
(local buf_clear_namespace vim.api.nvim_buf_clear_namespace)

(local process-events [:CursorMoved :InsertEnter :TextChanged :TextChangedI :TextChangedP])
(local cursor-events [:BufEnter :WinEnter])

(local state {:mode settings.mode :augroup nil})


(fn notify-error [buf request response]
  (vim.notify
    (t/cat
      [(.. "[Parinfer] error in buffer " buf)
       (json.encode (or (?. response :error) {}))
       (json.encode request)
       (json.encode (or response {}))]
      "\n")
    vim.log.levels.ERROR))

; creates parinfennel augroup if necessary & stores id in state
(fn ensure-augroup []
  (when (= nil state.augroup)
    (tset state :augroup (create_augroup "parinfennel" {:clear true}))))

; deletes parinfennel augroup if it exists
(fn del-augroup []
  (when (not= nil state.augroup)
    (del_augroup_by_id state.augroup)
    (tset state :augroup nil)))

; creates an autocmd in `parinfennel` group
(fn autocmd [events opts]
  (create_autocmd events (lmerge opts {:group "parinfennel"})))

; shorthand for attaching a callback to a buffer
(fn buf-autocmd [buf events func]
  (t/ins
    (. state buf :autocmds)
    (autocmd events {:callback func :buffer buf})))

; expands autocmd buffer argument and converts to a number
(fn abuf []
  (str2nr (expand "<abuf>")))

; highlight 'parenTrails' that are being handled by parinfer
(fn handle-trails [group]
  (fn [buf trails]
    (buf_clear_namespace buf ns 0 -1)
    (when trails
      (each [_ {: startX : endX : lineNo} (ipairs trails)]
        (buf_add_highlight buf ns group lineNo startX endX)))))

; gets cursor position, (0, 0) indexed
(fn get-cursor []
  (let [[row col] (win_get_cursor 0)]
    (values (- row 1) col)))

; sets cursor position, (0, 0) indexed
(fn set-cursor [row col]
  (win_set_cursor 0 [(+ row 1) col]))

; gets entire buffer text as one string
(fn get-buf-content [buf]
  (let [lines (buf_get_lines buf 0 -1 false)]
    (values (t/cat lines "\n") lines)))

; creates a function that refreshes the state of buf's changedtick
(fn refresh-changedtick [buf]
  (let [bufstate (. state buf)]
    #(tset bufstate :changedtick (buf_get_changedtick buf))))

; creates a function that refreshes the state of buf's cursor position
(fn refresh-cursor [buf]
  (let [bufstate (. state buf)]
    #(let [(cl cx) (get-cursor)]
       (tset bufstate :cursorX cx)
       (tset bufstate :cursorLine cl))))

; creates a function that refreshes the state of buf's text & changedtick
(fn refresh-text [buf]
  (let [bufstate (. state buf)]
    #(let [ct (buf_get_changedtick buf)]
       (when (not= ct bufstate.changedtick)
         (tset bufstate :changedtick ct)
         (tset bufstate :text (get-buf-content buf))))))

; creates a function that refreshes the state of
; buf's cursor, text, and changedtick
(fn refresher [buf]
  (let [ref-t (refresh-text buf) ref-c (refresh-cursor buf)]
    #(do (ref-t) (ref-c))))

; make a process-buffer function with enclosed settings
(fn make-processor [buf mode]
  (let [bufstate (. state buf)
        commentChar ";" stringDelimiters ["\""] forceBalance false
        lispVlineSymbols false lispBlockComments false guileBlockComments false
        schemeSexpComments false janetLongStrings false
        refresh-cursor (refresh-cursor buf) refresh-text (refresh-text buf)
        refresh-changedtick (refresh-changedtick buf)
        trails-func (when settings.trail_highlight (handle-trails settings.trail_highlight_group))]

    (fn process []
      (when (not= bufstate.changedtick (buf_get_changedtick buf))
        (let [(cl cx) (get-cursor)
              (original-text original-lines) (get-buf-content buf)
              req {:mode mode
                   :text original-text
                   :options
                   {: commentChar : stringDelimiters : forceBalance
                    : lispVlineSymbols : lispBlockComments : guileBlockComments
                    : schemeSexpComments : janetLongStrings
                    :cursorX cx :cursorLine cl
                    :prevCursorX bufstate.cursorX
                    :prevCursorLine bufstate.cursorLine
                    :prevText bufstate.text}}
              response (run-parinfer req)]
          (if response.success
            (do
              (when (not= response.text original-text)
                (cmd "silent! undojoin")
                (buf-apply-diff buf original-text original-lines response.text (split response.text "\n")))
              (set-cursor response.cursorLine response.cursorX)
              (tset bufstate :text response.text)
              (when (not= nil trails-func) (trails-func buf response.parenTrails)))
            (do
              (notify-error buf req response)
              (tset bufstate :error response.error)
              (refresh-text))))
        (refresh-changedtick))

      (refresh-cursor))))

; initialize buffer state if necessary, process buffer in paren mode
; TODO: handle mode. shouldn't be hard
; all that really needs to be done is set the `process-events` autocmd
; to call `process-{mode}` and also make sure to re-init the buffer
; whenever mode is changed. that's also how settings can be handled
(fn enter-buffer [buf]
  (when (= nil (. state buf))
    (tset state buf {})
    (let [(cl cx) (get-cursor)
          process (make-processor buf "smart")
          process-paren (make-processor buf "paren")]
      (each [k v (pairs {:process process
                         :process-paren process-paren
                         :text (get-buf-content buf)
                         :autocmds []
                         :changedtick -1
                         :cursorX cx :cursorLine cl})]
        (tset state buf k v))
      (buf-autocmd buf process-events process)
      (buf-autocmd buf cursor-events (refresh-cursor buf))
      (buf-autocmd buf :InsertCharPre (refresher buf))))
  ((. state buf :process-paren)))

; initializes a buffer if its window isn't a special type (qflist/etc)
(fn initialize-buffer []
  (when (= "" (win_gettype))
    (enter-buffer (abuf))))

; removes process callbacks associated with buf
(fn detach-buffer [buf]
  (when (?. state buf :autocmds)
    (each [_ v (ipairs (. state buf :autocmds))]
      (del_autocmd v)))
  (buf_clear_namespace buf ns 0 -1)
  (tset state buf nil))

(fn disable-parinfer-rust []
  (when (= 1 (vim.fn.exists "g:parinfer_enabled"))
    (tset vim.g :parinfer_enabled 0)))

; :ParinferSetup as well as the main entry-point of this module
; sets up autocmds to initialize new buffers
(fn setup! [conf]
  (when conf
    (each [k v (pairs (rmerge settings conf))]
      (tset settings k v)))
  (ensure-augroup)
  (autocmd :FileType
    {:pattern ["clojure" "scheme" "lisp" "racket" "hy" "fennel" "janet" "carp" "wast" "yuck" "dune"]
     :callback initialize-buffer}))

; :ParinferCleanup
; delete parinfennel augroup which contains the init callback & all processors
(fn cleanup! []
  (del-augroup))

; :ParinferOn
(fn attach-current-buf! []
  (disable-parinfer-rust)
  (ensure-augroup)
  (let [buf (get_current_buf)]
    (enter-buffer buf)))

; :ParinferOff
(fn detach-current-buf! []
  (let [buf (get_current_buf)]
    (detach-buffer buf)))

; :ParinferRefresh
(fn refresh-current-buf! []
  (let [buf (get_current_buf)]
    (detach-buffer buf)
    (enter-buffer buf)))

; :ParinferTrails
(fn toggle-trails! []
  (tset settings :trail_highlight (not settings.trail_highlight))
  (refresh-current-buf!))

;; if parinfer-rust is active commands should start with :ParinferFnl,
; otherwise they just start with :Parinfer
(fn cmd-str [s]
  (let [prefix
        (if (= 1 (vim.fn.exists "g:parinfer_enabled")) :ParinferFnl :Parinfer)]
    (.. prefix s)))

(fn parinfer-command! [s f opts]
  (vim.api.nvim_add_user_command (cmd-str s) f (or opts {})))

(parinfer-command! :On attach-current-buf!)
(parinfer-command! :Off detach-current-buf!)
(parinfer-command! :Refresh refresh-current-buf!)
(parinfer-command! :Trails toggle-trails!)
(parinfer-command! :Setup setup!)
(parinfer-command! :Cleanup cleanup!)

; should move this somewhere else
(fn toggle-paren-hl []
  (let [hl (vim.api.nvim__get_hl_defs 0)
        fnlP hl.fennelTSPunctBracket.link]
    (when (= fnlP "TSPunctBracket") (vim.cmd "highlight! link fennelTSPunctBracket Whitespace"))
    (when (= fnlP "Whitespace") (vim.cmd "highlight! link fennelTSPunctBracket TSPunctBracket"))))

(vim.api.nvim_add_user_command :Phl toggle-paren-hl {})

{: setup!
 : cleanup!
 : attach-current-buf!
 : detach-current-buf!
 : refresh-current-buf!
 : toggle-trails!
 : toggle-paren-hl
 :setup setup!
 :cleanup cleanup!
 :attach-current-buf attach-current-buf!
 :detach-current-buf detach-current-buf!
 :refresh-current-buf refresh-current-buf!
 :toggle-trails toggle-trails!}

