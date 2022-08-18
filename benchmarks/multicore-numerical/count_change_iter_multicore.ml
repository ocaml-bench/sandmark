let n = try int_of_string @@ Sys.argv.(1) with _ -> 120
let num_domains = try int_of_string @@ Sys.argv.(1) with _ ->  1 

module A = Array
module L = List
module T = Domainslib.Task

type coins = (int * int) list

type frame = { amt : int; coins : coins; current_enum : int list  }

let top = L.hd

let rest = L.tl

let rec run_cc first_call (acc: int list list) (f : frame) (stack : frame list) : (int list list) =
    match f.amt, f.coins, stack with 
    | 0, _, []             -> acc
    | 0, _, _              -> run_cc false (f.current_enum::acc) (top stack) (rest stack)
    | _, [], []            -> acc
    | _, [], _             -> run_cc false acc (top stack) (rest stack)
    | _, (den,qty)::rst ,_ -> 
        if den > f.amt then
            let new_f = { amt = f.amt; coins = (rest f.coins); current_enum = f.current_enum } in
            run_cc false acc new_f stack
        else 
            let new_coins = if qty == 1 then
                         rst 
                         else (den, qty-1)::rst in
            let left = { amt = (f.amt-den); coins = new_coins; current_enum = (den :: f.current_enum) } in
            let right = { amt = f.amt; coins = rst; current_enum = f.current_enum } in
            if not first_call then run_cc false acc left (right::stack)
            else
                run_cc false acc left stack

let cc amt (coins : (int * int) list) = 
    run_cc true [] { amt = amt; coins = coins; current_enum = [] } []

let rec get_deductibles amt coins = 
    let den = fst @@ L.hd coins in
    match (den > amt) with
    | false -> coins
    | true  -> get_deductibles amt (L.tl coins)

let setup_frames amt coins =
    let coins = get_deductibles amt coins in
    let clen = L.length coins in
    let a = Array.make clen { amt = 0; coins = []; current_enum = [] } in
    let rec aux count coins = 
        match count = clen with 
        | true -> a
        | false -> begin  
            let f = {
                amt = amt;
                coins = coins;
                current_enum = []
            } in
            a.(count) <- f; 
            aux (count+1) (L.tl coins)
        end
    in
    aux 0 coins

let sum_lengths arr = A.fold_left (+) 0 (A.map L.length arr)

let cc_par pool amt (coins : ((int * int) list)) = 
    let stacks = setup_frames amt coins in 
    let arr = A.init (A.length stacks) (fun _ -> []) in
    let len   = A.length arr in
    T.parallel_for pool ~start:0 ~finish:(len-1) ~body:(fun i ->
        let f = stacks.(i) in
        arr.(i) <- cc f.amt f.coins
    );
    Printf.printf "possibilites = %d\n" (sum_lengths arr)

let coins_input : (int * int) list =
    let den = [500 ; 250 ; 150; 100 ; 75 ; 50 ; 25 ; 20 ; 10 ; 5 ; 2 ; 1] in
    let qty = [22; 55 ; 88 ; 88 ; 99 ; 99 ; 122; 122; 122 ; 122; 177; 177] in  
  L.combine den qty

let _ = 
    let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) () in
    T.run pool (fun () -> cc_par pool n coins_input);
    T.teardown_pool pool
