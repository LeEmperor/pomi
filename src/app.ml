open! Core
open Bonsai_term
open Bonsai.Let_syntax
module Color = Bonsai_term_color_scheme
module Border_box = Bonsai_term_border_box

module Summary = struct
  type t =
    { completed : int
    ; focused : Time_ns.Span.t
    }

  let of_timer (t : Timer.t) = { completed = t.completed; focused = t.focused }
end

let format_clock span =
  let total = Float.iround_up_exn (Time_ns.Span.to_sec span) in
  sprintf "%02d:%02d" (total / 60) (total % 60)
;;

let format_duration span =
  let minutes = Float.iround_down_exn (Time_ns.Span.to_min span) in
  if minutes >= 60
  then sprintf "%dh %02dm" (minutes / 60) (minutes % 60)
  else sprintf "%dm" minutes
;;

let pluralize n word = sprintf "%d %s%s" n word (if n = 1 then "" else "s")

let window_title (t : Timer.t) ~now =
  let clock = format_clock (Timer.remaining t ~now) in
  match t.status with
  | Running _ -> sprintf "%s %s · pomi" clock (Timer.Phase.name t.phase)
  | Paused -> sprintf "%s %s (paused) · pomi" clock (Timer.Phase.name t.phase)
  | Ready -> "pomi"
;;

let repeat s n = String.concat (List.init (Int.max 0 n) ~f:(fun _ -> s))

(* Centers [view] horizontally in a strip [width] columns wide. *)
let hcenter ~width view = View.center view ~within:{ width; height = View.height view }

module Palette = struct
  type t =
    { accent : Attr.Color.t
    ; text : Attr.Color.t
    ; subtle : Attr.Color.t
    ; faint : Attr.Color.t
    ; bg : Attr.Color.t
    }

  let create ~flavor (phase : Timer.Phase.t) =
    let c = Color.color ~flavor in
    { accent =
        c
          (match phase with
           | Work -> Red
           | Short_break -> Green
           | Long_break -> Blue)
    ; text = Attr.Color.rgb ~r:255 ~g:176 ~b:0
    ; subtle = Attr.Color.rgb ~r:192 ~g:128 ~b:0
    ; faint = Attr.Color.rgb ~r:90 ~g:61 ~b:0
    ; bg = Attr.Color.rgb ~r:0 ~g:0 ~b:0
    }
  ;;
end

let progress_bar (p : Palette.t) ~width ~fraction =
  let filled =
    Float.iround_nearest_exn (fraction *. Float.of_int width)
    |> Int.clamp_exn ~min:0 ~max:width
  in
  View.hcat
    [ View.text ~attrs:[ Attr.fg p.accent ] (repeat "━" filled)
    ; View.text ~attrs:[ Attr.fg p.faint ] (repeat "─" (width - filled))
    ]
;;

let cycle_dots (p : Palette.t) (config : Config.t) t =
  let filled = Timer.cycle_position config t in
  List.init config.long_break_every ~f:(fun i ->
    if i < filled
    then View.text ~attrs:[ Attr.fg p.accent ] "●"
    else View.text ~attrs:[ Attr.fg p.faint ] "○")
  |> List.intersperse ~sep:(View.text " ")
  |> View.hcat
;;

let help (p : Palette.t) =
  let row keys =
    List.map keys ~f:(fun (key, what) ->
      View.hcat
        [ View.text ~attrs:[ Attr.bold; Attr.fg p.subtle ] key
        ; View.text ~attrs:[ Attr.fg p.faint ] (" " ^ what)
        ])
    |> List.intersperse ~sep:(View.text ~attrs:[ Attr.fg p.faint ] "  ·  ")
    |> View.hcat
  in
  [ row [ "space", "start/pause"; "r", "reset"; "n", "skip" ]
  ; row [ "+/-", "1 min"; "q", "quit" ]
  ]
;;

let panel (p : Palette.t) (config : Config.t) (t : Timer.t) ~now ~big =
  let clock = format_clock (Timer.remaining t ~now) in
  let clock_color =
    match t.status with
    | Paused -> p.faint
    | Ready | Running _ -> p.accent
  in
  let clock_view =
    if big
    then
      View.vcat
        (List.map (Big_digits.lines clock) ~f:(View.text ~attrs:[ Attr.fg clock_color ]))
    else View.text ~attrs:[ Attr.bold; Attr.fg clock_color ] clock
  in
  let width = Int.max 30 (View.width clock_view) in
  let header =
    View.hcat
      [ View.text ~attrs:[ Attr.bold; Attr.fg p.accent ] (Timer.Phase.name t.phase)
      ; View.text
          ~attrs:[ Attr.fg p.subtle ]
          (match t.status with
           | Ready -> "  ·  press space"
           | Running _ -> ""
           | Paused -> "  ·  paused")
      ]
  in
  let body =
    View.vcat
      [ hcenter ~width header
      ; View.text ""
      ; hcenter ~width clock_view
      ; View.text ""
      ; progress_bar p ~width ~fraction:(Timer.progress t ~now)
      ; View.text ""
      ; hcenter ~width (cycle_dots p config t)
      ]
  in
  Border_box.view
    ~line_type:Round_corners
    ~title:"pomi"
    ~title_attrs:[ Attr.bold; Attr.fg p.accent ]
    ~attrs:[ Attr.fg p.faint ]
    ~left_padding:3
    ~right_padding:3
    ~top_padding:1
    ~bottom_padding:1
    body
;;

let layout (p : Palette.t) config (t : Timer.t) ~now ~big =
  let stats =
    View.text
      ~attrs:[ Attr.fg p.subtle ]
      (sprintf
         "%s · %s focused"
         (pluralize t.completed "pomodoro")
         (format_duration t.focused))
  in
  let rows = panel p config t ~now ~big :: View.text "" :: stats :: help p in
  let width =
    List.map rows ~f:View.width |> List.max_elt ~compare |> Option.value ~default:0
  in
  View.vcat (List.map rows ~f:(hcenter ~width))
;;

let view ~flavor ~(dimensions : Dimensions.t) ~config ~(model : Timer.t) ~now =
  let p = Palette.create ~flavor model.phase in
  let content =
    let big = layout p config model ~now ~big:true in
    if View.width big <= dimensions.width && View.height big <= dimensions.height
    then big
    else layout p config model ~now ~big:false
  in
  View.zcat
    [ View.center (View.with_colors content ~fg:p.text ~bg:p.bg) ~within:dimensions
    ; View.rectangle
        ~attrs:[ Attr.bg p.bg ]
        ~fill:' '
        ~width:dimensions.width
        ~height:dimensions.height
        ()
    ]
;;

let app ~(config : Config.t) ~exit ~dimensions (local_ graph) =
  let model, inject =
    Bonsai.state_machine
      ~default_model:(Timer.initial config)
      ~apply_action:(fun _ctx model action -> Timer.apply config model action)
      graph
  in
  let tick = Time_ns.Span.of_ms 200. in
  let now = Bonsai.Clock.approx_now ~tick_every:tick graph in
  let get_now = Bonsai.Clock.get_current_time graph in
  Bonsai.Clock.every
    ~when_to_start_next_effect:`Every_multiple_of_period_blocking
    (Bonsai.return tick)
    (let%arr inject and get_now in
     let%bind.Effect now = get_now in
     inject (Tick now))
    graph;
  if config.bell
  then (
    let write = Expert.Write_to_tty.write_string_to_tty graph in
    Bonsai.Edge.on_change'
      ~equal:Int.equal
      (let%arr model in
       model.finished_phases)
      ~callback:
        (let%arr write in
         fun previous current ->
           match previous with
           | Some previous when previous <> current -> write "\007"
           | Some _ | None -> Effect.Ignore)
      graph);
  if config.set_title
  then
    Bonsai.Edge.on_change
      ~equal:String.equal
      (let%arr model and now in
       window_title model ~now)
      ~callback:(Title.set_title graph)
      graph;
  let view =
    let%arr flavor = Color.flavor graph
    and dimensions
    and model
    and now in
    view ~flavor ~dimensions ~config ~model ~now
  in
  let handler =
    let%arr inject and get_now and model in
    let with_now f =
      let%bind.Effect now = get_now in
      inject (f now)
    in
    let adjust minutes =
      with_now (fun now -> Timer.Action.Adjust { by = Time_ns.Span.of_min minutes; now })
    in
    fun (event : Event.t) ->
      match event with
      | Key_press { key = ASCII ' ' | Enter; mods = [] } ->
        with_now (fun now -> Timer.Action.Toggle now)
      | Key_press { key = ASCII ('r' | 'R'); mods = _ } -> inject Reset
      | Key_press { key = ASCII ('n' | 'N' | 's' | 'S'); mods = _ } ->
        with_now (fun now -> Skip now)
      | Key_press { key = ASCII ('+' | '=') | Arrow `Up; mods = _ } -> adjust 1.
      | Key_press { key = ASCII ('-' | '_') | Arrow `Down; mods = _ } -> adjust (-1.)
      | Key_press { key = ASCII ('q' | 'Q') | Escape; mods = [] }
      | Key_press { key = ASCII ('c' | 'C'); mods = [ Ctrl ] } ->
        exit (Summary.of_timer model)
      | _ -> Effect.Ignore
  in
  ~view, ~handler
;;

let command =
  Async.Command.async_or_error
    ~summary:"a little pomodoro timer for your terminal"
    ~readme:(fun () ->
      "Keys: space/enter start & pause, r reset, n skip, +/- (or up/down) add or remove \
       a minute, q/esc/ctrl-c quit.")
    (let%map_open.Command config = Config.param in
     fun () ->
       let open Async in
       let%map.Deferred.Or_error { Summary.completed; focused } =
         Bonsai_term.start_with_exit (fun ~exit ~dimensions graph ->
           app ~config ~exit ~dimensions graph)
       in
       if completed > 0
       then
         print_endline
           (sprintf
              "pomi: %s, %s focused. nice work."
              (pluralize completed "pomodoro")
              (format_duration focused)))
;;
