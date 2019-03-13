let depth = int_of_string Sys.argv.(1)
let arguments = Sys.argv.(2)

let rec ints_small a0 n = if n == 0 then
  1
else
  a0 + (ints_small a0 (n - 1)) * a0

let rec ints_large a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 n = if n == 0 then
  1
else
  a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10 + a11 + a12 + a13 + a14 + a15 + (ints_large a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 (n-1)) * a0

let rec floats_small a0 n = if n == 0 then
  1.0
else
  a0 +. (floats_small a0 (n - 1)) *. a0

let rec floats_large a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 n = if n == 0 then
  1.0 
else 
  a0 +. a1 +. a2 +. a3 +. a4 +. a5 +. a6 +. a7 +. a8 +. a9 +. a10 +. a11 +. a12 +. a13 +. a14 +. a15 +. (floats_large a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 (n-1)) *. a0

let run_many_times f =
  for _ = 1 to 20000 do
    f ()
  done

let () = let result = match arguments with
    | "ints-small" -> run_many_times (fun _ -> ints_small 100 depth)
    | "ints-large" -> run_many_times (fun _ -> ints_large 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 depth)
    | "floats-small" -> run_many_times (fun _ -> floats_small 100.0 depth)
    | "floats-large" -> run_many_times (fun _ -> floats_large 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 depth)
    | _ -> failwith "unexpected arguments"
  in ignore(Sys.opaque_identity result)