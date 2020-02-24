let n = try int_of_string (Array.get Sys.argv 1) with _ ->  10000

let num_domains = try int_of_string (Array.get Sys.argv 2) with _ -> 4

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

 let rec gen size l =
  if size = 0 then
     l
  else
    let n = Random.int 1000 in
    let list = n :: l in
    gen (size - 1) list

let rec spawn n lst st incr =
  if (n = 0) then []
  else begin
    Domain.spawn(fun _ -> halving (slice lst st incr)) :: spawn (n-1) lst (st + incr) incr
  end

let _ =
   let lst = gen n [] in
   let domains = spawn num_domains lst 0 (n / num_domains) in
   let res = List.map Domain.join domains in
   let sorted = List.fold_left merge [] res in
   List.iter (Printf.printf "%d\n") sorted;
   Gc.print_stat stdout
