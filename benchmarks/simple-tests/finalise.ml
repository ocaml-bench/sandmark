let percent_finalize = int_of_string Sys.argv.(1)
let words_to_allocate = 1000000000.

type a_record = { an_int: int; mutable a_string : string; a_float : float }

let allocate () =
  for y = 0 to (if percent_finalize > 0 then percent_finalize*10 else 1000) do
    let v = { an_int = 5; a_string = "foo"; a_float = 0.0 } in
    if percent_finalize > 0 && y mod percent_finalize == 0 then
      Gc.finalise (fun n -> ignore(n.an_int+1)) v
  else
    ignore(ref v)
  done

let () = while (Gc.minor_words() < words_to_allocate) do
  allocate()
  done
