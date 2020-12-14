let scale = try int_of_string Sys.argv.(1) with _ -> 12

let edgefactor = try int_of_string Sys.argv.(2) with _ -> 10

let startVertex = try int_of_string Sys.argv.(4) with _ -> 1

let num_domains = try int_of_string Sys.argv.(3) with _ -> 1

module T = Domainslib.Task

let rec findlst lst value col row root index = 
	if index = (row.(root+1)+1) then lst 
else
	if col.(index) = root then 
	findlst lst value col row root (index+1) else
	findlst ( (col.(index), value.(index)) :: lst) value col row root (index+1)

let rec sssp value col row visited queue distance pool prev_root parent = 
	match Lockfree.List.elem_of queue with
	[] -> () |
	(droot, root)::_ ->
		match Lockfree.List.sdelete queue (droot,root) compare with
		false -> Printf.printf "[FAULT IN DELETION]"; exit 0 |
		true ->
		(*Printf.printf "[ROOT] : %d\n" root;
		Printf.printf "Elements of Queue : ";*)
		parent.(root) <- prev_root;
		(*List.iter (fun (x,y) -> Printf.printf " %f , %d " x y) (Lockfree.List.elem_of queue);*)
		let lst = findlst [] value col row root (row.(root)) in 
		let ar = Array.of_list lst in
		(*if (Array.length ar) < 12 then 
			Printf.printf "%d \n" (Array.length ar);*)
		let dist = Atomic.get distance in
		(*Printf.printf "Adj List for Root : ";
		Array.iter (fun (x,y) -> Printf.printf "%d,%f " x y) ar;
		Printf.printf "Distance : ";
		Array.iter (fun i -> Printf.printf "%f " i) dist;*)
		T.parallel_for pool ~start:0 ~finish:(List.length lst - 1) 
		~body:(	fun i ->
				if visited.(fst ar.(i)) = 0 then 
						dist.(fst ar.(i)) <- min (dist.(fst ar.(i))) ( dist.(root) +. (snd ar.(i)) )
			else ()
		);
		(*Printf.printf "Updated Distance : ";
		Array.iter (fun(x) -> Printf.printf "%f " x ) dist;
		Printf.printf "\n";*)
		T.parallel_for pool ~start:0 ~finish:(List.length lst - 1) 
		~body:(	fun i -> 
				if visited.(fst ar.(i)) = 0 then
					match Lockfree.List.sinsert queue (dist.(fst ar.(i)), fst ar.(i)) compare with
						false, _ -> () |
						true, _ -> () (* Printf.printf "%d" (fst ar.(i)) *)
			else ()
		);
		(*Printf.printf "[QUEUE Elements at end] :  ";
		List.iter (fun (x,y) -> Printf.printf " %f,%d " x y) (Lockfree.List.elem_of queue);
		Printf.printf "\n";
		Printf.printf "\n";*)
		visited.(root) <- 1;
		sssp value col row visited queue distance pool root parent

let kernel3 () = 
  	let (value, col, row, n) = Kernel1_csr.linkKronecker () in
  	let visited = Array.make n (0) in
  	let parent = Array.make n (-1) in
  	let distance = Array.make n (infinity) in
  	distance.(startVertex) <- 0.;
	let queue = Lockfree.List.create () in
	match Lockfree.List.sinsert queue (0.,startVertex) compare with
	false , _ -> exit 0 |
	true,_ -> 
		let pool = T.setup_pool ~num_domains:(num_domains - 1) in
		let t = Unix.gettimeofday () in
		let _ = sssp value col row visited queue (Atomic.make distance) pool (-1) parent in
		let r = Unix.gettimeofday () in
		Printf.printf "\nSSSP: %f" (r -. t);
		(*Printf.printf "\nKERNEL3 TOTAL: %f\n" (r -. s);*)
		T.teardown_pool pool;
		Printf.printf "Distance Array is : ";
		let _ = Array.iter (fun i -> Printf.printf "%f " i) distance in
		Printf.printf "\n Parent Array is : ";
		let _ = Array.iter (fun i -> Printf.printf "%d " i) parent in
		distance,parent

let _ = kernel3 ()