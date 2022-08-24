let n = try int_of_string @@ Sys.argv.(1) with _ -> 120

module L = List

type coins = (int * int) list

type frame = { amt : int; coins : coins; current_enum : int list  }

let top = L.hd

let rest = L.tl

let rec run_cc (acc: int list list) (f : frame) (stack : frame list) : (int list list) =
    match f.amt, f.coins, stack with 
    | 0, _, []             -> acc
    | 0, _, _              -> run_cc (f.current_enum::acc) (top stack) (rest stack)
    | _, [], []            -> acc
    | _, [], _             -> run_cc acc (top stack) (rest stack)
    | _, (den,qty)::rst ,_ -> 
        if den > f.amt then
            let new_f = { amt = f.amt; coins = (rest f.coins); current_enum = f.current_enum } in
            run_cc acc new_f stack
        else 
            let new_coins = if qty == 1 then
                         rst 
                         else (den, qty-1)::rst in
            let left = { amt = (f.amt-den); coins = new_coins; current_enum = (den :: f.current_enum) } in
            let right = { amt = f.amt; coins = rst; current_enum = f.current_enum } in
            run_cc acc left (right::stack)

let cc amt (coins : (int * int) list) = 
    run_cc [] { amt = amt; coins = coins; current_enum = [] } []

let coins_input : (int * int) list =
    let den = [500 ; 250 ; 150; 100 ; 75 ; 50 ; 25 ; 20 ; 10 ; 5 ; 2 ; 1] in
    let qty = [22; 55 ; 88 ; 88 ; 99 ; 99 ; 122; 122; 122 ; 122; 177; 177] in  
  L.combine den qty

let () = 
    let x = cc n coins_input in
    Printf.printf "possibilities = %d\n" (L.length x)
