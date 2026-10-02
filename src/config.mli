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

(** 25 / 5 / 15 minutes, long break every 4, bell and title on, no auto-start. *)
val default : t

val param : t Command.Param.t
