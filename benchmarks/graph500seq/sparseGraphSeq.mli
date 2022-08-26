open GraphTypes

type t

(** Create a sparse graph representation able to contain vertices with labels
    lesser than or equal to [max_vertex_label]. *)
val create : max_vertex_label:int -> t

val add_edge : edge -> t -> unit

val from : vertex -> t -> (vertex * weight) list

val max_vertex_label : t -> vertex

val num_vertices : t -> int

val get_next_edgenode : t -> vertex -> (vertex * weight)

val get_vertex : (vertex * weight) -> vertex

val get_weight : (vertex * weight) -> weight

val has_no_edgenodes : t -> vertex -> bool

val copy_graph : t -> t

val has_selfloop:  vertex -> (vertex * weight) list -> bool

val graph : t

val graph2 : t

val graph3 : t

val graph4 : t

val print_sparse_graph: t -> unit

val print_vertex: vertex -> unit

(** Return a random vertex from the graph of degree at least 1. *)
val sample_vertex : t -> vertex
