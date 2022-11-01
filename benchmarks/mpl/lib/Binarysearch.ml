let search cmp s x =
  let rec loop lo hi =
    match hi - lo with
    | 0 -> lo
    | n ->
      let mid = lo + n / 2 in
      let pivot = Seq.get s mid in
      let c = cmp x pivot in
      if c < 0 then
        (* less *)
        loop lo mid
      else if c = 0 then
        (* equal *)
        mid
      else
        (* greater *)
        loop (mid+1) hi
  in
  loop 0 (Seq.length s)
