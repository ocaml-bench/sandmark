(*Kernel 2 aims at building a bfs tree where the bfs is maintained using a queue
  and the parent Array which consists of the immediate parent of the node.  The
  input for this kernel is :  INPUTS : adjacency HashMap(for undirected graphs)
  and starting vertex which would allow you to begin the bfs*)

(*<-------OCaml Kernel 2 inspired from https://graph500.org/?page_id=12---------->
  Written by support of PRISM Lab, IIT Madras and OCaml Labs*)

(*This function iterates over the list which are adjacent to the node. 
So lets say for node n1, we have n2,n3,n4 nodes. THe list would be in 
the form of (node,wght) tuple inside the list 
i.e. [(n2,weight_21);(n3,weight_31);(n4,weight_41)] which is 
adjacentVertice list. Parent array will be updated here. Queue is just a 
list module.
  Also, visited array has the nodes which have already being visited to avoid 
  the nodes being pushed to queue which have been visited in order to avoid redundancy.*)

(*appendVerticesToQueue is the function doing recusrion to push desired elements 
in the queue, adjacent and ~visited nodes for a node. THe queue's first element
  is always the node to be computed on for adjacency. As queue pushs the node 
  from front, head::tail helps directly, primrily pointing out that queue 
  has been considered as a list.*)

let rec appendVerticesToQueue parentVertex queue adjacentVertices
    (parentArray : int array) visited =
  match adjacentVertices with
  | [] -> (queue, parentArray)
  | head :: tail ->
      if visited.(fst head) = 0 then
        let _ = parentArray.(fst head) <- parentVertex in
        appendVerticesToQueue parentVertex
          (queue @ [ fst head ])
          tail parentArray visited
      else appendVerticesToQueue parentVertex queue tail parentArray visited

(*For debugging*)
(*let rec printList list = 
  	match list with
  	[] -> Printf.printf "Empty/END" |
  	head::tail -> let _ = Printf.printf "%d" head in printList tail
  ;;*)

(*BFS function is a normal bfs function by building the bfs tree. 
Uses adjacency HashMap, queue, parent Array, visited. 
bfsTree stores the order of the nodes and 
  it is a list. Parent array works as : parent[node] = _parentNode_ 
  is the DAT being used i.e. an array*)

let rec bfs adjMatrix queue bfsTree parentArray visited =
  match queue with
  | [] -> (bfsTree, parentArray)
  | head :: tail ->
      if visited.(head) = 0 then
        let _ = visited.(head) <- 1 in
        let adjacentVertices = Hashtbl.find adjMatrix head in
        let queue, parentArray =
          appendVerticesToQueue head tail adjacentVertices parentArray visited
        in
        (*let _ = printList queue in*)
        (*For debugging*)
        let _ = Hashtbl.remove adjMatrix head in
        bfs adjMatrix queue (bfsTree @ [ head ]) parentArray visited
      else bfs adjMatrix tail bfsTree parentArray visited

(*Main function is the function where it calls bfs. 
Size computation is using HashMap and the initialiszation 
of all arrays and lists happen here.*)

let rec bfsRecDisconnectedGraph adjMatrix bfsTree parentArray visited index =
  if index = Array.length visited then (bfsTree, parentArray)
  else if parentArray.(index) = -1 && visited.(index) = 0 then
    let bfsTree, parentArray =
      bfs adjMatrix [ index ] bfsTree parentArray visited
    in
    bfsRecDisconnectedGraph adjMatrix bfsTree parentArray visited (index + 1)
  else bfsRecDisconnectedGraph adjMatrix bfsTree parentArray visited (index + 1)

let main adjMatrixHash n =
  let len = n in
  let _  = Printf.printf "%d\n" len in 
  let parentArray = Array.make len (-1) in
  let visited = Array.make len 0 in
  let bfsTree, parentArray =
    bfsRecDisconnectedGraph adjMatrixHash [] parentArray visited 0
  in
  Printf.printf "\nBfs Tree is : ";
  List.iter (fun x -> Printf.printf "%d " x) bfsTree;
  Printf.printf "\n Parent Array is : ";
  Array.iter (fun x -> Printf.printf "%d " x) parentArray;
  Printf.printf "\n KERNEL2 OVER";
  (bfsTree, parentArray)

let linkKernel1 () =
  let ans = Kernel1Old.linkKronecker () in
  main (fst ans) (snd ans)

let _ = linkKernel1 ()
