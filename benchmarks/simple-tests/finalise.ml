let percent_finalize = int_of_string Sys.argv.(1)
let iterations = 10000000

type a_record = { an_int: int; mutable a_string : string; a_float : float }

let allocate () =
  for y = 0 to 1000 do
    let v = { an_int = 5; a_string = "foo"; a_float = 0.0 } in
    if percent_finalize > 0 && y mod percent_finalize == 0 then
      Gc.finalise (fun n -> ignore(Sys.opaque_identity (n.an_int+1))) v
  else
    ignore(Sys.opaque_identity ref v)
  done

let () = for _ = 0 to iterations do
  allocate()
  done
