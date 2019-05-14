let bar n =
  n + 5

let foo () = for a = 0 to 1_000_000 do
  ignore(Sys.opaque_identity bar a)
done

let () = for _ = 0 to (try int_of_string(Array.get Sys.argv 1) with _ -> 10_000) do
  foo()
done
