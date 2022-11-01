type grain = int
val pool: Domainslib.Task.pool

val run: (unit -> 'a) -> 'a

val par: (unit -> 'a) -> (unit -> 'b) -> 'a * 'b

val par3:
  (unit -> 'a) -> (unit -> 'b) -> (unit -> 'c)
  ->
  'a * 'b * 'c

val par4:
  (unit -> 'a) -> (unit -> 'b) -> (unit -> 'c) -> (unit -> 'd)
  ->
  'a * 'b * 'c * 'd

val parfor: grain -> (int * int) -> (int -> unit) -> unit
