open Domain

let swap arr i j = 
	let temp=arr.(i) in
	arr.(i)<-arr.(j);
	arr.(j)<-temp

let n = try int_of_string(Array.get Sys.argv 1) with _ ->  2000 

let num_domains = try int_of_string Sys.argv.(2) with _ -> 2

let partition arr low high = 
	let x = arr.(high) and  i =ref (low-1) in
	if (high-low > 0) then
	begin
		for j= low to (high-1) do
			if (arr.(j)<=x) then
			begin
				i:= !i+1;
				swap arr !i j
			end
		done 
    end;
    swap arr (!i+1) high;
    !i+1

let rec quicksort_o arr low high =
	match (high - low) <= 0 with
	| true  -> ()
	| false   ->
		let q = partition arr low high in
		quicksort_o arr low (q-1); 
		quicksort_o arr (q+1) high



let i = Atomic.make 0

let rec quicksort arr low high =
	match (high - low) <= 0 with
	| true  -> ()
	| false   ->
	if((Atomic.get i ) < num_domains) then
		begin
			Atomic.incr i;
			let q = partition arr low high in
			let f = Domain.spawn(fun () -> quicksort arr low (q-1))in
			quicksort arr (q+1) high;
			Domain.join f
		end
	else
		begin
			let q = partition arr low high in
			quicksort_o arr low (q-1) ;
			quicksort_o arr (q+1) high
		end

		   

let () =
	let arr=Array.make n 0 in
	for i=0 to (Array.length arr -1) do
		arr.(i)<- Random.int 1048576
	done;
	quicksort arr 0 (Array.length arr - 1);
	(* for i=0 to (Array.length arr -1) do
		print_int arr.(i);print_string "  ";
	done *)	
	()


