(** Returns a list vertices of vertices that have at least one 
    out-going edge *)
let get_sinks g = 
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

(** Returns a list of n random vetices from the list of sinks *)
let extract_samples n sinks =
    let rec aux count cands xs = 
        match count with 
        | 0 -> xs 
        | _ -> begin 
            let sample = Random.full_int (List.length cands) in
            aux (count-1) (List.filter (fun x -> if x = sample then false else true) cands) ((List.nth cands sample)::xs)
        end
    in
    aux n sinks [] 

(** Returns an array of n samples from g that don't contain 
    self-loops *)
let get_samples n g = 
    let sinks = get_sinks (Array.mapi (fun i x -> if (SparseGraphSeq.has_selfloop i x) then [] else x) g) in
    let samples_list = extract_samples n sinks in
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
