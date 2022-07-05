
(*************************************************************************************
* The main procudure cc enumerates all possible ways to distribute change for a      *
* given set of different denominations of coins of certain quantities for some given *
* amount.                                                                            *
*************************************************************************************)

let n = try int_of_string @@ Sys.argv.(1) with _ -> 960
module L = List

(* Selectors for tuples *)
let get_1 (x,_,_) = x 

let get_2 (_,y,_) = y

let get_3 (_,_,z) = z


let rec des amt coins curr acc stack =
    match amt, coins, stack with
    | _, _, [] -> acc 
    | 0, _, _ -> begin 
        let stack_top = L.hd stack in
        let stack_rest = L.tl stack in
        let get_amt = get_1 in 
        let get_coins = get_2 in
        let get_curr = get_3 in
        des (get_amt stack_top) (get_coins stack_top) (get_curr stack_top) (curr::acc) stack_rest 
    end
    | _, [], _ -> begin
        let stack_top = L.hd stack in
        let stack_rest = L.tl stack in
        let get_amt = get_1 in 
        let get_coins = get_2 in
        let get_curr = get_3 in
        des (get_amt stack_top) (get_coins stack_top) (get_curr stack_top) acc stack_rest 
    end
    | _, (den, qty)::rst, _ -> begin 
        let new_amt = amt - den in 
        let new_coins = (den, qty -1)::rst in 
        if den > amt then 
            des amt rst curr acc stack
        else if qty = 1 then 
            des new_amt rst (den::curr) acc stack 
        else if (L.tl coins) = [] || curr = [] then
            des new_amt new_coins (den::curr) acc stack
        else
            des new_amt new_coins (den::curr) acc ((amt, rst, curr)::stack)
    end

let cc amt (coins : ((int * int) list)) = 
    let rec aux c stack =
        match c with 
        | [] -> des amt coins [] [] stack
        | _ -> aux (L.tl c) (((amt, c, []))::stack) in 
    aux coins []

let coins_input : (int * int) list =
  let cs = [250 ; 100 ; 25 ; 10 ; 5 ; 1] in
  let qs = [55 ; 88 ; 88 ; 99 ; 122 ; 177] in
  L.combine cs qs

let () = 
    let x = cc n coins_input in
    Printf.printf "possibilities = %d\n" (L.length x)
