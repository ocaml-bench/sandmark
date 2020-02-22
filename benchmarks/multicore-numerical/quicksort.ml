let n = try int_of_string Sys.argv.(1) with _ -> 2000

let swap arr i j =
	let temp = arr.(i) in
	arr.(i) <- arr.(j);
	arr.(j) <- temp

let partition arr low high =
	let x = arr.(high) and  i = ref (low-1) in
	if (high-low > 0) then
	begin
		for j= low to high - 1 do
			if arr.(j) <= x then
			begin
				i := !i+1;
				swap arr !i j
			end
		done
    end;
    swap arr (!i+1) high;
    !i+1

let rec quicksort_o arr low high =
	match (high - low) <= 0 with
	| true  -> ()
	| false ->
		let q = partition arr low high in
		quicksort_o arr low (q-1);
		quicksort_o arr (q+1) high

let rec quicksort arr low high =
	match (high - low) <= 0 with
	| true  -> ()
	| false   ->
    let q = partition arr low high in
    quicksort_o arr low (q-1);
    quicksort_o arr (q+1) high

let () =
  let arr = Array.init n (fun _ -> Random.int n) in
	quicksort arr 0 (Array.length arr - 1);
	(* for i = 0 to  Array.length arr - 1 do
		print_int arr.(i);
    print_string "  "
  done; *)
	()


