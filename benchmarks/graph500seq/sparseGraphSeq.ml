open GraphTypes

type t = (vertex * weight) list array

let create ~max_vertex_label =
  assert (max_vertex_label <= 1 lsl 60); (* More than 2^60 vertices seems a bit
                                            much. *)
  Array.init (max_vertex_label + 1) (fun _ -> [])

let max_vertex_label g =
  Array.length g - 1

let add_edge (s,e,w) g =
  g.(s) <- (e,w) :: g.(s)

let from s g =
  g.(s)

let rec sample_vertex g =
  let v = Random.int (Array.length g) in
  let outgoing = g.(v) in
  if outgoing <> [] then v else sample_vertex g
