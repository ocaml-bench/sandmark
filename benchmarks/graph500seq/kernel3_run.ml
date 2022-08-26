let usage_msg = "kernel3Seq_run.exe <sparse_graph_input_file> <samples_input_file"
let files = ref []

let () =
    Random.self_init ();
    Arg.parse [] (fun filename -> files := filename::!files) usage_msg;
    files := List.rev !files; 
    let sparse_graph_input_filename = List.nth !files 0 in
    let samples_input_filename = List.nth !files 1 in
    if sparse_graph_input_filename = "" then begin
        Printf.eprintf "Must provide sparse graph input file argument.\n"; exit 1
    end;
    if sparse_graph_input_filename = "" then begin
        Printf.eprintf "Must provide search keys input file argument.\n"; exit 1
    end;
    Printf.printf "Reading sparse graph from %s...\n%!" sparse_graph_input_filename;
    let graph = FileHandler.from_file sparse_graph_input_filename in
    Printf.printf "Reading search keys from from %s...\n%!" samples_input_filename;
    let samples = FileHandler.from_file samples_input_filename in
    Printf.printf "Performing single-source shortest path searches...\n%!";
    let t0 = Unix.gettimeofday () in
    ignore @@ Sys.opaque_identity @@ Array.map (fun start -> let g = graph in Kernel3Seq.kernel3 g start) samples;
    let t1 = Unix.gettimeofday () in
    Printf.printf "Done. Time: %f\n" (t1 -. t0);

