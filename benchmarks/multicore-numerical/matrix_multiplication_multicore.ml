module T = Domainslib.Task

let num_domains = try Sys.argv.(1) |> int_of_string with _ -> 1
let size = try Sys.argv.(2) |> int_of_string with _ -> 1024

let matrix_multiply pool res x y =
  let i_n = Array.length x in
  let j_n = Array.length y.(0) in
  let k_n = Array.length y in

  T.parallel_for ~start:0 ~finish:(i_n - 1) ~body:(fun i ->
    for j = 0 to j_n -1 do
      let w = ref 0 in
      for k = 0 to k_n - 1 do
        w := !w + x.(i).(k) * y.(k).(j);
      done;
      res.(i).(j) <- !w
    done) pool

let print_matrix m =
  for i = 0 to pred (Array.length m) do
    for j = 0 to pred (Array.length m.(0)) do
      print_string @@ Printf.sprintf " %d " m.(i).(j)
    done;
    print_endline "";
  done

let _ =
    let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) () in

    let m1 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
    let m2 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
    let res = Array.make_matrix size size 0 in

    (* print_matrix m1; print_matrix m2; *)
    matrix_multiply pool res m1 m2;
    T.teardown_pool pool;
    (* print_matrix res; *)
