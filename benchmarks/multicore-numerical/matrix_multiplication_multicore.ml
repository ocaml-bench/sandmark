module T = Domainslib.Task

let num_domains = try Sys.argv.(1) |> int_of_string with _ -> 1
let n = try Sys.argv.(2) |> int_of_string with _ -> 1024
let pool = T.setup_pool ~num_domains:(num_domains - 1)
let m3 = Array.make_matrix n n 0

let mat_mul m1 m2 =
  let i_n = Array.length m1 in
  let j_n = Array.length m2.(0) in
  let k_n = Array.length m2 in

  T.parallel_for pool ~start:0 ~finish:(i_n - 1) ~body:(fun i ->
    for j = 0 to pred j_n do
      for k = 0 to pred k_n do
        m3.(i).(j) <- m3.(i).(j) + (m1.(i).(k) * m2.(k).(j));
      done;
    done)

(* let print_matrix m =
  for i = 0 to pred (Array.length m) do
    for j = 0 to pred (Array.length m.(0)) do
      print_string @@ Printf.sprintf " %d " m.(i).(j)
    done;
    print_endline "";
  done *)

let _ =
    let m1 = Array.init n (fun _ -> Array.init n (fun _ -> Random.int 100)) in
    let m2 = Array.init n (fun _ -> Array.init n (fun _ -> Random.int 100)) in
    (* print_matrix m1;
    print_matrix m2; *)
    mat_mul m1 m2;
    T.teardown_pool pool;
    (* print_matrix m3; *)
