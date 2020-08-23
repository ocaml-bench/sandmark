type wait4_result =
  { status: Unix.process_status
  ; user_secs: float
  ; sys_secs: float
  ; maxrss_kB: int }

external wait4 : int -> wait4_result = "ml_wait4"

let escape_re = Str.regexp "\\(\027\\[[0-9:;]*m\\)*"

let clean_escape_sequences line = Str.global_replace escape_re "" line

let escape_sequences_only line =
  let _ = Str.search_forward escape_re line 0 in
  Str.matched_string line

let quotes_needed = function
  | 'a' .. 'z'
  | 'A' .. 'Z'
  | '0' .. '9'
  | '/'
  | '_'
  | '.'
  | ','
  | '-'
  | '+'
  | ':' ->
      false
  | _ ->
      true

let quote s =
  match String.iter (fun ch -> if quotes_needed ch then raise Exit) s with
  | () ->
      s
  | exception Exit ->
      Filename.quote s

let quote_cmd cmdline = String.concat " " (List.map quote cmdline)

let starts_with s line =
  String.length line >= String.length s
  && s = String.sub line 0 (String.length s)

let break ch s =
  let open String in
  let i = index s ch in
  (trim (sub s 0 i), trim (sub s (i + 1) (String.length s - (i + 1))))

let chop_prefix pfx s =
  assert (starts_with pfx s);
  String.sub s (String.length pfx) (String.length s - String.length pfx)

let get_ocaml_config () =
  let ic = Unix.open_process_in "ocamlc -config" in
  let boring = function
    | "standard_library_default"
    | "standard_library"
    | "standard_runtime"
    | "ext_exe"
    | "ext_obj"
    | "ext_asm"
    | "ext_lib"
    | "ext_dll"
    | "asm_cfi_supported"
    | "exec_magic_number"
    | "cmi_magic_number"
    | "cmo_magic_number"
    | "cma_magic_number"
    | "cmx_magic_number"
    | "cmxa_magic_number"
    | "ast_impl_magic_number"
    | "ast_intf_magic_number"
    | "cmxs_magic_number"
    | "cmt_magic_number"
    | "ranlib"
    | "asm"
    | "ccomp_type"
    | "cc_profile"
    | "default_executable_name"
    | "bytecomp_c_libraries"
    | "native_c_libraries"
    | "native_pack_linker"
    | "profiling"
    | "host" (* arch info available elsewhere *)
    | "os_type" (* already have more specific "system" *)
    | "target"
    | "int_size" (* we keep word_size *)
    | "safe_string"
    | "default_safe_string"
    | "systhread_supported"
    | "ocamlc_cflags"
    | "ocamlc_cppflags"
    | "ocamlopt_cflags"
    | "ocamlopt_cppflags"
    | "bytecomp_c_compiler"
    | "native_c_compiler" ->
        true
    | _ ->
        false
  in
  let default_val = function
    | "model" ->
        Some "default"
    | "flambda" ->
        Some "false"
    | "spacetime" ->
        Some "false"
    | "flat_float_array" ->
        Some "true"
    | "afl_instrument" ->
        Some "false"
    | "windows_unicode" ->
        Some "false"
    | "with_frame_pointers" ->
        Some "false"
    | _ ->
        None
  in
  let rec go () =
    match input_line ic with
    | exception End_of_file ->
        []
    | s ->
        let key, value = break ':' s in
        if boring key || default_val key = Some value then go ()
        else (key, `String value) :: go ()
  in
  `Assoc (go ())

let gc_stats stderr_file =
  let ic = open_in stderr_file in
  let rec go found_stats =
    match (found_stats, input_line ic) with
    | exception End_of_file ->
        close_in ic ; []
    | false, line
      when not (starts_with "allocated_words: " (clean_escape_sequences line))
      ->
        prerr_endline line ; go false
    | _, line -> (
        (* There may be some escape characters which need printing on allocated_words *)
        prerr_string (escape_sequences_only line) ;
        let line = clean_escape_sequences line in
        let key, value = break ':' line in
        match key with
        | "mean_space_overhead" ->
            let value = float_of_string value in
            (key, `Float value) :: go true
        | _ ->
            let value = int_of_string value in
            (key, `Int value) :: go true )
  in
  `Assoc (go false)

let re = Re.Perl.compile_pat "caml[A-Z].*"

let is_interesting_symbol name =
  Base.List.exists [ "caml_curry"; "caml_tuplify"; "caml_apply" ]
    ~f:(fun prefix -> Base.String.is_prefix ~prefix name)
    || ( Re.execp re name
     && not (Base.String.is_prefix ~prefix:"camlCompiler_bench_runtime" name))

let read_process_lines command =
  let lines = ref [] in
  let in_channel = Unix.open_process_in command in
  begin
    try
      while true do
        lines := Stdio.In_channel.input_line_exn in_channel :: !lines
      done;
    with End_of_file ->
      ignore (Unix.close_process_in in_channel)
  end;
List.rev !lines

let get_benchmark_exe output cmdline =
  let cwd = Sys.getcwd () in
  let re_exe = Re.Perl.compile_pat ".exe$|setrip|cpdf|minilight-ocaml|frama-c|js_of_ocaml|alt-ergo|menhir|cubicle|coqc" in
  let bench = List.find_opt (Re.execp re_exe) cmdline in
  match bench with
  | None -> ""
  | Some x ->
     let exe = Str.replace_first (Str.regexp "^./") "" x in
     Base.String.concat ~sep:"/" [cwd; exe]

let get_codesize output cmdline =
  let file = get_benchmark_exe output cmdline in
  match file with
  | "" -> 0.0
  | _ ->
    let command = Base.String.concat ~sep:" " ["/usr/bin/nm"; "--format=bsd";
                                            "--debug-syms"; "--radix=d";
                                            "--print-size"; file] in
    let lines = read_process_lines command in
    Base.List.fold lines ~init:0 ~f:(fun total line ->
      if not (Base.String.is_prefix ~prefix:" " line)
       then (
         match Base.String.split ~on:' ' line with
         | [ _sym_addr; sym_size; (("t" | "T") as _sym_type); sym_name ]
           when is_interesting_symbol sym_name ->
           (match total + Base.Int.of_string sym_size with
            | exception Failure _ -> total
            | v -> v)
         | _ -> total)
       else total)
     |> Float.of_int

let run output input cmdline =
  let prog = List.hd cmdline in
  (* workaround for the lack of execve *)
  let prog =
    if Filename.is_implicit prog && Sys.file_exists prog then "./" ^ prog
    else prog
  in
  try
    let profiling =
      match Sys.getenv_opt "ORUN_CONFIG_PROFILE" with
      | None ->
          false
      | Some _ ->
          true
    in
    let exec_prog output_name prog cmdline env stdin stdout stderr =
      if profiling then (
        let pid, parent_ready =
          Profiler.create_process_env_paused prog cmdline env stdin stdout
            stderr
        in
        let result = Profiler.start_profiling pid parent_ready in
        Profiler.write_profiling_result output_name result ;
        pid )
      else Unix.create_process_env prog cmdline env stdin stdout stderr
    in
    let before = Unix.gettimeofday () in
    let captured_stderr_filename = Filename.temp_file "orun" "stderr" in
    let stderr_fd =
      Unix.openfile captured_stderr_filename [Unix.O_WRONLY] 0600
    in
    let process_stdin =
      match input with
      | Some stdin_file ->
          Unix.openfile stdin_file [] 0600
      | None ->
          Unix.stdin
    in
    let strip_suffix fname suffix =
      if Filename.check_suffix fname suffix then
        Filename.chop_suffix fname suffix
      else fname
    in
    let strip_prefix s prefix =
      if starts_with prefix s then
        chop_prefix prefix s
      else s
    in
    let name = strip_suffix (Filename.basename output) ".bench" in
    let name = strip_suffix name ".orun" in
    let ocamlrunparam =
      let params =
        match List.filter
                (fun s -> starts_with "OCAMLRUNPARAM=" s)
                (Array.to_list (Unix.environment ()))
        with
        | [] -> "v=0x400" (* print stats at termination *)
        | x::_ ->
            let params = strip_prefix x "OCAMLRUNPARAM=" in
            if params = "" then "v=0x400"
            else params ^ ",v=0x400"
      in
      "OCAMLRUNPARAM=" ^ params
    in
    let environ =
      ocamlrunparam
      :: "OCAML_EVENTLOG_ENABLED=1" (* enable tracing on eventlog branches *)
      :: Printf.sprintf "OCAML_EVENTLOG_FILE=%s.trace" name
      :: List.filter
           (fun s -> not (starts_with "OCAMLRUNPARAM=" s))
           (Array.to_list (Unix.environment ()))
    in
    let pid =
      exec_prog name prog (Array.of_list cmdline) (Array.of_list environ)
        process_stdin Unix.stdout stderr_fd
    in
    Unix.close stderr_fd ;
    let {status; user_secs; sys_secs; maxrss_kB} = wait4 pid in
    let status =
      match status with
      (* hack because Unix.create_process has terrible error handling :( *)
      | WEXITED 127 ->
          raise (Unix.Unix_error (Unix.ENOENT, "exec", prog))
      | WEXITED n ->
          n
      | WSTOPPED _ ->
          failwith "WSTOPPED but not WUNTRACED?"
      | WSIGNALED s ->
          Unix.kill (Unix.getpid ()) s ;
          assert false
    in
    let after = Unix.gettimeofday () in
    let codesize = get_codesize output cmdline in
    let stats =
      [ ("name", `String name)
      ; ("command", `String (quote_cmd cmdline))
      ; ("time_secs", `Float (after -. before))
      ; ("user_time_secs", `Float user_secs)
      ; ("sys_time_secs", `Float sys_secs)
      ; ("maxrss_kB", `Int maxrss_kB)
      ; ("ocaml", get_ocaml_config ())
      ; ("gc", gc_stats captured_stderr_filename)
      ; ("codesize", `Float codesize)]
    in
    let extra_config =
      Unix.environment () |> Array.to_list
      |> List.filter (starts_with "ORUN_CONFIG_")
      |> List.map (fun s ->
             let k, v = break '=' s in
             (chop_prefix "ORUN_CONFIG_" k, `String v) )
    in
    let stats = `Assoc (stats @ extra_config) in
    Sys.remove captured_stderr_filename ;
    let oc = if output = "" then stderr else open_out output in
    Yojson.Basic.to_channel oc stats ;
    output_string oc "\n" ;
    close_out oc ;
    status
  with Unix.Unix_error (err, fn, arg) ->
    Printf.fprintf stderr "%s: %s\n%!" (Unix.error_message err)
      (if arg = "" then fn else arg) ;
    exit 127

open Cmdliner

let output =
  let doc = "Output location for run statistics file (if omitted then will print to stderr)" in
  Arg.(value & opt string "" & info ["o"; "output"] ~docv:"FILE" ~doc)

let input =
  let doc = "Optional file to use as stdin" in
  Arg.(value & opt (some string) None & info ["i"; "input"] ~docv:"FILE" ~doc)

let target = Arg.(non_empty & pos_all string [] & info [] ~docv:"PROG")

let prog =
  let info =
    let doc = "run an OCaml program, measuring its runtime and memory use" in
    let man = [] in
    Term.info "orun" ~version:"v0.1" ~doc ~man
  in
  (Term.(const run $ output $ input $ target), info)

let () = Term.exit_status (Term.eval prog)
