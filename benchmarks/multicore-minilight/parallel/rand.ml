open Domain.DLS

let k : Random.State.t Domain.DLS.key = new_key ()

let get_state () = try Option.get @@ Domain.DLS.get k
  with _ -> begin
    Domain.DLS.set k (Random.State.make_self_init ());
    Option.get @@ Domain.DLS.get k
  end
