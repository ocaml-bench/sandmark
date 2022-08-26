open GraphTypes


type t = (vertex * weight) list array

let create ~max_vertex_label =
  assert (max_vertex_label <= 1 lsl 60); (* More than 2^60 vertices seems a bit
                                            much. *)
  Array.init (max_vertex_label + 1) (fun _ -> [])

let max_vertex_label g =
  Array.length g - 1

let add_edge (s,e,w) g =
  g.(s) <- (e,w) :: g.(s)

let from s g =
  g.(s)

let num_vertices g = 
    Array.length g

(* Takes a sparse graph g and a vertex v and returns the next edgenode 
   res in the edgenode list of v and changes the state of g with res removed
   from the edgenode list of v. *)
let get_next_edgenode g v =
    let res = List.hd g.(v) in
    let rest_edgelist = List.tl g.(v) in
    g.(v) <- rest_edgelist;
    res

let has_no_edgenodes g v = 
    g.(v) = []

let get_vertex edgenode = fst edgenode

let get_weight edgenode = snd edgenode

let rec has_selfloop v edgelist = 
    match (edgelist = []) with
    | true -> false
    | false -> begin
        let edgenode = List.hd edgelist in
        let rest = List.tl edgelist in
        match (get_vertex @@ edgenode = v) with
        | true -> true
        | false -> has_selfloop v rest
    end

let copy_graph g = 
    Array.copy g

let sample_vertex g =
        let v = Random.int (Array.length g) in
        let outgoing = g.(v) in
        if (outgoing <> []) && (not @@ has_selfloop v g.(v)) then 
            v 
        else 
            v

let print_edgelist el = 
    let rec aux str el = 
        match el with 
        | [] -> str ^ "NULL"
        | _ -> aux (str ^ (List.hd el |> fst |> string_of_int) ^ "->") (List.tl el)
    in 
    aux "" el

let print_sparse_graph g =
    for i = 0 to (Array.length g) -1 do
        print_endline ((string_of_int i) ^ ": " ^ (print_edgelist g.(i)));
    done

let print_vertex v = print_int v

let gr = [|
    [1;3];
    [0];
    [3;4];
    [0;2];
    [2]
|]

let gr2 = [|
    [];
    [2;3;7;4;8];
    [1;6];
    [1;7];
    [1];
    [6];
    [2;5;8];
    [1;3];
    [1;6];
|]

let graph = 
    Array.map 
        (fun x -> 
            List.map (fun y -> (y, 0.)) x
        ) 
    gr

let graph2 = 
    Array.map 
        (fun x -> 
            List.map (fun y -> (y, 0.)) x
        ) 
    gr2

let graph3 = [|
    [(1, 3.); (2, 1.)];
    [(0, 3.); (2, 7.); (4, 1.); (3, 5.)];
    [(1, 7.); (0, 1.); (3, 2.)];
    [(2, 2.); (1, 5.); (4, 7.)];
    [(1, 1.); (3,7.)]
|]

let graph4 = [|
    [(1, 5.); (2, 3.)];
    [(0, 5.); (2, 1.)];
    [(0, 3.); (1, 1.)];
|]

(*let graph5 = [|
    [(0, 3.); (2, 1.)];
    [(1, 3.); (2, 7.); (4, 1.); (3, 5.)];
    [(2, 7.); (0, 1.); (3, 2.)];
    [(3, 2.); (1, 5.); (4, 7.)];
    [(4, 1.); (3, 7.)]
|]*)


(*open Base
let%test_unit "has_selfloop_1" =
    [%test_eq: bool] (has_selfloop 2 [(1, 0.); (2, 0.)]) true 

let%test_unit "has_selfloop_2" = 
    [%test_eq: bool] (has_selfloop 3 [(0, 3.); (2, 7.); (4, 1.); (3, 5.)]) true


*)
