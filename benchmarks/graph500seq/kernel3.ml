(*Kernel 3 works on the dijkstars algorithm which is basically the shortest path
  from the node to all the nodes. As expected the main function here takes the
  HashMap and  the source node from where the shortest distnaces have to be
  calculated.*)
(*INPUTS : Adjacency HashMap and Start Vertex*)

(*<-------OCaml Kernel 3 inspired from https://graph500.org/?page_id=12---------->
  Written by support of PRISM Lab, IIT Madras and OCaml Labs*)

(*Minimum Distance function computes the vertex which is at the min distance from the node 
which is currently under study. Only the nodes which have not been visited
  are only considered. This function is not checking the visited as the 
  verticesInspected already takes care of it in other function (changeVerticeInspected).
  E.g. N1 is under study and now the nodes N2, N3 are at 2, inf distance in distanceArray, 
  so N2 will be selected as the min vertex.*)

let startVertex = try int_of_string Sys.argv.(3) with _ -> 0

let minimumDistance verticesInspected distanceArray =
  let rec minimumDistance verticesInspected distanceArray minimumVal index
      minimumVertice =
    if index = Array.length verticesInspected then minimumVertice
    else if minimumVal >= distanceArray.(verticesInspected.(index)) then
      minimumDistance verticesInspected distanceArray
        distanceArray.(verticesInspected.(index))
        (index + 1) verticesInspected.(index)
    else
      minimumDistance verticesInspected distanceArray minimumVal (index + 1)
        minimumVertice
  in
  minimumDistance verticesInspected distanceArray infinity 0 0

(*After determining the min vertex (obtained from prev func), 
we have to adjust dist such that, for all node, 
if dist[node] > dist[min vertex] + weight_node_minVertex then update the distance 
else continue with other nodes. Parent Array is also updated here.*)

let rec adjustDistance vertex adjacentList distanceArray parentArray visited =
  match adjacentList with
  | [] -> (distanceArray, parentArray)
  | head :: tail ->
      if visited.(fst head) = 1 then
        adjustDistance vertex tail distanceArray parentArray visited
      else
        let adjvertex = fst head in
        if distanceArray.(adjvertex) < distanceArray.(vertex) +. snd head then
          adjustDistance vertex tail distanceArray parentArray visited
        else
          let _ = parentArray.(adjvertex) <- vertex in
          let _ =
            distanceArray.(adjvertex) <- distanceArray.(vertex) +. snd head
          in
          adjustDistance vertex tail distanceArray parentArray visited

(*This basically removes the nodes visited from the list verticesInspected*)

let rec changeVerticeInspected vertex (list : int list) (newList : int list) =
  match list with
  | [] -> Array.of_list newList
  | head :: tail ->
      if head = vertex then changeVerticeInspected vertex tail newList
      else changeVerticeInspected vertex tail (newList @ [ head ])

(*Dijkstra's algorithm which calculates the min vertex, then adjust the distance , 
update the visited list and iterate till all nodes have been inspected.*)
let rec dijkstraAlgorithm adjMatrix parentArray distanceArray verticesInspected
    visited =
  if Array.length verticesInspected = 0 then (distanceArray, parentArray)
  else
    let minVerticeId = minimumDistance verticesInspected distanceArray in
    let adjacentVerticeList = Hashtbl.find adjMatrix minVerticeId in
    let distanceArray, parentArray =
      adjustDistance minVerticeId adjacentVerticeList distanceArray parentArray
        visited
    in
    let verticesInspected =
      changeVerticeInspected minVerticeId (Array.to_list verticesInspected) []
    in
    let _ = visited.(minVerticeId) <- 1 in
    dijkstraAlgorithm adjMatrix parentArray distanceArray verticesInspected
      visited

let rec hashMapVerticeList adjMatrix list n index =
  if index = n then Array.of_list (List.rev list)
  else if Hashtbl.mem adjMatrix index = true then
    hashMapVerticeList adjMatrix (index :: list) n (index + 1)
  else hashMapVerticeList adjMatrix list n (index + 1)

(*ALl intialisation done in main function. Weights are float and vertices are int*)
let main adjMatrix startVertex n =
  let parentArray = Array.make n 0 in
  let distanceArray = Array.make n infinity in
  parentArray.(startVertex) <- startVertex;
  distanceArray.(startVertex) <- 0.;
  let verticesInspected = hashMapVerticeList adjMatrix [] n 0 in
  let visited = Array.make n 0 in
  let distanceArray, parentArray =
    dijkstraAlgorithm adjMatrix parentArray distanceArray verticesInspected
      visited
  in
  Printf.printf "\nDistance Array is : ";
  Array.iter (fun x -> Printf.printf "%f, " x) distanceArray;
  Printf.printf "\n Parent Array is : ";
  Array.iter (fun x -> Printf.printf "%d, " x) parentArray;
  Printf.printf "\n KERNEL3 OVER";
  (distanceArray, parentArray)

let linkKernel1 () =
  let ans = Kernel1Old.linkKronecker () in
  main (fst ans) startVertex (snd ans)


let _ = linkKernel1 ()
