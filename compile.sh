#!/usr/bin/env zsh

sources=(fnl/parinfer/*.fnl)

for f in ${sources/*macros*}; do
  fennel \
    --lua "${${:-luajit}:c:P}" \
    --add-macro-path "fnl/parinfer/macros.fnl" \
    --compile "${f}" \
    > "${(*)f//((#s)fnl|fnl(#e))/lua}"
done

