let update_discovered d_arr v = 
    d_arr.(v) <- true

let set_parent par_arr ~parent ~child =
    par_arr.(child) <- parent

let get_bool_vect_val_at_index d_arr v = 
    d_arr.(v)

let is_discovered d_arr v = 
    get_bool_vect_val_at_index d_arr v

let next_edgenode g v = SparseGraphSeq.get_vertex @@ SparseGraphSeq.get_next_edgenode g v 

let has_no_edgenodes = SparseGraphSeq.has_no_edgenodes

let rec breadthfirstsearch (g : SparseGraphSeq.t) par_arr disc_arr (q : int Queue.t ) =
    match (Queue.is_empty q) with 
    | true -> par_arr
    | false -> 
        let v = Queue.peek q in
        match (has_no_edgenodes g v) with 
        | true -> let _ = Queue.pop q in breadthfirstsearch g par_arr disc_arr q 
        | false -> begin 
            let edgenode = next_edgenode g v in (* get the edgenode of v and change the state of g *)
            match (is_discovered disc_arr edgenode) with
            | true -> breadthfirstsearch g par_arr disc_arr q
            | false -> begin 
                Queue.push edgenode q;
                set_parent par_arr ~parent:v ~child:edgenode;
                update_discovered disc_arr edgenode;
                breadthfirstsearch g par_arr disc_arr q
            end
        end

let bfs g start = 
    let nvertices = SparseGraphSeq.num_vertices g in
    let parent_arr = Array.init nvertices (fun _ -> -1) in
    let discovery_arr = Array.init nvertices (fun _ -> false) in
    let q = ref (Queue.create ()) in
    Queue.push start !q;
    update_discovered discovery_arr start;
    let g_copy = SparseGraphSeq.copy_graph g in
    breadthfirstsearch g_copy parent_arr discovery_arr !q

let kernel2 = bfs



(*
(* Unit tests *)
let parray = Array.init 64 (fun _ -> -1)

open Base
let%test_unit "rev" = 
    [%test_eq: int list] [ 3; 2; 1 ] [ 3; 2; 1 ]

let%test_unit "update_discovered" = 
    let bvect = [| false; false; false |] in
    update_discovered bvect 0;
    [%test_eq: bool] bvect.(0) true


let%test_unit "set_parent" = 
    set_parent parray ~parent:8 ~child:2;
    [%test_eq: int] parray.(2) 8

let%test_unit "kernel2" = 
    [%test_eq: int array] (kernel2 SparseGraphSeq.graph 2) [|3;0;-1;2;2|]

let%test_unit "kernel2_2" = 
    [%test_eq: int array] (kernel2 SparseGraphSeq.graph2 8) [|-1;8;1;1;1;6;8;1;-1|]


*)
