open GraphTypes

type t = (vertex * weight) list Atomic.t array

let create ~max_vertex_label =
  assert (max_vertex_label <= 1 lsl 60); (* More than 2^60 vertices seems a bit
                                            much. *)
  Array.init (max_vertex_label + 1) (fun _ -> Atomic.make [])

let max_vertex_label g =
  Array.length g - 1

let rec add_edge (s,e,w) g =
  let old = Atomic.get g.(s) in
  let new_ = (e,w) :: old in
  if Atomic.compare_and_set g.(s) old new_ then ()
  else add_edge (s,e,w) g

let from s g =
  Atomic.get g.(s)

let rec sample_vertex g =
  let v = Random.int (Array.length g) in
  let outgoing = Atomic.get g.(v) in
  if outgoing <> [] then v else sample_vertex g
