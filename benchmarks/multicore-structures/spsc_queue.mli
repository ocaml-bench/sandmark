type 'a t

val create : int -> 'a t
val enqueue : 'a t -> 'a -> bool
val dequeue : 'a t -> 'a option