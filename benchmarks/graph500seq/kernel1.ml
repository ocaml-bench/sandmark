(*Kernel 1 is basic construction of adjacency HashMap for undirected graphs which is corresponding to sparse graph implementation. INPUTS : ijw and m which has been 
derived from kronecker product*)

(*(*<-------OCaml Kernel 1 inspired from https://graph500.org/?page_id=12---------->
Written by support of PRISM Lab, IIT Madras and OCaml Labs*)*)

(*This function helps in transpose of the list which has to be converted from (startVertex, endVertex, weight) in column to (startVertex, endVertex, weight) in 3 rows*)

let scale = int_of_string Sys.argv.(1)
let edgefactor = int_of_string Sys.argv.(2)

let rec transpose list col newList =
  if col = 3 then newList
  else
    let rec transposeRow row rowList =
      if row = List.length list then rowList
      else
        transposeRow (row + 1) (rowList @ [ List.nth (List.nth list row) col ])
    in
    transpose list (col + 1) (newList @ [ transposeRow 0 [] ])

(*This basically sorts the list in a way that (startVertex, endVertex), startVertex > endVertex.*)
let sortVerticeList list newList =
  let rec sortVerticeList list newList maximum =
    match list with
    | [] -> (newList, int_of_float maximum)
    | head :: tail ->
        let x = List.nth head 0 and y = List.nth head 1 in
        if x > y then
          sortVerticeList tail
            (newList @ [ [ x; y; List.nth head 2 ] ])
            (max maximum x)
        else
          sortVerticeList tail
            (newList @ [ [ y; x; List.nth head 2 ] ])
            (max maximum y)
  in
  sortVerticeList list newList 0.

(* As the name suggests, it removes the self loops from [ijw] *)
let rec removeSelfLoops ijw newList col m =
  if col = m then newList
  else if List.nth (List.nth ijw 0) col = List.nth (List.nth ijw 1) col then
    removeSelfLoops ijw newList (col + 1) m
  else
    removeSelfLoops ijw
      ( newList
      @ [
          [
            List.nth (List.nth ijw 0) col;
            List.nth (List.nth ijw 1) col;
            List.nth (List.nth ijw 2) col;
          ];
        ] )
      (col + 1) m

(*This is basically the construction of adj matrix [row][col], just in case dense graphs are being tested. All the kernels further though use HashMap, and thus would 
require changes*)

(*let constructionAdjMatrix list maxLabel = let matrix = Array.make_matrix
maxLabel maxLabel 0. in let rec fillMatrix matrix list = match list with [] ->
matrix | head::tail -> let _ = matrix.(int_of_float(List.nth head
0)).(int_of_float(List.nth head 1)) <- (List.nth head 2) in   let _ =
matrix.(int_of_float(List.nth head 1)).(int_of_float(List.nth head 0)) <-
(List.nth head 2) in fillMatrix matrix tail in fillMatrix matrix list ;;*)

(*Adding Edge adds the edge to HashMap for undirected graphs, where the binding is between index and the list (endVertex, weight) *)

let addEdge startVertex endVertex weight hashTable =
  if Hashtbl.mem hashTable startVertex = false then
    Hashtbl.add hashTable startVertex [ (endVertex, weight) ]
  else
    Hashtbl.replace hashTable startVertex
      (Hashtbl.find hashTable startVertex @ [ (endVertex, weight) ])

(*The two functions constructionAdjHash and kernel1 are the main functions driving all the other functions.*)
let rec constructionAdjHash list hashTable =
  match list with
  | [] -> hashTable
  | head :: tail ->
      let startVertex = int_of_float (List.nth head 0)
      and endVertex = int_of_float (List.nth head 1)
      and weight = List.nth head 2 in
      addEdge startVertex endVertex weight hashTable;
      addEdge endVertex startVertex weight hashTable;
      constructionAdjHash tail hashTable

let rec adjustForAllVertices adjMatrix size index =
  if index = size then adjMatrix
  else if Hashtbl.mem adjMatrix index = true then
    adjustForAllVertices adjMatrix size (index + 1)
  else
    let _ = Hashtbl.add adjMatrix index [] in
    adjustForAllVertices adjMatrix size (index + 1)

let kernel1 ijw m =
  let list = removeSelfLoops ijw [] 0 m in
  let list, maximumEdgeLabel = sortVerticeList list [] in
  let hashTable = Hashtbl.create (maximumEdgeLabel + 1) in
  let adjMatrix = constructionAdjHash list hashTable in
  let adjMatrix = adjustForAllVertices adjMatrix (maximumEdgeLabel + 1) 0 in
  (adjMatrix, maximumEdgeLabel + 1)

let linkKronecker () =
  let adjMatrix =
    kernel1 (Kronecker.kronecker scale edgefactor) (snd (Kronecker.computeNumber scale edgefactor))
  in
  adjMatrix
