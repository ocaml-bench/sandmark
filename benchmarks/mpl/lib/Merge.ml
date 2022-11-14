let slice_idxs s i j =
  Seq.subseq s (i, j-i)

let write_merge_serial cmp s1 s2 t =
  let write i x = Seq.set t i x in
  let n1 = Seq.length s1 in
  let n2 = Seq.length s2 in
  (* i1 index into s1
   * i2 index into s2
   * j index into output *)
  let rec loop i1 i2 j =
    if i1 = n1 then
      Seq.foreach (slice_idxs s2 i2 n2) (fun i x -> write (i+j) x)
    else if i2 = n2 then
      Seq.foreach (slice_idxs s1 i1 n1) (fun i x -> write (i+j) x)
    else
    let x1 = Seq.get s1 i1 in
    let x2 = Seq.get s2 i2 in
    if cmp x1 x2 < 0 then
      (write j x1; loop (i1+1) i2 (j+1))
    else
      (write j x2; loop i1 (i2+1) (j+1))
  in
  loop 0 0 0


let merge_serial cmp s1 s2 =
  let n1 = Seq.length s1 in
  let n2 = Seq.length s2 in
  if n1 + n2 = 0 then
    Seq.empty ()
  else
  let dummy_elem = if n1 <> 0 then Seq.get s1 0 else Seq.get s2 0 in
  let out = Seq.full (Array.make (n1+n2) dummy_elem) in
  write_merge_serial cmp s1 s2 out;
  out


let rec write_merge cmp s1 s2 t =
  if Seq.length t <= 4096 then
    write_merge_serial cmp s1 s2 t
  else if Seq.length s1 = 0 then
    Seq.foreach s2 (fun i x -> Seq.set t i x)
  else
  let n1 = Seq.length s1 in
  let n2 = Seq.length s2 in
  let mid1 = n1 / 2 in
  let pivot = Seq.get s1 mid1 in
  let mid2 = Binarysearch.search cmp s2 pivot in

  let l1 = slice_idxs s1 0 mid1 in
  let r1 = slice_idxs s1 (mid1+1) n1 in
  let l2 = slice_idxs s2 0 mid2 in
  let r2 = slice_idxs s2 mid2 n2 in

  let _ = Seq.set t (mid1+mid2) pivot in
  let tl = slice_idxs t 0 (mid1+mid2) in
  let tr = slice_idxs t (mid1+mid2+1) (Seq.length t) in
  let _ =
    Forkjoin.par
      (fun _ -> write_merge cmp l1 l2 tl)
      (fun _ -> write_merge cmp r1 r2 tr)
  in
  ()


let merge cmp s1 s2 =
  let n1 = Seq.length s1 in
  let n2 = Seq.length s2 in
  if n1 + n2 = 0 then
    Seq.empty ()
  else
  let dummy_elem = if n1 <> 0 then Seq.get s1 0 else Seq.get s2 0 in
  let out = Seq.full (Array.make (n1+n2) dummy_elem) in
  write_merge cmp s1 s2 out;
  out
