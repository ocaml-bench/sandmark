let size = try int_of_string Sys.argv.(1) with _ -> 1024

let matrix_multiply res x y =
  let i_n = Array.length x in
  let j_n = Array.length y.(0) in
  let k_n = Array.length y in

  for i = 0 to i_n - 1 do
    for j = 0 to j_n - 1 do
      let w = ref 0 in
      for k = 0 to k_n - 1 do
        w := !w + x.(i).(k) * y.(k).(j);
      done;
      res.(i).(j) <- !w
    done
  done

let print_matrix m =
  for i = 0 to pred (Array.length m) do
    for j = 0 to pred (Array.length m.(0)) do
      print_string @@ Printf.sprintf " %d " m.(i).(j)
    done;
    print_endline "";
  done

let () =

  let m1 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
  let m2 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
  let res = Array.make_matrix size size 0 in

  matrix_multiply res m1 m2;

  (* print_matrix res; *)
