open Lwt

let pred = function
  | 0 -> 502
  | n -> pred n

let succ = function
  | 502 -> 0
  | n -> succ n

let make_th streams n id =
  let rec do_n_times = function
    | 0 -> Lwt.return_unit
    | n ->
      Lwt_stream.next @@ fst streams.(pred id) >>= fun () ->
      snd streams.(succ id) @@ Some ();
      do_n_times (pred n)
  in
  do_n_times n

let main n =
  let streams = Array.init 503 (fun _ -> Lwt_stream.create ()) in
  let ths = Array.init 503 @@ make_th streams n in
  snd streams.(0) @@ Some ();
  ths.(502)

let () =
  let n = if Array.length Sys.argv > 1 then int_of_string Sys.argv.(1) else 50000
  in Lwt_main.run @@ main n

let () =
  try
    let fn = Sys.getenv "OCAML_GC_STATS" in
    let oc = open_out fn in
    Gc.print_stat oc
  with _ -> ()
