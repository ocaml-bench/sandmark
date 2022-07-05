let num_domains = try int_of_string @@ Sys.argv.(1) with _ ->  1 
let n = try int_of_string @@ Sys.argv.(2) with _ -> 960

module A = Array
module L = List
module T = Domainslib.Task

(* Selectors for tuples *)
let get_1 (x,_,_) = x 

let get_2 (_,y,_) = y

let get_3 (_,_,z) = z

let rec des amt coins curr acc stack =
    (* Descends down the left branch *)
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

let setup_stacks amt coins =
    (* Assumes that the that qty for each den in coins is greater than or equal to 2 *)
    let a = A.init (L.length coins) (fun _ -> (0,[], [], [])) in
    let rec aux count c = 
        match c with 
        | [] -> a
        | (den, qty)::rst -> begin 
            let new_amt = amt - den in 
            let new_c = (den, qty-1)::rst in
            if den > amt then 
                aux count (L.tl c)
            else if qty = 1 then begin
                a.(count) <- (new_amt, (L.tl c), (den::[]), [(new_amt, rst, den::[])]);
                aux (count+1) (L.tl c)
            end else begin
                a.(count) <- (new_amt, new_c, (den::[]), [(new_amt, rst, den::[])]);
                aux (count+1) (L.tl c) 
            end
    end 
    in
    aux 0 coins

let cc_par pool amt (coins : ((int * int) list)) arr = 
    let setup = setup_stacks amt coins in 
    let len   = A.length arr in
    let amt   = fun (x, _, _, _) -> x in 
    let c     = fun (_, x, _, _) -> x in
    let curr  = fun (_, _, x, _) -> x in
    let stack = fun (_, _, _, x) -> x in
    T.parallel_for pool ~start:0 ~finish:(len-1) ~body:(fun i ->
        Printf.printf "%d\n" i;
        arr.(i) <- des (amt setup.(i)) (c setup.(i)) (curr setup.(i)) [] (stack setup.(i));
    ) 

let coins_input : (int * int) list =
  let cs = [250 ; 100 ; 25 ; 10 ; 5 ; 1] in
  let qs = [55 ; 88 ; 88 ; 99 ; 122 ; 177] in
  L.combine cs qs

let arr = A.init (L.length coins_input) (fun _ -> [])

let _ = 
    let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) () in
    T.run pool (fun () -> cc_par pool n coins_input arr);
    Printf.printf "possibilites = %d\n" (A.fold_left (+) 0 (A.map L.length arr));
    T.teardown_pool pool
