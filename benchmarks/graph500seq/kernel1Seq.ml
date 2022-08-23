(* Kernel 1 is a basic construction of an adjacency HashMap for undirected
   graphs which corresponds to a sparse graph implementation.
   INPUTS : an array of edges as (start vertex, end vertex, weight) tuples. *)

let max_vertex_label edges =
  Array.fold_left (fun acc (s,e,_) -> max acc (max s e)) (-1) edges

let build_sparse ar =
  let max_vertex_label = max_vertex_label ar in
  let g = SparseGraphSeq.create ~max_vertex_label in
  for i = 0 to Array.length ar - 1 do
    let (s,e,w) = ar.(i) in
    if not (s = e) then begin (* We remove self-loops *)
      SparseGraphSeq.add_edge (s,e,w) g;
      SparseGraphSeq.add_edge (e,s,w) g;
    end;
  done;
  g

let kernel1 edges =
  build_sparse edges
