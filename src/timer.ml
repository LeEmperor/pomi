open! Core

module Phase = struct
  type t =
    | Work
    | Short_break
    | Long_break
  [@@deriving sexp_of, equal]

  let name = function
    | Work -> "Focus"
    | Short_break -> "Short break"
    | Long_break -> "Long break"
  ;;

  let duration (config : Config.t) = function
    | Work -> config.work
    | Short_break -> config.short_break
    | Long_break -> config.long_break
  ;;
end

module Status = struct
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
  ; remaining : Time_ns.Span.t (** Only meaningful while not [Running] *)
  ; completed : int (** Work sessions finished (not skipped) *)
  ; focused : Time_ns.Span.t (** Total time spent in finished work sessions *)
  ; finished_phases : int (** Bumped whenever a phase runs out; drives the bell *)
  }
[@@deriving sexp_of, equal]

let initial config =
  let length = Phase.duration config Work in
  { phase = Work
  ; status = Ready
  ; length
  ; remaining = length
  ; completed = 0
  ; focused = Time_ns.Span.zero
  ; finished_phases = 0
  }
;;

let remaining t ~now =
  match t.status with
  | Running { ends_at } -> Time_ns.Span.max Time_ns.Span.zero (Time_ns.diff ends_at now)
  | Ready | Paused -> t.remaining
;;

let progress t ~now =
  let length = Time_ns.Span.to_sec t.length in
  if Float.(length <= 0.)
  then 1.
  else
    Float.clamp_exn
      (1. -. (Time_ns.Span.to_sec (remaining t ~now) /. length))
      ~min:0.
      ~max:1.
;;

(** Work sessions finished in the current cycle, counting up to [long_break_every]. *)
let cycle_position (config : Config.t) t =
  match t.phase, t.completed with
  | Long_break, n when n > 0 -> config.long_break_every
  | _, n -> n % config.long_break_every
;;

let start_phase (config : Config.t) t phase ~now =
  let length = Phase.duration config phase in
  let status : Status.t =
    if config.auto_start then Running { ends_at = Time_ns.add now length } else Ready
  in
  { t with phase; status; length; remaining = length }
;;

let after_work (config : Config.t) ~completed : Phase.t =
  if completed > 0 && completed % config.long_break_every = 0
  then Long_break
  else Short_break
;;

module Action = struct
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

let apply (config : Config.t) t (action : Action.t) =
  match action with
  | Toggle now ->
    (match t.status with
     | Ready | Paused ->
       { t with status = Running { ends_at = Time_ns.add now t.remaining } }
     | Running _ -> { t with status = Paused; remaining = remaining t ~now })
  | Reset ->
    { t with
      status = Ready
    ; length = Phase.duration config t.phase
    ; remaining = Phase.duration config t.phase
    }
  | Skip now ->
    (* Skipping never counts as finishing a session. *)
    let next : Phase.t =
      match t.phase with
      | Work -> after_work config ~completed:(t.completed + 1)
      | Short_break | Long_break -> Work
    in
    start_phase { config with auto_start = false } t next ~now
  | Adjust { by; now } ->
    let current = remaining t ~now in
    let updated = Time_ns.Span.(current + by) in
    if Time_ns.Span.(updated < of_min 1.) && Time_ns.Span.(by < zero)
    then t
    else (
      let length = Time_ns.Span.(t.length + by) in
      match t.status with
      | Running { ends_at } ->
        { t with length; status = Running { ends_at = Time_ns.add ends_at by } }
      | Ready | Paused -> { t with length; remaining = updated })
  | Tick now ->
    (match t.status with
     | Ready | Paused -> t
     | Running _ when Time_ns.Span.(remaining t ~now > zero) -> t
     | Running _ ->
       let t = { t with finished_phases = t.finished_phases + 1 } in
       (match t.phase with
        | Work ->
          let completed = t.completed + 1 in
          let t = { t with completed; focused = Time_ns.Span.(t.focused + t.length) } in
          start_phase config t (after_work config ~completed) ~now
        | Short_break | Long_break -> start_phase config t Work ~now))
;;
