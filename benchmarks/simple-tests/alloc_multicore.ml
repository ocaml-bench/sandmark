let num_domains = try int_of_string(Sys.argv.(1)) with _ -> 1
let iterations = try int_of_string(Sys.argv.(2)) with _ -> 1_000_000

type a_mutable_record = { an_int : int; mutable a_string : string ; a_float: float } 

let rec create f n =
  match n with 
  | 0 -> ()
  | _ -> let _ = f() in
  create f (n-1)


let () =
  let w = iterations / num_domains in
    let rec spawn i =
      if i > 0 then
        (Domain.spawn (fun () -> for _ = 0 to w do
  Sys.opaque_identity create (fun () -> { an_int = 5; a_string = "foo"; a_float = 0.1 }) 1000
done)) :: spawn (i-1)
      else
        []
      in
        ignore(Sys.opaque_identity(List.iter (fun f -> Domain.join f) (spawn num_domains)))
