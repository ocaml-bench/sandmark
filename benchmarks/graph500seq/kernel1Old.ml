(*Kernel 1 is basic construction of adjacency HashMap for undirected graphs 
which is corresponding to sparse graph implementation. INPUTS : ijw and m which has been 
derived from kronecker product*)

(*(*<-------OCaml Kernel 1 inspired from https://graph500.org/?page_id=12---------->
Written by support of PRISM Lab, IIT Madras and OCaml Labs*)*)

let scale = try int_of_string Sys.argv.(1) with _ -> 12

let edgefactor = try int_of_string Sys.argv.(2) with _ -> 10

(*This basically sorts the list in a way that (startVertex, endVertex), 
startVertex > endVertex.
It removes the self loops from ijw*)
let sortVerticeList ar newAr index =
  let rec sortVerticeList ar maximum newAr index =
    if index = -1 then (newAr, int_of_float maximum)
    else if ar.(0).(index) > ar.(1).(index) then
      sortVerticeList ar
        (max maximum ar.(0).(index))
        (Array.append newAr
           [|[| ar.(0).(index); ar.(1).(index); ar.(2).(index) |]|])
        (index - 1)
    else if ar.(0).(index) = ar.(1).(index) then
      sortVerticeList ar (max maximum ar.(0).(index)) newAr (index - 1)
    else
      sortVerticeList ar
        (max maximum ar.(1).(index))
        (Array.append newAr
           [|[| ar.(1).(index); ar.(0).(index); ar.(2).(index) |]|])
        (index - 1)
  in
  sortVerticeList ar 0. newAr index

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
  if Hashtbl.mem hashTable startVertex = false then
    Hashtbl.add hashTable startVertex [ (endVertex, weight) ]
  else
    Hashtbl.replace hashTable startVertex
      (Hashtbl.find hashTable startVertex @ [ (endVertex, weight) ])

(*The two functions constructionAdjHash and kernel1 are the main 
functions driving all the other functions.*)
let rec constructionAdjHash ar hashTable index =
  if index = -1 then hashTable
  else
    let startVertex = int_of_float ar.(index).(0)
    and endVertex = int_of_float ar.(index).(1)
    and weight = ar.(index).(2) in
    addEdge startVertex endVertex weight hashTable;
    addEdge endVertex startVertex weight hashTable;
    constructionAdjHash ar hashTable (index - 1)

let rec adjustForAllVertices adjMatrix size index =
  if index = size then adjMatrix
  else if Hashtbl.mem adjMatrix index = true then
    adjustForAllVertices adjMatrix size (index + 1)
  else
    let _ = Hashtbl.add adjMatrix index [] in
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

let kernel1 ijw m =
  let ar, maximumEdgeLabel = sortVerticeList ijw [||] (m - 1) in
  let hashTable = Hashtbl.create (maximumEdgeLabel + 1) in
  let adjMatrix = constructionAdjHash ar hashTable ( Array.length ar - 1) in
  let adjMatrix = adjustForAllVertices adjMatrix (maximumEdgeLabel + 1) 0 in
  let _ = Printf.printf "%d" maximumEdgeLabel in
  (adjMatrix, maximumEdgeLabel + 1)

let linkKronecker () =
  let file = open_in "kronecker.txt" in
  let ijw = readFile file [||] in
  (*let _ = Array.map (Printf.printf "%f" ) ijw.(0) in*)
  let adjMatrix =
    kernel1 ijw (snd (computeNumber scale edgefactor))
  in
  adjMatrix
