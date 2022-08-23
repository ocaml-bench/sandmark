open GraphTypes

val go : scale:int -> edge_factor:int -> edge array
val to_file : filename:string -> edge array -> unit
val from_file : string -> edge array
val generate_to_file : scale:int -> edge_factor:int -> filename:string -> unit
