open GraphTypes

val update_discovered : bool array -> vertex -> unit

(*val set_parent : ~parent_array:vertex array -> ~parent:vertex -> ~child:vertex -> unit*)

val get_bool_vect_val_at_index : bool array -> int -> bool

val is_discovered: bool array -> vertex -> bool

(*val bfs : SparseGraphSeq.t -> vertex -> vertex array -> vertex array -> vertex Queue.t -> vertex array*)

val kernel2 : SparseGraphSeq.t -> vertex -> vertex array
