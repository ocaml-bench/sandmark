open GraphTypes

module T = Domainslib.Task

val go : pool:T.pool -> scale:int -> edge_factor:int -> edge array
val to_file : filename:string -> edge array -> unit
val from_file : string -> edge array
val generate_to_file :
  pool:T.pool -> scale:int -> edge_factor:int -> filename:string -> unit
