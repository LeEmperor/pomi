open! Core
open Bonsai_term

(** What gets handed back when the app exits. *)
module Summary : sig
  type t =
    { completed : int
    ; focused : Time_ns.Span.t
    }
end

val app
  :  config:Config.t
  -> exit:(Summary.t -> unit Effect.t)
  -> dimensions:Dimensions.t Bonsai.t
  -> local_ Bonsai.graph
  -> view:View.t Bonsai.t * handler:(Event.t -> unit Effect.t) Bonsai.t

val command : Command.t
