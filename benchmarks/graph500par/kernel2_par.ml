let scale = try int_of_string Sys.argv.(1) with _ -> 12

let edgefactor = try int_of_string Sys.argv.(2) with _ -> 10

let startVertex = try int_of_string Sys.argv.(3) with _ -> 1

let num_domains = try int_of_string Sys.argv.(4) with _ -> 1

module T = Domainslib.Task

(*let rec printList lst = 
	match lst with
	[] -> None |
	hd::tl -> Printf.printf "%d" (fst hd); printList tl
*)

let rec findlst lst col row root index = 
	if index = (row.(root+1)+1) then lst 
else
	if col.(index) = root then 
	findlst lst col row root (index+1) else
	findlst (col.(index)::lst) col row root (index+1)

let rec bfs col row level queue pool = 
	if Lockfree.MSQueue.is_empty queue = true then ()
else
	match Lockfree.MSQueue.pop queue with
	None -> () |
	Some root -> 
		let lst = findlst [] col row root (row.(root)) in 
		Printf.printf "Root : %d\n" root;
		let _ = Array.iter (fun i -> Printf.printf "%d" i) level in
		Printf.printf "\n"; 
		let _ = List.iter (fun i -> Printf.printf "%d" i) lst in
		Printf.printf "\n";

		T.parallel_for pool ~start:0 ~finish:(List.length lst - 1) 
		~body:(	fun i -> 
				(*Printf.printf "INdex : %d " i;*)
				if level.(List.nth lst i) != (-1) then ()
						 else begin 
							(*Printf.printf "efjewfjef\n";*)
							level.(List.nth lst i) <- level.(root) + 1;
							(*Printf.printf "jk";*)
							Lockfree.MSQueue.push queue (List.nth lst i)
							end 
		);
		bfs col row level queue pool

let kernel2 () = 
  	let (_, col, row, n) = Kernel1_csr.linkKronecker () in
  	let s = Unix.gettimeofday () in
  	let level = Array.make n (-1) in
  	level.(startVertex) <- 0;
	let queue = Lockfree.MSQueue.create () in
	let _ = Lockfree.MSQueue.push queue startVertex in
	let pool = T.setup_pool ~num_domains:(num_domains - 1) in
	let t = Unix.gettimeofday () in
	let _ = bfs col row level queue pool in
	let r = Unix.gettimeofday () in
	Printf.printf "\nBFS: %f\n" (r -. t);
	Printf.printf "\nKERNEL2 TOTAL: %f\n" (r -. s);
	T.teardown_pool pool;
	let _ = Array.iter (fun i -> Printf.printf "%d" i) level in
	level

let _ = kernel2 ()