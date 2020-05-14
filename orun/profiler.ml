open Printf
open Common

external unpause_and_start_profiling :
  int -> Unix.file_descr -> (sample -> unit) -> unit
  = "ml_unpause_and_start_profiling"

exception ExpectedSome

let unwrap = function None -> raise ExpectedSome () | Some x -> x

let agg_hash = Hashtbl.create 1000

let update_line src_line self_time_inc total_time_inc =
  match Hashtbl.find_opt agg_hash src_line with
  | None ->
      Hashtbl.add agg_hash src_line {self_time= 1; total_time= 1}
  | Some x ->
      x.self_time <- x.self_time + self_time_inc ;
      x.total_time <- x.total_time + total_time_inc

let rec update_lines = function
  | [] ->
      ()
  | h :: t ->
      update_line h 0 1 ; update_lines t

let src_line_to_idx = Hashtbl.create 10000

let find_src_line_idx src_line =
  match Hashtbl.find_opt src_line_to_idx src_line with
  | None ->
      let new_idx = Hashtbl.length src_line_to_idx in
      Hashtbl.add src_line_to_idx src_line new_idx ;
      new_idx
  | Some x ->
      x

let samples_list = ref []

let sample_callback sample =
  (* increment self for the current source line *)
  update_line sample.current 1 1 ;
  update_lines sample.call_stack ;
  let new_stack = List.map (fun a -> find_src_line_idx a) sample.call_stack in
  let compressed_stack =
    { stack= find_src_line_idx sample.current :: List.rev new_stack
    ; thread_id= sample.thread_id
    ; cpu= sample.cpu
    ; timestamp= sample.timestamp
    ; id= sample.id }
  in
  samples_list := compressed_stack :: !samples_list

let start_profiling pid pipe_fd =
  unpause_and_start_profiling pid pipe_fd sample_callback ;
  agg_hash

let int_of_fd (x : Unix.file_descr) : int = Obj.magic x

let rec file_descr_not_standard (fd : Unix.file_descr) =
  if int_of_fd fd >= 3 then fd else file_descr_not_standard (Unix.dup fd)

let safe_close fd = try Unix.close fd with Unix.Unix_error (_, _, _) -> ()

let perform_redirections new_stdin new_stdout new_stderr =
  let new_stdin = file_descr_not_standard new_stdin in
  let new_stdout = file_descr_not_standard new_stdout in
  let new_stderr = file_descr_not_standard new_stderr in
  (*  The three dup2 close the original stdin, stdout, stderr,
      which are the descriptors possibly left open
      by file_descr_not_standard *)
  Unix.dup2 ~cloexec:false new_stdin Unix.stdin ;
  Unix.dup2 ~cloexec:false new_stdout Unix.stdout ;
  Unix.dup2 ~cloexec:false new_stderr Unix.stderr ;
  safe_close new_stdin ;
  safe_close new_stdout ;
  safe_close new_stderr

let rec wait_for_parent parent_ready =
  let read_fds, _write_fds, _exception_fds =
    Unix.select [parent_ready] [] [] (-1.0)
  in
  if List.mem parent_ready read_fds then () else wait_for_parent parent_ready

let create_process_env_paused cmd args env new_stdin new_stdout new_stderr =
  let parent_ready, parent_ready_write = Unix.pipe () in
  match Unix.fork () with
  | 0 -> (
    try
      perform_redirections new_stdin new_stdout new_stderr ;
      wait_for_parent parent_ready ;
      Unix.execvpe cmd args env
    with _ -> exit 127 )
  | id ->
      (id, parent_ready_write)

module StringMap = Map.Make (String)

module IntMap = Map.Make (struct
  type t = int

  let compare = Pervasives.compare
end)

let slash_regex = Str.regexp "[/\\.]"

let add_to_line_list src_line counts l =
  match l with
  | None ->
      Some [(src_line, counts)]
  | Some v ->
      Some ((src_line, counts) :: v)

let group_by_source_file src_line counts m =
  match src_line.filename with
  | None ->
      m
  | Some f ->
      StringMap.update f
        (function
          | None ->
              Some (IntMap.add src_line.line [(src_line, counts)] IntMap.empty)
          | Some l ->
              Some
                (IntMap.update src_line.line
                   (add_to_line_list src_line counts)
                   l) )
        m

let map_some f l =
  List.map
    (fun x -> f (unwrap x))
    (List.filter (function None -> false | Some _ -> true) l)

let source_line_counts_to_json (filename, function_name) (counts, lc) =
  `Assoc
    [ ("filename", `String filename)
    ; ("function", `String function_name)
    ; ("self_time", `Int counts.self_time)
    ; ("total_time", `Int counts.total_time)
    ; ( "line_counts"
      , `List
          ( match lc with
          | None ->
              []
          | Some line_counts ->
              List.map
                (fun (line, count) ->
                  `List [`Int line; `Int count.self_time; `Int count.total_time]
                  )
                (List.sort (fun (a, _) (b, _) -> a - b) line_counts) ) ) ]

let hotspots_to_json hotspots =
  `List (List.map (fun (k, v) -> source_line_counts_to_json k v) hotspots)

let group_by (f : 'a -> 'b) (ll : 'a list) : ('b, 'a list) Hashtbl.t =
  List.fold_left
    (fun acc e ->
      let grp = f e in
      let grp_mems = try Hashtbl.find acc grp with Not_found -> [] in
      Hashtbl.replace acc grp (e :: grp_mems) ;
      acc )
    (Hashtbl.create 100) ll

let fold_groups (f : 'b -> 'a list -> 'c) (g : ('b, 'a list) Hashtbl.t) :
    ('b, 'c) Hashtbl.t =
  Hashtbl.fold
    (fun a b m ->
      Hashtbl.add m a (f a b) ;
      m )
    g (Hashtbl.create 100)

let flatten h = Hashtbl.fold (fun a b c -> (a, b) :: c) h []

let group_by_fold (f : 'a -> 'b) (l : 'a list) (f2 : 'b -> 'a list -> 'c) :
    ('b * 'c) list =
  let grouped = group_by f l in
  flatten (fold_groups f2 grouped)

let write_profiling_result output_name (agg_result : aggregate_result) =
  (* first write out the json representation of results *)
  let total_samples =
    Hashtbl.fold (fun a b c -> c + b.self_time) agg_result 0
  in
  let key_values = flatten agg_result in
  let only_present_filenames =
    List.filter
      (function
        | {filename= None}, _ ->
            false
        | {filename= Some x}, _ ->
            Sys.file_exists x )
      key_values
  in
  (* calculate hotspots *)
  let grouped_by_file_function =
    group_by
      (fun (k, v) ->
        (get_or "unknown" k.filename, get_or "unknown" k.function_name) )
      key_values
  in
  let sum_counts l =
    List.fold_left
      (fun s (k, v) ->
        s.self_time <- s.self_time + v.self_time ;
        s.total_time <- s.total_time + v.total_time ;
        s )
      {self_time= 0; total_time= 0}
      l
  in
  let sum_counts_by_file_function =
    fold_groups (fun _ l -> sum_counts l) grouped_by_file_function
  in
  let sum_counts_by_line =
    fold_groups
      (fun _ l ->
        group_by_fold (fun (k, v) -> k.line) l (fun _ cs -> sum_counts cs) )
      grouped_by_file_function
  in
  let hottest_file_functions =
    take
      (List.sort
         (fun (k0, v0) (k1, v1) -> v1.self_time - v0.self_time)
         (flatten sum_counts_by_file_function))
      20
  in
  let hotspots =
    List.map
      (fun (ff, c) -> (ff, (c, Hashtbl.find_opt sum_counts_by_line ff)))
      hottest_file_functions
  in
  let profile_out = open_out_bin (output_name ^ ".prof.json") in
  let hotspots_json =
    `Assoc
      [ ("total_samples", `Int total_samples)
      ; ("hotspots", hotspots_to_json hotspots) ]
  in
  Yojson.Basic.to_channel profile_out hotspots_json ;
  close_out profile_out ;
  let dir_name = output_name ^ "_prof_results" in
  if not (Sys.file_exists dir_name) then Unix.mkdir dir_name 0o740 ;
  Reports.render_hotspots_html output_name hotspots total_samples ;
  Reports.render_trace_json output_name !samples_list src_line_to_idx
