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

let create_int32_array n =
  let a = Array1.create int32 c_layout n in
  for i = 0 to Array1.dim a - 1 do
    Array1.set a i (Int32.of_int i)
  done;
  a

let rev a =
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
    Sys.opaque_identity (ignore (rev a))
  done

let big_array_int32_rev iterations length =
  let a = create_int32_array length in
  for i = 1 to iterations do
    Sys.opaque_identity (ignore (rev a))
  done

let () =
  match bench_type with
  | "big_array_int_rev" ->
      big_array_int_rev iterations length
  | "big_array_int32_rev" ->
      big_array_int32_rev iterations length
  | _ ->
      ()
