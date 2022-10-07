open GraphTypes

type t

(** Create a sparse graph representation able to contain vertices with labels
    lesser than or equal to [max_vertex_label]. *)
val create : max_vertex_label:int -> t

(** Add edge to the sparse graph *)
val add_edge : edge -> t -> unit

val from : vertex -> t -> (vertex * weight) list

(** *)
val max_vertex_label : t -> vertex

(** Rerturn the number of vertices *)
val num_vertices : t -> int

(** Takes a sparse graph g and a vertex v and returns the next edgenode 
    res in the edgenode list of v and changes the state of g with res removed
    from the edgenode list of v. *)
val get_next_edgenode : t -> vertex -> (vertex * weight)

(** Extract vertex from the (vertex, weight) edgenode *)
val get_vertex : (vertex * weight) -> vertex

(** Extract weight from (vertex, weight)  edgenode *)
val get_weight : (vertex * weight) -> weight

(** Returns true if the vertex v has not out-going edges 
    and false otherwise *)
val has_no_edgenodes : t -> vertex -> bool

(** Returns a copy of the graph *)
val copy_graph : t -> t

(** Returns true if the vertex has an edge pointing to itself *)
val has_selfloop:  vertex -> (vertex * weight) list -> bool

val print_sparse_graph: t -> unit

val print_vertex: vertex -> unit

(** Return a random vertex from the graph of degree at least 1. *)
val sample_vertex : t -> vertex
