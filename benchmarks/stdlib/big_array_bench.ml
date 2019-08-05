open Bigarray

let bench_type = Sys.argv.(1)
let length = int_of_string Sys.argv.(2)
let iterations = int_of_string Sys.argv.(3)

let create_int_array size =
  let a = Array1.create int c_layout size in
  for i = 0 to Array1.dim a - 1 do
    Array1.set a i i
  done;
  a

let int_rev a =
  if Array1.dim a > 0
  then
    for i = 0 to (Array1.dim a - 1) / 2 do
      let t = Array1.get a i in
      Array1.set a i (Array1.get a (Array1.dim a - (1 + i)));
      Array1.set a (Array1.dim a - (1 + i)) t
    done;
  a

let big_array_int_rev iterations length =
  let a = create_int_array length in
  for i = 1 to iterations do
    Sys.opaque_identity (ignore (int_rev a))
  done

let () =
  match bench_type with
  | "big_array_int_rev" ->
      big_array_int_rev iterations length
  | _ ->
      ()
