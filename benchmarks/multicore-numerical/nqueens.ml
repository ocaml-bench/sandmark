(*
 * nqueen  4 = 2
 * nqueen  5 = 10
 * nqueen  6 = 4
 * nqueen  7 = 40
 * nqueen  8 = 92
 * nqueen  9 = 352
 * nqueen 10 = 724
 * nqueen 11 = 2680
 * nqueen 12 = 14200
 * nqueen 13 = 73712
 * nqueen 14 = 365596
 * nqueen 15 = 2279184
*)

(* xs contains an array of queen positions
 * i, j, k are the positions which conflict for the next element in xs
 * return true if none of the queens conflict and return false otherwise
 *)
let rec ok i j k xs =
  match xs with
    | [] -> true
    | h::t -> h<>i && h<>j && h<>k && ok i (j+1) (k-1) t

let rec nqueens n j xs =
  match n with
  | n when n = j -> 1
  | _ -> begin
      let count = ref 0 in
      for i = 0 to n-1 do
        if ok i (i+1) (i-1) xs then
          count := !count + (nqueens n (j+1) (i::xs))
      done;
      !count
    end

let board_size = try int_of_string Sys.argv.(1) with _ -> 13

let () =
  let n_solutions = nqueens board_size 0 [] in
  Printf.printf "%i solutions for board of size %i\n" n_solutions board_size
