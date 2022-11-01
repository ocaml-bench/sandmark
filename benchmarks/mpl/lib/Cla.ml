let rec search needle argv =
  match argv with
  | opt::xs ->
    if opt = needle
    then Some xs else search needle xs
  | _ -> None

let argv () = Sys.argv |> Array.to_list

let parse_flag key =
  match search ("--" ^ key) (argv ()) with
  | Some _ -> true
  | None -> false

let parse_val key default from_string =
  match search ("-" ^ key) (argv ()) with
  | None -> default
  | Some [] -> raise (Failure ("Missing argument of -" ^ key))
  | Some (x :: _) -> from_string x

let parse_int key default =
  parse_val key default int_of_string

let parse_float key default =
  parse_val key default float_of_string

let parse_string key default =
  parse_val key default (fun s -> s)
