# pomi

A little Pomodoro timer for the terminal, built with OCaml and
[Bonsai Term](https://github.com/janestreet/bonsai_term).

<img width="2494" height="1380" alt="image" src="https://github.com/user-attachments/assets/c921bf34-e189-4d7b-99c7-3ed6431839bf" />

Big block digits, a progress bar, and keyboard controls for keeping a focus
session moving.

<!-- Add the real focus screenshot here once captured; see docs/SCREENSHOTS.md. -->

- 25-minute focus sessions, 5-minute short breaks, and a 15-minute long break
  after every four completed sessions, all configurable.
- Start, pause, reset, skip, or adjust the current timer from the keyboard.
- Phase colors, cycle dots, completed-session totals, and a compact clock for
  smaller terminals.
- Optional terminal bell, countdown in the window title, and automatic starts
  for subsequent phases.

## Build and run

pomi currently targets **OxCaml**, using the `ocaml-variants.5.2.0+ox` compiler
and Jane Street's `v0.18~preview.130.106+341` libraries. It has not been tested
against stock OCaml or the stable v0.17 libraries.

The verified local environment is Linux, with that compiler and library set,
and Dune 3.24.2. The project requires Dune 3.17 or newer.

With opam installed, the setup commands for the declared dependencies are:

```sh
git clone https://github.com/LeEmperor/pomi.git
cd pomi
opam repository add ox git+https://github.com/oxcaml/opam-repository.git
opam switch create . ocaml-variants.5.2.0+ox
eval $(opam env)
opam install . --deps-only --with-test
dune build
dune exec pomi
```

If you already have a compatible switch, use it and start at the dependency
installation step. The manifest pins direct Jane Street dependencies to the
versions used locally; a fresh-switch installation has not yet been verified.
Building OxCaml and its dependencies can take a while.

To install the command into your active opam switch:

```sh
opam install .
pomi
```

Use a terminal with Unicode and true-color support. A window of 70 columns by
24 rows is a comfortable starting point; shorter windows use the compact clock.
Very small windows can clip the interface and keyboard hints.

## Controls

| Key | Action |
| --- | --- |
| `Space` / `Enter` | Start, pause, or resume |
| `r` | Reset the current phase to its configured duration |
| `n` / `s` | Skip to the next phase, ready to start |
| `+` / `↑` | Add a minute to the current phase |
| `-` / `↓` | Remove a minute, if at least one minute would remain |
| `q` / `Esc` / `Ctrl-C` | Quit |

## Customize a session

Pass options after `--` when running through Dune:

```sh
# Longer focus sessions and short breaks; subsequent phases start automatically.
dune exec pomi -- -work 50 -short-break 10 -auto-start

# A 20-minute long break after every three completed focus sessions.
dune exec pomi -- -long-break 20 -long-break-every 3

# Carry three completed sessions into this run.
dune exec pomi -- -completed 3

# Disable the bell and window-title updates.
dune exec pomi -- -no-bell -no-title

# List all options.
dune exec pomi -- -help
```

Durations are in minutes and must be positive. `-auto-start` applies when a
timer finishes; press `Space` to start the first session. Skipping a phase always
leaves the next one waiting to start and does not count as completing a session.

Session totals live in memory and are not saved on exit. `-completed N` seeds
the completed-session count and estimates prior focus time as `N ×` the
configured work duration. Focus time counts completed work sessions, including
timer adjustments, rather than every minute spent with a timer running.

## Development

```sh
dune build @all
dune runtest
```

Tests cover timer transitions and terminal views, including pausing,
adjustments, long breaks, carried-over sessions, and compact rendering.

| File | Responsibility |
| --- | --- |
| [`src/timer.ml`](src/timer.ml) | Pure timer state machine |
| [`src/app.ml`](src/app.ml) | Bonsai view, keyboard events, bell, and window title |
| [`src/config.ml`](src/config.ml) | Defaults and command-line options |
| [`src/big_digits.ml`](src/big_digits.ml) | Block-digit font |
| [`test/test_pomi.ml`](test/test_pomi.ml) | Expect tests for behavior and rendering |

For consistent README captures, see the [screenshot guide](docs/SCREENSHOTS.md).

## Acknowledgments

pomi started from the `bonsai_term_examples/pomodoro_timer` example in the
author's local `jane` workspace. Its terminal interface uses Jane Street's
Bonsai Term and the Bonsai Term border-box and color-scheme components.
