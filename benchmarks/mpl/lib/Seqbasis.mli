type grain = int
(*
val for: (int * int)
        -> (int -> unit)
        -> unit *)

val foldl: ('b -> 'a -> 'b)
        -> 'b
        -> (int * int)
        -> (int -> 'a)
        -> 'b

val tabulate: grain
           -> (int * int)
           -> (int -> 'a)
           -> 'a array

val reduce: grain
         -> ('a -> 'a -> 'a)
         -> 'a
         -> (int * int)
         -> (int -> 'a)
         -> 'a

val prim_reduce: grain
              -> ('a -> 'a -> 'a)
              -> 'a
              -> (int * int)
              -> (int -> 'a)
              -> 'a

val scan: grain
       -> ('a -> 'a -> 'a)
       -> 'a
       -> (int * int)
       -> (int -> 'a)
       -> 'a array  (* length N+1, for both inclusive and exclusive scan *)

val prim_scan: grain
            -> ('a -> 'a -> 'a)
            -> 'a
            -> (int * int)
            -> (int -> 'a)
            -> 'a array

val filter: grain
         -> (int * int)
         -> (int -> 'a)
         -> (int -> bool)
         -> 'a array

(*
val tabFilter: grain
            -> (int * int)
            -> (int -> 'a option)
            -> 'a array
*)
