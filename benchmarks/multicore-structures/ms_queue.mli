type 'a t

val create : unit -> 'a t
val enqueue : 'a t -> 'a -> unit
val dequeue : 'a t -> 'a option