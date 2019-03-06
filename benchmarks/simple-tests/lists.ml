let data_type = Sys.argv.(1)
let list_length = int_of_string Sys.argv.(2)
let words_to_allocate = 1000000000.

type a_mutable_record = { mutable an_int : int; a_string : string ; a_float: float } 

let rec create_list f n = match n with
  | 0 -> []
  | _ -> (f n) :: (create_list f (n-1))

let allocate_list () =
  match data_type with
  | "int" -> ignore (create_list (fun n -> (n+1)) list_length)
  | "float" -> ignore (create_list (fun n -> float_of_int n) list_length)
  | "int-tuple" -> ignore (create_list (fun n -> (n-1,n+1)) list_length)
  | "float-tuple" -> ignore (create_list (fun n -> ((float_of_int (n+1)), (float_of_int (n-1)))) list_length)
  | "string" -> ignore (create_list (fun n -> (string_of_int n)) list_length)
  | "record" -> ignore (create_list (fun n -> { an_int = n; a_string = (string_of_int n); a_float = (float_of_int n)}) list_length)
  | "float-array" -> ignore (create_list (fun n -> [| (float_of_int n), (float_of_int n), (float_of_int n) |]) list_length)
  | _ -> failwith "unexpected data type"

let () = while (Gc.minor_words() < words_to_allocate) do
    for i = 0 to 100 do
      allocate_list()
    done
  done

