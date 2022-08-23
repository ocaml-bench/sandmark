(* Kernel 1 is a basic construction of an adjacency HashMap for undirected
   graphs which corresponds to a sparse graph implementation.
   INPUTS : an array of edges as (start vertex, end vertex, weight) tuples. *)

open GraphTypes

(* Ensure that for every edge (start, end), start > end, swapping start and
   end if necessary. Remove self-loops. Also returns the maximum edge label. *)
let _normalize : edge array -> edge array * vertex = fun edges ->
  let edges, max_label = Array.fold_left
      (fun (edges, max_label) (s,e,w) ->
        if s > e then (s,e,w) :: edges, max s max_label
        else if s = e then edges, max s max_label
        else (e,s,w) :: edges, max e max_label
      )
      ([],0)
      edges
  in
  Array.of_list (List.rev edges), max_label

module T = Domainslib.Task

let max_vertex_label ~pool edges =
  T.parallel_for_reduce ~start:0 ~finish:(Array.length edges - 1)
    ~body:(fun i -> let (s,e,_) = edges.(i) in max s e) pool max (-1)

let build_sparse ~pool ar =
  let max_vertex_label = max_vertex_label ~pool ar in
  let g = SparseGraph.create ~max_vertex_label in
  T.parallel_for pool ~start:0 ~finish:(Array.length ar - 1) ~body:(fun i ->
    let (s,e,w) = ar.(i) in
    if not (s = e) then begin (* We remove self-loops *)
      SparseGraph.add_edge (s,e,w) g;
      SparseGraph.add_edge (e,s,w) g;
    end;
  );
  g

let kernel1 ~pool edges =
  build_sparse ~pool edges
