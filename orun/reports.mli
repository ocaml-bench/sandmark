open Common

val render_trace_json :
  string -> compressed_sample list -> (source_line, int) Hashtbl.t -> unit

val render_hotspots_html :
     string
  -> ((string * string) * (counts * (int * counts) list option)) list
  -> int
  -> unit
