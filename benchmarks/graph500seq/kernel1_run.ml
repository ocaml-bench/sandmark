let filename = ref ""

let () =
  Random.self_init ();
  Arg.parse [] (fun s -> filename := s)
    "kernel1Par.exe EDGE_LIST_FILE";
  if !filename = "" then begin
    Printf.eprintf "Must provide graph file argument.\n"; exit 1
  end;
  Printf.printf "Reading edge list from %s...\n%!" !filename;
  let t0 = Unix.gettimeofday () in
  let edges = GenerateSeq.from_file !filename in
  let t1 = Unix.gettimeofday () in
  Printf.printf "Done. Time: %f s.\nBuilding sparse representation...\n%!" (t1 -. t0);
  let t0 = Unix.gettimeofday () in
  ignore @@ Sys.opaque_identity @@ Kernel1Seq.kernel1 edges;
  let t1 = Unix.gettimeofday () in
  Printf.printf "Done. Time: %f\n" (t1 -. t0);
