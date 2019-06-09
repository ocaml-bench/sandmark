open Printf
open Common

let css =
  {|
        .outer-container { max-width: 1700px; margin: 0 auto }
        .gray-row { background-color: rgb(250, 250, 250) }
        .hotspot-row { padding: 15px; }
        .source_code { font-family: Menlo, Monaco, Consolas, "Courier New"; font-size: 14pt; }
|}

let common_header name =
  sprintf
    {|
<!DOCTYPE html><html><head>
<title>%s</title>
<style>%s</style>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap.min.css" integrity="sha256-916EbMg70RQy9LHiGkXzG8hSg9EdNy97GazNG/aiY1w=" crossorigin="anonymous">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/js/bootstrap.min.js" integrity="sha256-U5ZEeKfGNOja007MMD3YBI0A3OSZOQbeG6z2f2Y0hu8=" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/jquery@3.4.1/dist/jquery.min.js" integrity="sha256-CSXorXvZcTkaix6Yvo6HppcZGetbYMGWSFlBw8HfCJo=" crossorigin="anonymous"></script>
</head><body><div class="outer-container"><div class="container-fluid"><h3>Hotspots %s</h3>
<div class="hotspot-row row"><div class="col-xs-4"><b>File</b></div><div class="col-xs-3"><b>Function</b></div><div class="col-xs-2"><b>Self time</b></div><div class="col-xs-2"><b>Total time</b></div></div>
|}
    name css name

let common_footer = "</div></div></body></html>"

let shrink_file_location f =
  String.concat "/" (List.rev (take (List.rev (String.split_on_char '/' f)) 3))

let tab_regex = Str.regexp "\t"

let space_regex = Str.regexp " "

let replace_tabs_and_spaces s =
  Str.global_replace space_regex "&nbsp;"
    (Str.global_replace tab_regex "&nbsp;" s)

let render_hotspot output total_samples idx
    ((file, function_name), ((counts : counts), line_counts_option)) =
  fprintf output
    {|<div class="hotspot-row %s row"><div class="col-xs-4"><a data-toggle="tooltip" title="%s">%s</a></div><div class="col-xs-3">%s</div><div class="col-xs-2">%d (%d%%)</div><div class="col-xs-2">%d (%d%%)</div><div class="col-xs-1"><button id="view_source_%d" class="btn btn-xs">View source</button></div></div>
    <script>
    $("#view_source_%d").click(function(){
      $("#source_%d").toggle();
    });
    </script>|}
    (if idx mod 2 == 0 then "gray-row" else "")
    file
    (shrink_file_location file)
    function_name counts.self_time
    (100 * counts.self_time / total_samples)
    counts.total_time
    (100 * counts.total_time / total_samples)
    idx idx idx ;
  (* find min and max lines if there's any line info *)
  match line_counts_option with
  | Some line_counts ->
      if Sys.file_exists file then (
        let min_line =
          List.fold_left
            (fun a (line, _) -> if line < a then line else a)
            max_int line_counts
          - 5
        in
        let max_line =
          List.fold_left
            (fun a (line, _) -> if line > a then line else a)
            min_int line_counts
          + 5
        in
        let original_src = open_in file in
        let current_line = ref 1 in
        try
          fprintf output
            {| <div id="source_%d" class="row" style="display: none;"><div class="col-xs-offset-1 col-xs-10"> |}
            idx ;
          while true do
            let assoc_opt = List.assoc_opt !current_line line_counts in
            let self_time =
              match assoc_opt with Some c -> c.self_time | None -> 0
            in
            let total_time =
              match assoc_opt with Some c -> c.total_time | None -> 0
            in
            let src_line = input_line original_src in
            let html_line = replace_tabs_and_spaces src_line in
            if !current_line >= min_line && !current_line <= max_line then
              fprintf output
                {| <div id="source_%d_%d" class="source_code row %s"><div class="col-xs-1 text-right">%d</div><div class="col-xs-9">%s</div><div class="col-xs-1 text-left">%d</div><div class="col-xs-1 text-left">%d</div></div> |}
                idx !current_line
                (if !current_line mod 2 == 0 then "" else "gray-row")
                !current_line html_line self_time total_time ;
            incr current_line
          done
        with End_of_file ->
          fprintf output {| </div></div> |} ;
          close_in original_src )
      else
        fprintf output "<style>#view_source_%d { display: none; }</style>" idx
  | None ->
      fprintf output "<style>#view_source_%d { display: none; }</style>" idx

let render_hotspots_html output_name hotspots total_samples =
  let hotspots_file = open_out (output_name ^ "_prof_results/hotspots.html") in
  fprintf hotspots_file "%s" (common_header output_name) ;
  List.iteri (render_hotspot hotspots_file total_samples) hotspots

let generate_stacks stack_idxs sample =
  let max_idx = List.length sample.stack - 1 in
  let stack_json =
    List.mapi
      (fun depth stack ->
        let src_line = Hashtbl.find stack_idxs stack in
        let category =
          match src_line.filename with
          | None ->
              "unknown"
          | Some x ->
              Filename.basename x
        in
        let name = get_or "unknown" src_line.function_name in
        let base_list = [("name", `String (category ^ ":" ^ name))] in
        let related_list =
          match depth with
          | x when x = max_idx ->
              base_list
          | n ->
              ( "parent"
              , `String (string_of_int sample.id ^ "_" ^ string_of_int (n + 1))
              )
              :: base_list
        in
        ( string_of_int sample.id ^ "_" ^ string_of_int depth
        , `Assoc related_list ) )
      sample.stack
  in
  stack_json

let generate_all_stacks stack_idxs samples =
  List.flatten (List.map (generate_stacks stack_idxs) samples)

let convert_sample stack_idxs sample =
  `Assoc
    [ ("cpu", `Int sample.cpu)
    ; ("tid", `Int sample.thread_id)
    ; ("ts", `Float (float_of_int sample.timestamp))
    ; ("name", `String "perf-cpu")
    ; ("sf", `String (string_of_int sample.id ^ "_0"))
    ; ("weight", `Int 1) ]

let stack_frames samples stack_idxs =
  List.map (convert_sample stack_idxs) samples

let render_trace_json output_name samples stack_idxs =
  let inverted_idxs = invert_hashtbl stack_idxs in
  let output_file = open_out (output_name ^ "_prof_results/trace.json") in
  let trace_json =
    `Assoc
      [ ("traceEvents", `List [])
      ; ("samples", `List (stack_frames samples inverted_idxs))
      ; ("stackFrames", `Assoc (generate_all_stacks inverted_idxs samples)) ]
  in
  Yojson.Basic.to_channel output_file trace_json
