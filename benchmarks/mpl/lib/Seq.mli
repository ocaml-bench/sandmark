type 'a t
type 'a seq = 'a t

val get: 'a seq -> int -> 'a
val set: 'a seq -> int -> 'a -> unit

val length: 'a seq -> int
val empty: unit -> 'a seq
val full: 'a array -> 'a seq
val base: 'a seq -> 'a array * int * int

val of_list: 'a list -> 'a seq
val to_list: 'a seq -> 'a list
(* val to_string: ('a -> string) -> 'a seq -> string *)

val subseq: 'a seq -> int * int -> 'a seq
val take: 'a seq -> int -> 'a seq
val drop: 'a seq -> int -> 'a seq

val tabulate: (int -> 'a) -> int -> 'a seq
val map: ('a -> 'b) -> 'a seq -> 'b seq
val rev: 'a seq -> 'a seq
val append: 'a seq -> 'a seq -> 'a seq

val fold_left: ('b -> 'a -> 'b) -> 'b -> 'a seq -> 'b
val fold_right: ('a -> 'b -> 'b) -> 'b -> 'a seq -> 'b

val scan: ('a -> 'a -> 'a) -> 'a -> 'a seq -> 'a seq * 'a
val scan_incl: ('a -> 'a -> 'a) -> 'a -> 'a seq -> 'a seq
val reduce: ('a -> 'a -> 'a) -> 'a -> 'a seq -> 'a

val filter: ('a -> bool) -> 'a seq -> 'a seq
val filter_idx: (int -> 'a -> bool) -> 'a seq -> 'a seq

val foreach: 'a seq -> (int -> 'a -> unit) -> unit

val flatten: 'a seq seq -> 'a seq
