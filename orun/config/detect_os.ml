module C = Configurator.V1

let is_linux () = 
  let ic = Unix.open_process_in "uname -s" in
  let uname = input_line ic in
  let () = close_in ic in
  match uname with
  | "Linux" -> true
  | _ -> false

let () =
C.main ~name:"detect_os" (fun c ->
let c_linker_flags = if is_linux () then
    ["-ldw"]
    else
    []
in
C.Flags.write_sexp "profiler_library_flags.sexp" c_linker_flags)