open! Core

module Phase : sig
  type t =
    | Work
    | Short_break
    | Long_break
  [@@deriving sexp_of, equal]

  val name : t -> string
  val duration : Config.t -> t -> Time_ns.Span.t
end

module Status : sig
  type t =
    | Ready
    | Running of { ends_at : Time_ns.t }
    | Paused
  [@@deriving sexp_of, equal]
end

type t =
  { phase : Phase.t
  ; status : Status.t
  ; length : Time_ns.Span.t (** Full length of the current phase, including adjustments *)
  ; remaining : Time_ns.Span.t
  (** Time left while not [Running]; while [Running], time left when it started *)
  ; completed : int (** Work sessions finished (not skipped) *)
  ; focused : Time_ns.Span.t (** Total time spent in finished work sessions *)
  ; finished_phases : int (** Bumped whenever a phase runs out; drives the bell *)
  }
[@@deriving sexp_of, equal]

val initial : Config.t -> t
val remaining : t -> now:Time_ns.t -> Time_ns.Span.t

(** Fraction of the current phase that has elapsed, in [0, 1]. *)
val progress : t -> now:Time_ns.t -> float

(** How many dots to fill in the "sessions until long break" indicator. *)
val cycle_position : Config.t -> t -> int

module Action : sig
  type t =
    | Toggle of Time_ns.t
    | Reset
    | Skip of Time_ns.t
    | Adjust of
        { by : Time_ns.Span.t
        ; now : Time_ns.t
        }
    | Tick of Time_ns.t
  [@@deriving sexp_of]
end

val apply : Config.t -> t -> Action.t -> t
