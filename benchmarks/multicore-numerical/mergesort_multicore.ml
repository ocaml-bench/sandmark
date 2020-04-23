module T = Domainslib.Task

let num_domains = try int_of_string @@ Sys.argv.(1) with _ -> 4

let n = try int_of_string @@ Sys.argv.(2) with _ ->  10000

let domain_pool = T.setup_pool ~num_domains:(num_domains - 1)

let rec take n = function
  | [] -> []
  | x::xs -> if (n > 0) then x :: (take (n-1) xs) else []

let rec drop n = function
  | [] -> []
  | x::xs -> if (n = 0) then x::xs
    else if (n > 0) then (drop (n-1) xs)
    else []

let slice lst start range = take range (drop start lst)

let rec merge x y =
  match x, y with
    | [], l -> l
    | l, [] -> l
    | x :: xs , y :: ys ->
      if x < y
          then x :: merge xs (y :: ys)
          else y :: merge (x::xs) ys


let rec halving l =
  match l with
  | [] -> []
  | [x] -> [x]
  | [x;y] -> if (x < y) then [x;y] else [y;x]
  | _ ->
    let left = take (List.length l/2) l in
    let right = drop (List.length l/2) l in
    merge (halving left) (halving right)

let rec msort l =
  match l with
  | [] -> []
  | [x] -> [x]
  | _ ->
    let left = take (List.length l/2) l in
    let right = drop (List.length l/2) l in
    (* Printf.printf "I'm merging\n"; *)
    merge (msort left) (msort right)


let main () =
    let arr = Array.init n (fun _ -> Random.int 100) in 
    (* List.iter (fun el ->
        List.iter (fun x -> Printf.printf " %d " x) el;
        print_endline ""; ) new_lst *)
    let _lst =
        List.map (fun l -> T.async domain_pool (fun _ -> msort l)) lst |>
        List.map (fun l -> T.await domain_pool l) |>
        msort |>
        List.fold_left (fun acc x -> acc @ x) [] in
    (* List.iter (fun e -> Printf.printf " %d " e) lst;
    print_endline "" *)
        ()

let _ = main ()
