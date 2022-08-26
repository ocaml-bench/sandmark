let is_intree intree v = 
    intree.(v)

let get_min_edgenode intree distance = 
    let nvertices = Array.length intree in
    let d = ref Float.infinity in
    let v = ref 0 in
    for i = 0 to (nvertices-1) do
        if ((not @@ is_intree intree i) && (!d > distance.(i))) then begin
            d := distance.(i);
            v := i;
        end
    done;
    (!v , !d)

let set_val_to_array_index arr index value = arr.(index) <- value

let set_vertex_intree intree v = set_val_to_array_index intree v true

let set_distance = set_val_to_array_index 

let set_parent = set_val_to_array_index

let get_next_edgenode = SparseGraphSeq.get_next_edgenode

let has_no_edgenodes = SparseGraphSeq.has_no_edgenodes

let is_tree_complete intree v = is_intree intree v

let is_shortest_dist_edge (distance : float array) src dest from_weight =
    distance.(dest) > (distance.(src) +. from_weight)

let rec run_dijkstra g v intree parents (distance : float array) =
    match (is_tree_complete intree v) with 
    | true -> (parents, distance)
    | false -> begin 
        match (has_no_edgenodes g v) with
        | true -> begin 
            set_vertex_intree intree v;
            let min_edge = get_min_edgenode intree distance in
            let w = fst min_edge in
            run_dijkstra g w intree parents distance
        end
        | false -> begin 
            let edgenode = get_next_edgenode g v in 
            let w = fst edgenode in
            let weight = snd edgenode in
            match (is_shortest_dist_edge distance v w weight) with
            | false -> run_dijkstra g v intree parents distance
            | true -> begin 
                    set_distance distance w (distance.(v) +. weight);
                    set_parent parents w v;
                    run_dijkstra g v intree parents distance
            end
        end
    end

let dijkstra g start = 
    let nvertices = SparseGraphSeq.num_vertices g in
    let distance = Array.init nvertices (fun _ -> Float.infinity) in
    set_distance distance start 0.;
    let intree = Array.init nvertices (fun _ -> false) in
    let parents = Array.init nvertices (fun _ -> -1) in
    set_parent parents start start;
    let g_copy = SparseGraphSeq.copy_graph g in
    run_dijkstra g_copy start intree parents distance 

let kernel3 g root =
    dijkstra g root

(*open Base
let%test_unit "kernel3_1" =
    [%test_eq: (int array) * (float array)] (kernel3 SparseGraphSeq.graph3 2) ([|2; 0; 2; 2; 1|], [|1.;4.;0.;2.;5.|]) 

let%test_unit "kernel3_2" =
    [%test_eq: (int array) * (float array)] (kernel3 SparseGraphSeq.graph4 5) ([|-1; -1; -1; -1; -1; 5; 7; 5 |], [|Float.infinity; Float.infinity; Float.infinity; Float.infinity; Float.infinity; 0.; 4.; 3.|]) 
*)

