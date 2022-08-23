let num_domains = ref 1
let filename = ref ""

let speclist =
  [ ("-ndomains", Arg.Set_int num_domains, "number of domains");
  ]

module T = Domainslib.Task

let () =
  Random.self_init ();
  Arg.parse speclist (fun s -> filename := s)
    "kernel1Par.exe [-ndomains NUM_DOMAINS] EDGE_LIST_FILE";
  if !filename = "" then begin
    Printf.eprintf "Must provide graph file argument.\n"; exit 1
  end;
  Printf.printf "Reading edge list from %s...\n%!" !filename;
  let t0 = Unix.gettimeofday () in
  let edges = Generate.from_file !filename in
  let t1 = Unix.gettimeofday () in
  Printf.printf "Done. Time: %f s.\nBuilding sparse representation...\n%!" (t1 -. t0);
  let pool = T.setup_pool ~num_additional_domains:(!num_domains-1) () in
  let t0 = Unix.gettimeofday () in
  ignore @@ Sys.opaque_identity @@ T.run pool (fun () ->
    Kernel1Par.kernel1 ~pool edges);
  let t1 = Unix.gettimeofday () in
  T.teardown_pool pool;
  Printf.printf "Done. Time: %f\n" (t1 -. t0);
