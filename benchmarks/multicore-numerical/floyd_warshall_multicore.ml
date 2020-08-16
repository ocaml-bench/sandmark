let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ -> 4
(* n is size of matrix  *)

let sum x y =
  match x , y with
  | Some x ,Some y -> Some (x+y)
  | _ , _-> None

let print_inf x =
  match  x with
  | Some x -> print_int x
  | None -> print_string "∞"

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

module T = Domainslib.Task

let my_formula () =
  let r = Random.int 100 in
  let r1 = Random.int 2 in
  match r1 with
  |0 ->None
  |_-> Some r

let adj = Array.init n (fun _ -> Array.init n (fun _ -> my_formula ()))

let edit_diagonal mat =
  Array.iteri (fun i _ -> mat.(i).(i) <- Some 0) mat

(* let adj = [|
    [| Some 0; Some 8;None; Some 1 |];
    [| None; Some 0; Some 1; None|];
    [| Some 4;None;Some 0;None |];
    [| None; Some 2; Some 9;Some 0 |];
  |] *)

let aux pool =
  for k = 0 to (pred n) do
    T.parallel_for pool
    ~chunk_size:(n/(8*num_domains))
    ~start:0
    ~finish:(n - 1)
    ~body:(fun i ->
      if adj.(i).(k) <> None then
        for j = 0 to n-1 do
          Domain.Sync.poll();
            if adj.(k).(j) <> None
              && (adj.(i).(j) = None
              || (sum adj.(i).(k) adj.(k).(j)) <  adj.(i).(j))
            then adj.(i).(j) <- (sum adj.(i).(k)  adj.(k).(j))
        done);
  done

let ()=
  let pool = T.setup_pool ~num_domains:(num_domains - 1) in
  edit_diagonal adj;
  aux pool;
  (* print_mat adj ; *)
  T.teardown_pool pool