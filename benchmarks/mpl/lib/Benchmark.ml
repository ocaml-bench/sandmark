let getTime f =
  let tm0 = Unix.gettimeofday () in
  let res = f () in
  let tm1 = Unix.gettimeofday () in
  let diff = tm1 -. tm0 in
  (res, diff)

let getTimes n f =
  let rec loop tms k =
    let (result, tm) = getTime f in
    Printf.printf "time %.03f\n" tm; flush stdout;
    if k <= 1 then (result, List.rev (tm :: tms))
    else loop (tm :: tms) (k-1)
  in
  loop [] n

let avg (tms: float list) : float =
  List.fold_left (+.) 0.0 tms /. float_of_int (List.length tms)

let warmup warmtime f =
  if warmtime <= 0.0 then () else
  (Printf.printf "======== WARMUP ========\n"; flush stdout;
  let start = Unix.gettimeofday () in
  let elapsed () = Unix.gettimeofday () -. start in
  let rec loop tms =
    let (_, tm) = getTime f in
    Printf.printf "warmup %.03f\n" tm; flush stdout;
    if elapsed () >= warmtime then List.rev (tm :: tms)
    else loop (tm :: tms)
  in
  let tms = loop [] in
  Printf.printf "warmup_average %.03f\n" (avg tms); flush stdout;
  Printf.printf "======== END WARMUP ========\n"; flush stdout;
  ())


let rec getopt needle argv f def =
  match argv with
  | opt::x::xs ->
    if opt = needle
    then f x else getopt needle (x::xs) f def
  | _ -> def

let run msg f =
  let argv = Sys.argv |> Array.to_list in
  let warmtime = getopt "-warmup" argv float_of_string 0.0 in
  let repeat = getopt "-repeat" argv int_of_string 1 in
  Printf.printf "warmup %0.1f\n" warmtime; flush stdout;
  Printf.printf "repeat %d\n" repeat; flush stdout;
  warmup warmtime f;
  print_string (msg ^ "\n");
  let ((result, tms), end_to_end_tm) = getTime (fun _ -> getTimes repeat f) in
  Printf.printf "average %.3f\n" (avg tms); flush stdout;
  Printf.printf "total   %.3f\n" (List.fold_left (+.) 0.0 tms); flush stdout;
  Printf.printf "end-to-end %.3f\n" end_to_end_tm; flush stdout;
  result
