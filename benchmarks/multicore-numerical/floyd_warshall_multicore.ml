module T = Domainslib.Task

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ -> 4
(* n is size of matrix  *)

type edge =
  | Infinity
  | Value of int

let print_inf x =
  match  x with
  | Value x -> print_int x
  | Infinity -> print_string "∞"

let print_mat adjacency =
  print_endline " ";
  let rows = Array.length adjacency in
  let columns = Array.length adjacency.(0) in
  for i = 0 to (rows - 1) do
    for j = 0 to (columns - 1) do
      print_inf adjacency.(i).(j); print_string " "
    done;
    print_endline " "
  done

(* setup the adjacency matrix for the test *)
let make_adj n =
  let random_init _i =
    match Random.int 2 with
    | 0 -> Infinity
    | _ -> Value (Random.int 100) in
  let mat = Array.init n (fun _ -> Array.init n random_init) in
  (* zero the diagonal *)
  for i = 0 to (n-1) do
    mat.(i).(i) <- Value 0
  done;
  mat

let f_w pool adj =
  for k = 0 to (n-1) do
    T.run pool (fun _ ->
      T.parallel_for pool
        ~start:0
        ~finish:(n - 1)
        ~body:(fun i ->
          match adj.(i).(k) with
          | Value a_ik ->
             for j = 0 to n-1 do
               match adj.(i).(j), adj.(k).(j) with
               | Infinity, Value a_kj ->
                  adj.(i).(j) <- Value (a_ik + a_kj)
               | Value a_ij, Value a_kj when a_ik + a_kj < a_ij ->
                  adj.(i).(j) <- Value (a_ik + a_kj)
               | _, _ -> ()
             done
          | Infinity -> ()
      ))
  done

let ()=
  Random.init 512;
  let adj = make_adj n in
  let pool = T.setup_pool ~num_domains:(num_domains - 1) () in
  (*
  let adj = [|
    [| Value 0; Value 8; Infinity; Value 1 |];
    [| Infinity; Value 0; Value 1; Infinity|];
    [| Value 4; Infinity; Value 0; Infinity |];
    [| Infinity; Value 2; Value 9; Value 0 |];
  |] in
  *)
  f_w pool adj;
  (* print_mat adj ; *)
  T.teardown_pool pool
