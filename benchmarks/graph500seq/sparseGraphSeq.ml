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
