module T = Domainslib.Task

let n = try int_of_string @@ Sys.argv.(1) with _ ->  10000

let num_domains = try int_of_string @@ Sys.argv.(2) with _ -> 4

let domain_pool = T.setup_pool ~num_domains:num_domains

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

let list_chunker = fun lst chunk ->
    let (<.>) = List.nth in
    let temp_lst = ref [] in
    let new_lst = ref [] in
    for i = 1 to (List.length lst) do
        match (i mod chunk) = 0 with
        | true -> begin new_lst := (List.rev @@ !temp_lst) :: !new_lst;
                    temp_lst := [];
                    end
        | false -> temp_lst := (lst<.>(i - 1)) :: !temp_lst;
        done;
    
    begin
    match List.length !temp_lst = 0 with
    | true -> 
        new_lst := List.rev @@ !new_lst;
    | false ->
        new_lst := (List.rev @@ !temp_lst) :: !new_lst;
        new_lst := List.rev @@ !new_lst;
    end;
    !new_lst

(* let f = fun lst -> *)


let main () =
    let chunk = (n/num_domains) + 1 in
    let lst = List.init n (fun _ -> Random.int (2*n)) in 
    let lst = list_chunker lst chunk in
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
