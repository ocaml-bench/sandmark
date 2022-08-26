let usage_msg = "kernel1Seq_run.exe <edge_list_input_file> -o <sparse_graph_output_file>"
let edge_list_input_filename = ref ""
let sparse_graph_output_filename = ref ""

let speclist = [("-o", Arg.Set_string sparse_graph_output_filename, "Set output file name")]

let () =
  Random.self_init ();
  Arg.parse speclist (fun s -> edge_list_input_filename := s) usage_msg;
  if !edge_list_input_filename = "" then begin
    Printf.eprintf "Must provide edge list input file argument.\n"; exit 1
  end;
  Printf.printf "Reading edge list from %s...\n%!" !edge_list_input_filename;
  let t0 = Unix.gettimeofday () in
  let edges = FileHandler.from_file !edge_list_input_filename in
  let t1 = Unix.gettimeofday () in
  Printf.printf "Done. Time: %f s.\nBuilding sparse representation...\n%!" (t1 -. t0);
  let t0 = Unix.gettimeofday () in
  let sparse_graph = Kernel1Seq.kernel1 edges in
  let t1 = Unix.gettimeofday () in
  Printf.printf "Done. Time: %f\n" (t1 -. t0);
  FileHandler.to_file ~filename:!sparse_graph_output_filename sparse_graph;

