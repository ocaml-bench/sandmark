let iterations = 10000000

type a_mutable_record = { an_int : int; mutable a_string : string ; a_float: float } 

let rec create f n =
  match n with 
  | 0 -> ()
  | _ -> let _ = f() in
  create f (n-1)

let () = for _ = 0 to iterations do
  Sys.opaque_identity create (fun () -> { an_int = 5; a_string = "foo"; a_float = 0.1 }) 1000
done
