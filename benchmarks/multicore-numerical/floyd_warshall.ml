let n = try int_of_string Sys.argv.(1) with _ -> 4

type e =
      | None
      | Some of int

let sum x y =
  match x , y with
  | Some x ,Some y -> Some (x+y)
  | _ , _-> None

let print_inf x =
  match  x with
  | Some x -> print_int x
  | None -> print_string "∞"


let my_formula () =
  let r = Random.int 100 in
  let r1 = Random.int 2 in
  match r1 with
  |0 ->None
  |_-> Some r


let adj = Array.init n (fun _ -> Array.init n (fun _ -> my_formula ()))

let edit_diagonal mat =
  Array.iteri (fun i _ -> mat.(i).(i) <- Some 0) mat


let f_w adj =
  for k = 0 to n-1 do
    for i = 0 to n-1 do
      if adj.(i).(k) <> None then
        for j = 0 to n-1 do
          if adj.(k).(j) <> None && (adj.(i).(j) = None || ( sum  adj.(i).(k)   adj.(k).(j) ) <  adj.(i).(j) ) then
            adj.(i).(j) <- (sum adj.(i).(k)  adj.(k).(j))
        done
    done
  done

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


let ()=
  edit_diagonal adj;
  f_w adj
 (* print_mat adj*)
