let usage_msg = "kernel2Par_run.exe <sparse_graph_input_file> <samples_input_file> -ndomains <num_domains>"
let files = ref []
let num_domains = ref 2 

let speclist = [("-ndomains", Arg.Set_int num_domains, "Set the number of domains")]

module T = Domainslib.Task

let parellel_kernel2 pool graph samples res= 
    let len = Array.length res in
    T.parallel_for pool ~start:0 ~finish:(len-1) ~body:(fun i ->
        res.(i) <- (Kernel2Seq.kernel2 graph samples.(i))
    ) 


let () =
    Random.self_init ();
    Arg.parse speclist (fun filename -> files := filename::!files) usage_msg;
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
    let g = graph in
    Printf.printf "Reading search keys from from %s...\n%!" samples_input_filename;
    let samples = FileHandler.from_file samples_input_filename in
    Printf.printf "Performing breadth-first searches...\n%!";
    let pool = T.setup_pool ~num_additional_domains:(!num_domains-1) () in
    let t0 = Unix.gettimeofday () in
    let results = Array.init (Array.length samples) (fun _ -> [||]) in
    ignore @@ Sys.opaque_identity @@ T.run pool (fun () -> parellel_kernel2 pool g samples results);
    let t1 = Unix.gettimeofday () in
    Printf.printf "Done. Time: %f\n" (t1 -. t0);

