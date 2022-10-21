val write_merge_serial:
  ('a -> 'a -> int) -> 'a Seq.t -> 'a Seq.t -> 'a Seq.t -> unit
val write_merge:
  ('a -> 'a -> int) -> 'a Seq.t -> 'a Seq.t -> 'a Seq.t -> unit

val merge_serial:
  ('a -> 'a -> int) -> 'a Seq.t -> 'a Seq.t -> 'a Seq.t
val merge:
  ('a -> 'a -> int) -> 'a Seq.t -> 'a Seq.t -> 'a Seq.t
