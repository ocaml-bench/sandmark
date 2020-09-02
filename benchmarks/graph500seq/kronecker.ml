(*Kronecker is using the following algorithm : 
 Function Kronecker generator(scale, edgefactor) :
 	N = 2^scale
 	M = edgefactor * N (No of edges)
 	[A,B,C] = [0.57, 0.19, 0.19]
 	ijw = {	{1,1,1,1,1,...Mtimes};
 			{1,1,1,1,1...Mtimes};
 			{1,1,1,1,1...Mtimes};
 			}
 	ab = A + B;
  	c_norm = C/(1 - (A + B));
  	a_norm = A/(A + B);
  	for i in (0, scale) :
  		ii_bit = rand(1,M) > ab;
  		jj_bit = rand (1, M) > ( c_norm * ii_bit + a_norm * not (ii_bit) );(not a: a xor 0)
  		ijw(1:2,:) = ijw(1:2,:) + 2^(ib-1) * [ii_bit; jj_bit];
  	ijw(3,:) = unifrnd(0, 1, 1, M);//produce values from 0 to 1 for 1*M array.
  	
  	p = randperm (N);	
  	ijw(1:2,:) = p(ijw(1:2,:));
  	p = randperm (M);
  	ijw = ijw(:, p);
  	ijw(1:2,:) = ijw(1:2,:) - 1;
	Here, the labels are from 0 to N-1.
*)

(*(*<-------OCaml Kronecker Kernel inspired from https://graph500.org/?page_id=12---------->
Written by support of PRISM Lab, IIT Madras and OCaml Labs*)*)

let rec listGenerator1D list m =
  if m = 0 then list else listGenerator1D (0. :: list) (m - 1)

let rec listGenerator m list =
  if List.length list = 3 then list
  else listGenerator m (listGenerator1D [] m :: list)

let rec randomWghtGen len list =
  if len = 0 then list else randomWghtGen (len - 1) (Random.float 1. :: list)

let rec generateIIBitList list m ab =
  if List.length list = m then List.rev list
  else if Random.float (float_of_int m) > ab then
    generateIIBitList (1. :: list) m ab
  else generateIIBitList (0. :: list) m ab

let rec generateJJBitList list ii_bit m a_norm c_norm =
  match ii_bit with
  | [] -> List.rev list
  | head :: tail ->
      if
        Random.float (float_of_int m)
        > (c_norm *. head) +. (a_norm *. float_of_int (int_of_float head lxor 1))
      then generateJJBitList (1. :: list) tail m a_norm c_norm
      else generateJJBitList (0. :: list) tail m a_norm c_norm

let rec modifyRowIJW kk_list index list newList =
  match (kk_list, list) with
  | [], [] -> List.rev newList
  | _ :: _, [] -> []
  | [], _ :: _ -> []
  | headII :: tailII, headList :: tailList ->
      let element = headList +. ((2. ** float_of_int index) *. headII) in
      modifyRowIJW tailII index tailList (element :: newList)

let rec compareWithPr index m n ab a_norm c_norm ijw scale =
  if index = scale then ijw
  else
    let ii_bit = generateIIBitList [] m ab in
    let jj_bit = generateJJBitList [] ii_bit m a_norm c_norm in
    let firstRowIJW = modifyRowIJW ii_bit index (List.nth ijw 0) [] in
    let secondRowIJW = modifyRowIJW jj_bit index (List.nth ijw 1) [] in
    let ijw = [ firstRowIJW ] @ [ secondRowIJW ] @ [ List.nth ijw 2 ] in
    compareWithPr (index + 1) m n ab a_norm c_norm ijw scale

let permute list =
  let list = List.map (fun x -> (Random.bits (), x)) list in
  let list = List.sort compare list in
  List.map (fun x -> snd x) list

let rec transpose col list newList =
  if col = List.length (List.nth list 0) then newList
  else
    let rec adjustRow list newList col =
      match list with
      | [] -> List.rev newList
      | head :: tail -> adjustRow tail (List.nth head col :: newList) col
    in
    transpose (col + 1) list (newList @ [ adjustRow list [] col ])

let rec printList list =
  let _ = Printf.printf "\n" in
  match list with
  | [] -> Printf.printf "END"
  | head :: tail ->
      List.iter print_float head;
      printList tail

let computeNumber scale edgefactor =
  let n = int_of_float (2. ** float_of_int scale) in
  let m = edgefactor * n in
  (n, m)

let kronecker scale edgefactor =
  let n, m = computeNumber scale edgefactor in
  let a, b, c = (0.57, 0.19, 0.19) in
  let ijw = listGenerator m [] in
  (*For debugging*)
  let _ = printList ijw in
  let ab = a +. b in
  let c_norm = c /. (1. -. (a +. b)) in
  let a_norm = a /. (a +. b) in
  let ijw = compareWithPr 0 m n ab a_norm c_norm ijw scale in
  (*For debugging*)
  let _ = printList ijw in
  let thirdRow = randomWghtGen m [] in
  let ijw = [ List.nth ijw 0 ] @ [ List.nth ijw 1 ] @ [ thirdRow ] in
  let firstRowPermute = permute (List.nth ijw 0) in
  let secondRowPermute = permute (List.nth ijw 1) in
  let ijw = [ firstRowPermute ] @ [ secondRowPermute ] @ [ List.nth ijw 2 ] in
  (*For debugging*)
  let _ = printList ijw in
  let ijw = permute (transpose 0 ijw []) in
  let ijw = transpose 0 ijw [] in
  ijw
