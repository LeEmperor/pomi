open! Core

(* A 3x5 pixel font. Each pixel is drawn two cells wide so the glyphs come out roughly
   square in a typical terminal. *)
let glyph = function
  | '0' -> [ "###"; "# #"; "# #"; "# #"; "###" ]
  | '1' -> [ " # "; "## "; " # "; " # "; "###" ]
  | '2' -> [ "###"; "  #"; "###"; "#  "; "###" ]
  | '3' -> [ "###"; "  #"; "###"; "  #"; "###" ]
  | '4' -> [ "# #"; "# #"; "###"; "  #"; "  #" ]
  | '5' -> [ "###"; "#  "; "###"; "  #"; "###" ]
  | '6' -> [ "###"; "#  "; "###"; "# #"; "###" ]
  | '7' -> [ "###"; "  #"; "  #"; "  #"; "  #" ]
  | '8' -> [ "###"; "# #"; "###"; "# #"; "###" ]
  | '9' -> [ "###"; "# #"; "###"; "  #"; "###" ]
  | ':' -> [ " "; "#"; " "; "#"; " " ]
  | _ -> [ " "; " "; " "; " "; " " ]
;;

let height = 5

let render_row row =
  String.concat_map row ~f:(function
    | '#' -> "██"
    | _ -> "  ")
;;

let lines s =
  let glyphs = String.to_list s |> List.map ~f:glyph in
  List.init height ~f:(fun i ->
    List.map glyphs ~f:(fun g -> render_row (List.nth_exn g i)) |> String.concat ~sep:" ")
;;
