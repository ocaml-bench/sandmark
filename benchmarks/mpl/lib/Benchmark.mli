val getTime: (unit -> 'a) -> ('a * float)
val getTimes: int -> (unit -> 'a) -> ('a * float list)
val avg: float list -> float
val warmup: float -> (unit -> 'a) -> unit
val run: string -> (unit -> 'a) -> 'a
