open Sequence_cps

let test n =
  let s = Sequence(0,
                   {unfold =
                      fun i ~on_done ~on_skip ~on_yield ->
                        if i >= n then on_done else
                          on_yield (i+1) i})
  in
  s
  |> map ~f:(fun x -> x + 3)
  |> filter ~f:(fun i -> i land 1 = 0)
  |> map ~f:(fun x -> x * x)
  |> fold ~init:0 ~f:(+)

let () =
  let n = int_of_string Sys.argv.(1) in
  let r = ref 0 in
  for i = 0 to n do
    r := !r + test i;
  done;
  print_int !r;
  print_newline ()

let () =
  try
    let fn = Sys.getenv "OCAML_GC_STATS" in
    let oc = open_out fn in
    Gc.print_stat oc
  with _ -> ()
