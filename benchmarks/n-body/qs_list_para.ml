open Domain

let id () = ()

let partition pivot l=
	let rec aux(left,pivot,right) =function
	| []->(left,pivot,right)
	|x::rest ->
	if x < pivot then aux (x::left, pivot, right) rest
	else aux (left, pivot, x::right) rest
in
aux ([], pivot, []) l



let rec quicksort l =
	match l with
	| []  -> l
	| _::[] -> l
	| pivot::rest ->
		let (left,pivot ,right) = partition pivot rest in
		quicksort left @ (pivot::quicksort right)

		
let i= ref 0

let  rec qsort arr   =
	match arr with
	| [] -> arr
	| _::[] -> arr
	| pivot:: rest->
		let (left, pivot, right)= partition pivot  rest in
		if (!i<8) then
		begin
			(* print_int !i;print_string "\n"; *)i:=!i+1; 
			let first = Domain.spawn  (  fun () -> (); qsort  left   ) in
			let second = Domain.spawn (  fun () -> (); qsort right   ) in
			let rl=join first in
			let rr=join second in
			rl @ (pivot::rr)
		end
		else
		(
			quicksort left @  (pivot::quicksort right);
		)	
	

let rec print_list = function 
[] -> print_string "\n" 
| e::l -> print_int e ; print_string "  " ; print_list l
	 

let () =
	let l=[91;62;83;34;55;46;27;19;4;8;56] in
	let r=qsort l in
	print_list r