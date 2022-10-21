type 'a t
type 'a hashset = 'a t

exception Full

val make: hash:('a -> int)
       -> eq:('a -> 'a -> bool)
       -> capacity:int
       -> maxload:float
       -> 'a t

val size: 'a t -> int
val capacity: 'a t -> int
val resize: 'a t -> 'a t
val insert: 'a t -> 'a -> bool
val to_list: 'a t -> 'a list
