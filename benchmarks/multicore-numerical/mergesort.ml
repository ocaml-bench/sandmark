let rec take n = function
  | [] -> []
  | x::xs -> if (n > 0) then x :: (take (n-1) xs) else []

let rec drop n = function
  | [] -> []
  | x::xs -> if (n = 0) then x::xs
    else if (n > 0) then (drop (n-1) xs)
    else []

let rec merge x y =
  match x, y with
    | [], l -> l
    | l, [] -> l
    | x :: xs , y :: ys ->
      if x < y
          then x :: merge xs (y :: ys)
          else y :: merge (x::xs) ys

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
    let n = Random.int 1000000 in
    let list = n :: l in
    gen (size - 1) list

let n = try int_of_string(Array.get Sys.argv 1) with _ ->  100000

let _ =
   let lst = gen n [] in
   msort lst |> ignore;
