let seed = int_of_string Sys.argv.(1)
let width = int_of_string Sys.argv.(2)
let depth = int_of_string Sys.argv.(3)

let prng = Random.State.make [| seed |]

type box = {a: int64; b: int32;}
let box_e =
  let open Data_encoding in
  obj2
    (req "sixty-four" int64)
    (req "thirty-two" int32)

let box () = {
  a = Random.State.int64 prng Int64.max_int;
  b = Random.State.int32 prng Int32.max_int;
}
let option f () = if Random.State.bool prng then Some (f ()) else None
let rec list n f acc =
  if n <= 0 then
    acc
  else
    list (n - 1) f (f () :: acc)
let list n f () = list n f []

let t () = list depth (list width (option box)) ()

type t = box option list list
let e =
  let open Data_encoding in
  list (dynamic_size @@ list (dynamic_size option box_e))

let () =
  let v = t () in
  let b = Data_encoding.Binary.to_bytes_exn e v in
  let vv = Data_encoding.Binary.of_bytes_exn e b in
  assert (v = vv)
