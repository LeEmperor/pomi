open! Core

(** Renders digits and [:] in a chunky 5-line block font. Other characters render as blank
    space. *)
val lines : string -> string list
