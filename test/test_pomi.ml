open! Core
open Bonsai_test

let config = { Pomi.Config.default with work = Time_ns.Span.of_min 2.; set_title = false }

let create
  ?(config = config)
  ?(dimensions = { Bonsai_term.Dimensions.width = 70; height = 22 })
  ()
  =
  let handle =
    Bonsai_term_test.create_handle (fun ~dimensions graph ->
      Pomi.App.app
        ~config
        ~exit:(fun { completed; focused } ->
          Bonsai.Effect.of_thunk (fun () ->
            print_s [%message "exit" (completed : int) (focused : Time_ns.Span.t)]))
        ~dimensions
        graph)
  in
  Bonsai_term_test.set_dimensions handle dimensions;
  Handle.recompute_view handle;
  handle
;;

let key handle c =
  Bonsai_term_test.send_event handle (Key_press { key = ASCII c; mods = [] });
  Handle.recompute_view handle
;;

let advance handle seconds =
  Handle.advance_clock_by handle (Time_ns.Span.of_sec seconds);
  Handle.recompute_view handle;
  Handle.recompute_view handle
;;

let%expect_test "initial screen" =
  let handle = create () in
  Handle.show handle;
  [%expect
    {|
    ┌──────────────────────────────────────────────────────────────────────┐
    │                                                                      │
    │                ╭ pomi ──────────────────────────────╮                │
    │                │                                    │                │
    │                │       Focus  ·  press space        │                │
    │                │                                    │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │   ██  ██     ██ ██ ██  ██ ██  ██   │                │
    │                │   ██  ██ ██████    ██  ██ ██  ██   │                │
    │                │   ██  ██ ██     ██ ██  ██ ██  ██   │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │                                    │                │
    │                │   ──────────────────────────────   │                │
    │                │                                    │                │
    │                │              ○ ○ ○ ○               │                │
    │                │                                    │                │
    │                ╰────────────────────────────────────╯                │
    │                                                                      │
    │                       0 pomodoros · 0m focused                       │
    │               space start/pause  ·  r reset  ·  n skip               │
    │                         +/- 1 min  ·  q quit                         │
    │                                                                      │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘
    |}]
;;

let%expect_test "running, pausing, adjusting" =
  let handle = create () in
  key handle ' ';
  advance handle 30.;
  Handle.show handle;
  [%expect
    {|
    ┌──────────────────────────────────────────────────────────────────────┐
    │                                                                      │
    │                ╭ pomi ──────────────────────────────╮                │
    │                │                                    │                │
    │                │               Focus                │                │
    │                │                                    │                │
    │                │   ██████   ██      ██████ ██████   │                │
    │                │   ██  ██ ████   ██     ██ ██  ██   │                │
    │                │   ██  ██   ██      ██████ ██  ██   │                │
    │                │   ██  ██   ██   ██     ██ ██  ██   │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │                                    │                │
    │                │   ━━━━━━━━──────────────────────   │                │
    │                │                                    │                │
    │                │              ○ ○ ○ ○               │                │
    │                │                                    │                │
    │                ╰────────────────────────────────────╯                │
    │                                                                      │
    │                       0 pomodoros · 0m focused                       │
    │               space start/pause  ·  r reset  ·  n skip               │
    │                         +/- 1 min  ·  q quit                         │
    │                                                                      │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘
    |}];
  key handle ' ';
  key handle '+';
  advance handle 30.;
  Handle.show handle;
  [%expect
    {|
    ┌──────────────────────────────────────────────────────────────────────┐
    │                                                                      │
    │                ╭ pomi ──────────────────────────────╮                │
    │                │                                    │                │
    │                │          Focus  ·  paused          │                │
    │                │                                    │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │   ██  ██     ██ ██     ██ ██  ██   │                │
    │                │   ██  ██ ██████    ██████ ██  ██   │                │
    │                │   ██  ██ ██     ██     ██ ██  ██   │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │                                    │                │
    │                │   ━━━━━─────────────────────────   │                │
    │                │                                    │                │
    │                │              ○ ○ ○ ○               │                │
    │                │                                    │                │
    │                ╰────────────────────────────────────╯                │
    │                                                                      │
    │                       0 pomodoros · 0m focused                       │
    │               space start/pause  ·  r reset  ·  n skip               │
    │                         +/- 1 min  ·  q quit                         │
    │                                                                      │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘
    |}]
;;

let%expect_test "finishing a work session rings the bell and moves to a break" =
  let handle = create () in
  key handle ' ';
  advance handle 121.;
  Handle.show handle;
  [%expect
    {|
    ([write_string_to_tty] (string "\007"))
    ┌──────────────────────────────────────────────────────────────────────┐
    │                                                                      │
    │                ╭ pomi ──────────────────────────────╮                │
    │                │                                    │                │
    │                │    Short break  ·  press space     │                │
    │                │                                    │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │   ██  ██ ██     ██ ██  ██ ██  ██   │                │
    │                │   ██  ██ ██████    ██  ██ ██  ██   │                │
    │                │   ██  ██     ██ ██ ██  ██ ██  ██   │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │                                    │                │
    │                │   ──────────────────────────────   │                │
    │                │                                    │                │
    │                │              ● ○ ○ ○               │                │
    │                │                                    │                │
    │                ╰────────────────────────────────────╯                │
    │                                                                      │
    │                       1 pomodoro · 2m focused                        │
    │               space start/pause  ·  r reset  ·  n skip               │
    │                         +/- 1 min  ·  q quit                         │
    │                                                                      │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘
    |}];
  key handle 'q';
  [%expect {|
    (exit
      (completed 1)
      (focused   2m))
    |}]
;;

let%expect_test "small terminal falls back to compact clock" =
  let handle = create ~dimensions:{ width = 60; height = 14 } () in
  Handle.show handle;
  [%expect
    {|
    ┌────────────────────────────────────────────────────────────┐
    │           ╭ pomi ──────────────────────────────╮           │
    │           │                                    │           │
    │           │       Focus  ·  press space        │           │
    │           │                                    │           │
    │           │               02:00                │           │
    │           │                                    │           │
    │           │   ──────────────────────────────   │           │
    │           │                                    │           │
    │           │              ○ ○ ○ ○               │           │
    │           │                                    │           │
    │           ╰────────────────────────────────────╯           │
    │                                                            │
    │                  0 pomodoros · 0m focused                  │
    │          space start/pause  ·  r reset  ·  n skip          │
    └────────────────────────────────────────────────────────────┘
    |}]
;;

let%expect_test "long break after every n sessions" =
  let config = Pomi.Config.default in
  let now = Time_ns.epoch in
  let phases =
    List.folding_map (List.range 0 8) ~init:(Pomi.Timer.initial config) ~f:(fun t _ ->
      let t = Pomi.Timer.apply config t (Toggle now) in
      let t = Pomi.Timer.apply config t (Tick (Time_ns.add now t.length)) in
      t, t.phase)
  in
  print_s [%sexp (phases : Pomi.Timer.Phase.t list)];
  [%expect {| (Short_break Work Short_break Work Short_break Work Long_break Work) |}]
;;

let%expect_test "starting between clock ticks doesn't flash an extra second" =
  let handle = create ~dimensions:{ width = 60; height = 14 } () in
  advance handle 0.1;
  key handle ' ';
  Handle.show handle;
  [%expect
    {|
    ┌────────────────────────────────────────────────────────────┐
    │           ╭ pomi ──────────────────────────────╮           │
    │           │                                    │           │
    │           │               Focus                │           │
    │           │                                    │           │
    │           │               02:00                │           │
    │           │                                    │           │
    │           │   ──────────────────────────────   │           │
    │           │                                    │           │
    │           │              ○ ○ ○ ○               │           │
    │           │                                    │           │
    │           ╰────────────────────────────────────╯           │
    │                                                            │
    │                  0 pomodoros · 0m focused                  │
    │          space start/pause  ·  r reset  ·  n skip          │
    └────────────────────────────────────────────────────────────┘
    |}]
;;

let%expect_test "-completed carries a streak over" =
  let handle = create ~config:{ config with completed = 3 } () in
  Handle.show handle;
  [%expect
    {|
    ┌──────────────────────────────────────────────────────────────────────┐
    │                                                                      │
    │                ╭ pomi ──────────────────────────────╮                │
    │                │                                    │                │
    │                │       Focus  ·  press space        │                │
    │                │                                    │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │   ██  ██     ██ ██ ██  ██ ██  ██   │                │
    │                │   ██  ██ ██████    ██  ██ ██  ██   │                │
    │                │   ██  ██ ██     ██ ██  ██ ██  ██   │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │                                    │                │
    │                │   ──────────────────────────────   │                │
    │                │                                    │                │
    │                │              ● ● ● ○               │                │
    │                │                                    │                │
    │                ╰────────────────────────────────────╯                │
    │                                                                      │
    │                       3 pomodoros · 6m focused                       │
    │               space start/pause  ·  r reset  ·  n skip               │
    │                         +/- 1 min  ·  q quit                         │
    │                                                                      │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘
    |}];
  key handle ' ';
  advance handle 121.;
  Handle.show handle;
  [%expect
    {|
    ([write_string_to_tty] (string "\007"))
    ┌──────────────────────────────────────────────────────────────────────┐
    │                                                                      │
    │                ╭ pomi ──────────────────────────────╮                │
    │                │                                    │                │
    │                │     Long break  ·  press space     │                │
    │                │                                    │                │
    │                │     ██   ██████    ██████ ██████   │                │
    │                │   ████   ██     ██ ██  ██ ██  ██   │                │
    │                │     ██   ██████    ██  ██ ██  ██   │                │
    │                │     ██       ██ ██ ██  ██ ██  ██   │                │
    │                │   ██████ ██████    ██████ ██████   │                │
    │                │                                    │                │
    │                │   ──────────────────────────────   │                │
    │                │                                    │                │
    │                │              ● ● ● ●               │                │
    │                │                                    │                │
    │                ╰────────────────────────────────────╯                │
    │                                                                      │
    │                       4 pomodoros · 8m focused                       │
    │               space start/pause  ·  r reset  ·  n skip               │
    │                         +/- 1 min  ·  q quit                         │
    │                                                                      │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘
    |}]
;;
