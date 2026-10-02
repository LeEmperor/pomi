# pomi

A little pomodoro timer for the terminal, built on `bonsai_term`. Started from
`jane/bonsai_term_examples/pomodoro_timer`.

    dune build
    dune exec ./bin/pomi.exe                  # 25 / 5 / 15, long break every 4
    dune exec ./bin/pomi.exe -- -work 50 -short-break 10 -auto-start
    dune exec ./bin/pomi.exe -- -completed 3          # pick up a streak from another run
    dune runtest

Keys: `space`/`enter` start & pause, `r` reset, `n` skip, `+`/`-` (or up/down) add or
remove a minute, `q`/`esc`/`ctrl-c` quit.

Layout: `src/timer.ml` is the pure state machine, `src/app.ml` is the bonsai view,
keybindings, bell and window title, `src/big_digits.ml` is the block font.
