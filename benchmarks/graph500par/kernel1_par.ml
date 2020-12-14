(*Kernel 1 is basic construction of adjacency HashMap for undirected graphs 
which is corresponding to sparse graph implementation. INPUTS : ijw and m which has been 
derived from kronecker product*)

(*(*<-------OCaml Kernel 1 inspired from https://graph500.org/?page_id=12---------->
Written by support of PRISM Lab, IIT Madras and OCaml Labs*)*)

let scale = try int_of_string Sys.argv.(1) with _ -> 12

let edgefactor = try int_of_string Sys.argv.(2) with _ -> 10

let num_domains = try int_of_string Sys.argv.(3) with _ -> 1

module T = Domainslib.Task

(*This basically sorts the list in a way that (startVertex, endVertex), 
startVertex > endVertex.
It removes the self loops from ijw*)
let sortVerticeList ar index =
  let rec sortVerticeList ar maximum index =
    if index = -1 then (int_of_float maximum)
    else if ar.(0).(index) > ar.(1).(index) then
      sortVerticeList ar
        (max maximum ar.(0).(index)) (index-1)
    else
      let temp = ar.(0).(index) in
      ar.(0).(index) <- ar.(1).(index);
      ar.(1).(index) <- temp;
      sortVerticeList ar
        (max maximum ar.(0).(index))
        (index - 1)
  in
  sortVerticeList ar 0. index

(*This is basically the construction of adj matrix [row][col], 
just in case dense graphs are being tested. All the kernels further though 
use HashMap, and thus would require changes*)

(*let constructionAdjMatrix list maxLabel = let matrix = Array.make_matrix
maxLabel maxLabel 0. in let rec fillMatrix matrix list = match list with [] ->
matrix | head::tail -> let _ = matrix.(int_of_float(List.nth head
0)).(int_of_float(List.nth head 1)) <- (List.nth head 2) in   let _ =
matrix.(int_of_float(List.nth head 1)).(int_of_float(List.nth head 0)) <-
(List.nth head 2) in fillMatrix matrix tail in fillMatrix matrix list ;;*)

(*Adding Edge adds the edge to HashMap for undirected graphs, where the binding 
is between index and the list (endVertex, weight) *)

let addEdge startVertex endVertex weight hashTable =
    match Lockfree.Hash.find hashTable startVertex with 
    None ->  Lockfree.Hash.add hashTable startVertex [(endVertex, weight)] |
    Some l -> (*List.iter (fun (x,y) -> Printf.printf "%d,%f " x y) l;*)
              (*Printf.printf "[ENDVERTEX, WGHT]\n %d,%d,%f \n"  startVertex endVertex weight;*)
              Lockfree.Hash.add hashTable startVertex ((endVertex, weight) :: l)

(*The two functions constructionAdjHash and kernel1 are the main 
functions driving all the other functions.*)
let rec constructionAdjHash ar hashTable i index higher =
  if index = higher + 1 then ()
else
    let startVertex = int_of_float ar.(0).(index)
    and endVertex = int_of_float ar.(1).(index)
    and weight = ar.(2).(index) in
    if startVertex = endVertex then constructionAdjHash ar hashTable i (index+1) higher
  else
    let _ = addEdge startVertex endVertex weight hashTable in
    let _ = addEdge endVertex startVertex weight hashTable in
    constructionAdjHash ar hashTable i (index + 1) higher

(*let rec find_all adjMatrix index hashTable = 
  if Lockfree.Hash.mem adjMatrix index = false then Lockfree.Hash.find hashTable index
else if Lockfree.Hash.mem hashTable index = true then begin
Lockfree.Hash.add hashTable index (Lockfree.Hash.find hashTable index @[ [(Lockfree.Hash.find adjMatrix index)]]);
if Lockfree.Hash.remove adjMatrix index = true then find_all adjMatrix index hashTable 
else exit 0; end
else begin Lockfree.Hash.add hashTable index ([ [(Lockfree.Hash.find adjMatrix index)]]);
if Lockfree.Hash.remove adjMatrix index = true then find_all adjMatrix index hashTable
else exit 0; end*) 

let rec adjustForAllVertices adjMatrix size index =
  if index = size then ()
  else if Lockfree.Hash.mem adjMatrix index = true then
    adjustForAllVertices adjMatrix size (index + 1)
  else
    let _ = Lockfree.Hash.add adjMatrix index [] in
    adjustForAllVertices adjMatrix size (index + 1)

let rec readFile file ijw =
  try
    match Some (input_line file) with
    | None -> ijw
    | Some line -> (
        match List.rev (String.split_on_char ',' line) with
        | [] -> readFile file ijw
        | _ :: tail ->
            let list =
              Array.of_list (List.map float_of_string (List.rev tail))
            in
            let ijw = Array.append ijw [| list |] in
            readFile file ijw )
  with End_of_file ->
    let _ = close_in file in
    ijw

let computeNumber scale edgefactor =
  let n = int_of_float (2. ** float_of_int scale) in
  let m = edgefactor * n in
  (n, m)

let printArray ijw = 
  Array.iter (fun x -> Printf.printf "%f" x) ijw.(0);
  Printf.printf "\n";
   Array.iter (fun x -> Printf.printf "%f" x) ijw.(1)

let kernel1 ijw m pool =
  let s = Unix.gettimeofday () in
  let maximumEdgeLabel = sortVerticeList ijw (m - 1) in
  let hashTable = Lockfree.Hash.create () in
  let temp = (Array.length (ijw.(0)) )/num_domains in
  let start = Unix.gettimeofday  () in
  T.parallel_for pool ~start:0 ~finish:(num_domains-1)
    ~body:(fun i -> if i=(num_domains-1) then 
     constructionAdjHash ijw hashTable i (i*temp) ( (Array.length ijw.(0)) - 1)
    else constructionAdjHash ijw hashTable i (i*temp) (i*temp + temp-1));
  let _ = T.teardown_pool pool in
  (*let _ = Printf.printf "Two\n" in*) 
  
  let stop = Unix.gettimeofday () in
  let _  =Printf.printf "POOL Exec : %f\n" (stop -. start) in
  let _  =Printf.printf "SORT + POOL Exec : %f\n" (stop -. s) in
  (*let _ = Printf.printf "Three\n" in*)
  let _ = adjustForAllVertices hashTable (maximumEdgeLabel + 1) 0 in
  let t = Unix.gettimeofday () in
  let _  =Printf.printf "ADJUST FOR ALL Exec : %f\n" (  t -. stop) in
  let _ = Printf.printf "%d" maximumEdgeLabel in
  (hashTable, maximumEdgeLabel + 1)

let rec printx l = 
  match l with
  [] -> None |
  head::tail -> 
  let _ = Printf.printf "First : %d\n" (fst head) in
  let _ = Printf.printf "First : %f\n" (snd head) in 
  printx tail

let rec printList lst = 
  match lst with
  [] -> None |
  hd::tl -> let _ = List.iter (fun (x,_) -> Printf.printf "%d" x) (hd) in
            let _ = Printf.printf "\n" in
            printList tl

let linkKronecker () =
  (*let s = Unix.gettimeofday () in *)
  let file = open_in "kronecker.txt" in
  let ijw = readFile file [||] in
  (*let r = Unix.gettimeofday () in*)
  let pool = T.setup_pool ~num_domains:(num_domains - 1) in
  let (adjMatrix,number) =
    kernel1 ijw (snd (computeNumber scale edgefactor)) pool
  in
  (*let t = Unix.gettimeofday () in
  Printf.printf "\nKERNEL1 BEFORE ADJMATRIX: %f\n" (r -. s);
  Printf.printf "\nKERNEL1 : %f\n" (t -. s);
  Printf.printf "\nADJMATRIX: %f\n" (t -. r);
  Printf.printf "KERNEL1 END--->\n\n";*)
  (*let lst = Lockfree.Hash.elem_of adjMatrix in
  let _ = printList lst in*)
  (*match Lockfree.Hash.find adjMatrix 1 with 
  None -> exit 0; |
  Some l ->  
  let _ = Printf.printf "\nLen : %d\n" (List.length l) in
  let _ = printx l in*)
  adjMatrix,number