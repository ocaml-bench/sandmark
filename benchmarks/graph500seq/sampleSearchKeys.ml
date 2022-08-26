(* Returns a list that contains all non-isolated vertices *)
let get_candidates g = 
    let glen = Array.length g in
    let rec aux count xs = 
        match (count = glen) with 
        | true -> xs
        | false -> begin 
            match g.(count) = [] with
            | true -> aux (count+1) xs
            | false -> aux (count+1) (count::xs)
        end
    in
    aux 0 []

(* Returns a list of n random vetices from the list of candidates *)
let extract_samples n candidates =
    let rec aux count cands xs = 
        match count with 
        | 0 -> xs 
        | _ -> begin 
            let sample = Random.full_int (List.length cands) in
            aux (count-1) (List.filter (fun x -> if x = sample then false else true) cands) ((List.nth cands sample)::xs)
        end
    in
    aux n candidates [] 

let get_samples n g = 
    let candidates = get_candidates (Array.mapi (fun i x -> if (SparseGraphSeq.has_selfloop i x) then [] else x) g) in
    let samples_list = extract_samples n candidates in
    Array.of_list samples_list

let usage_msg = "sampleSearchKeys.exe <sparse_graph_input_file> -o <sample_array_output_file"
let sparse_graph_input_filename = ref ""
let sample_array_output_filename = ref ""

let speclist = [("-o", Arg.Set_string sample_array_output_filename, "Set output file name")]

let () =
  Random.self_init ();
  Arg.parse speclist (fun s -> sparse_graph_input_filename := s) usage_msg;
  if !sparse_graph_input_filename = "" then begin
    Printf.eprintf "Must provide sparse graph input file as an argument.\n"; exit 1
  end;
  Printf.printf "Reading sparse graph from %s...\n%!" !sparse_graph_input_filename;
  let t0 = Unix.gettimeofday () in
  let g = FileHandler.from_file !sparse_graph_input_filename in
  let t1 = Unix.gettimeofday () in
  Printf.printf "Done. Time: %f s.\nGetting 64 samples search keys...\n%!" (t1 -. t0);
  let t0 = Unix.gettimeofday () in
  let sample_array = get_samples 64 g in
  let t1 = Unix.gettimeofday () in
  Printf.printf "Done. Time: %f\n" (t1 -. t0);
  FileHandler.to_file ~filename:!sample_array_output_filename sample_array;

(*open Base
let%test_unit "get_candidates_1" = 
    [%test_eq: int list list] (get_candidates [| [12]; [14]; []; [16] |]) [[16]; [14]; [12]] 

let%test_unit "get_candidates_2" = 
    [%test_eq: int list list] (get_candidates [| []; []; []; [] |]) []

let%test_unit "extract_samples_1" = 
    [%test_eq: int ] (Array.length (extract_samples 4 [1;2;3;4;5;6;7;8])) 4
    
let%test_unit "extract_samples_2" = 
    [%test_eq: bool] (( (extract_samples 2 [1;2;3])= [|1;2|]) || ((extract_samples 2 [1;2;3]) = [|1;3|]) || ((extract_samples 2 [1;2;3]) = [|2;1|]) || ((extract_samples 2 [1;2;3]) = [|2;3|]) || ((extract_samples 2 [1;2;3]) = [|3;1|]) || ((extract_samples 2 [1;2;3]) = [|3;2|]) )  true
*)
