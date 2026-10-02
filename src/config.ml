open! Core

type t =
  { work : Time_ns.Span.t
  ; short_break : Time_ns.Span.t
  ; long_break : Time_ns.Span.t
  ; long_break_every : int (** A long break follows every [n]th completed work session *)
  ; auto_start : bool (** Start the next phase as soon as the current one finishes *)
  ; bell : bool (** Ring the terminal bell when a phase finishes *)
  ; set_title : bool (** Mirror the countdown in the terminal window title *)
  ; completed : int
  (** Work sessions already finished, e.g. carried over from another run *)
  }
[@@deriving sexp_of]

let default =
  { work = Time_ns.Span.of_min 25.
  ; short_break = Time_ns.Span.of_min 5.
  ; long_break = Time_ns.Span.of_min 15.
  ; long_break_every = 4
  ; auto_start = false
  ; bell = true
  ; set_title = true
  ; completed = 0
  }
;;

let param =
  let open Command.Let_syntax in
  let%map_open work =
    flag
      "work"
      (optional_with_default 25. float)
      ~doc:"MIN length of a work session (default 25)"
  and short_break =
    flag
      "short-break"
      (optional_with_default 5. float)
      ~doc:"MIN length of a short break (default 5)"
  and long_break =
    flag
      "long-break"
      (optional_with_default 15. float)
      ~doc:"MIN length of a long break (default 15)"
  and long_break_every =
    flag
      "long-break-every"
      (optional_with_default 4 int)
      ~doc:"N take a long break after every N work sessions (default 4)"
  and auto_start =
    flag "auto-start" no_arg ~doc:" start the next phase automatically when one finishes"
  and no_bell = flag "no-bell" no_arg ~doc:" don't ring the terminal bell"
  and no_title = flag "no-title" no_arg ~doc:" don't touch the terminal window title"
  and completed =
    flag
      "completed"
      (optional_with_default 0 int)
      ~doc:"N start with N work sessions already done, to keep a streak going (default 0)"
  in
  let minutes name m =
    if Float.(m <= 0.)
    then raise_s [%message "duration must be positive" name (m : float)];
    Time_ns.Span.of_min m
  in
  if long_break_every < 1 then raise_s [%message "-long-break-every must be >= 1"];
  if completed < 0 then raise_s [%message "-completed must be >= 0"];
  { work = minutes "-work" work
  ; short_break = minutes "-short-break" short_break
  ; long_break = minutes "-long-break" long_break
  ; long_break_every
  ; auto_start
  ; bell = not no_bell
  ; set_title = not no_title
  ; completed
  }
;;
