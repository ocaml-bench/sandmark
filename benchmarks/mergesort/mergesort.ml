(* similar to Maple's mergesort: https://github.com/MPLLang/mpl/blob/master/examples/lib/Mergesort.sml  *)

open Common
module A = Array
module T = Domainslib.Task
module AS = CCArray_slice

let goto_seqmerge = 4096
let goto_quicksort = 8192

let rec binary_search' (lo : int) (hi :int) (f : 'a -> 'a -> int) (s : 'a AS.t) (x : 'a) : int =
  let n = hi - lo in
  if n == 0
  then lo
  else let mid = lo + (n / 2) in
       let pivot = AS.get s mid in
       let cmp = f x pivot in
       if cmp < 0
       then binary_search' lo mid f s x
       else if cmp > 0
       then binary_search' (mid+1) hi f s x
       else mid

let binary_search (f : 'a -> 'a -> int) (s : 'a AS.t) (x : 'a) : int =
  binary_search' 0 (AS.length s) f s x

let write_loop_seq (idx : int) (offset : int) (end_idx : int) (from : 'a AS.t) (to0 : 'a AS.t) : 'a AS.t =
  for i = idx to (end_idx-1) do
    AS.set to0 (i+offset) (AS.get from i)
  done;
  to0

let write_loop pool (idx : int) (offset : int) (end_idx : int) (from : 'a AS.t) (to0 : 'a AS.t) :'a AS.t =
  T.parallel_for ~start:idx ~finish:(end_idx-1)
    ~body:(fun i -> AS.set to0 (i+offset) (AS.get from i))
    pool;
  to0

(* i1 index into s1
 * i2 index into s2
 * j index into output *)
let rec write_merge_seq_loop (i1 : int) (i2 : int) (j : int) (n1 : int) (n2 : int) (f : 'a -> 'a -> int) (s1 : 'a AS.t) (s2 : 'a AS.t) (t : 'a AS.t) : 'a AS.t =
  if i1 == n1
  then let tmp1 = AS.sub s2 i2 (n2-i2) in
       let t2 = write_loop_seq 0 j (n2-i2) tmp1 t in
       t2
  else if i2 == n2
  then let tmp1 = AS.sub s1 i1 (n1-i1) in
       let t1 = write_loop_seq 0 j (n1-i1) tmp1 t in
       t1
  else let x1 = AS.get s1 i1 in
       let x2 = AS.get s2 i2 in
       if (f x1 x2) < 0
       then let _ = AS.set t j x1 in
            let res = write_merge_seq_loop (i1+1) i2 (j+1) n1 n2 f s1 s2 t in
            res
       else let _ = AS.set t j x2 in
            let res = write_merge_seq_loop i1 (i2+1) (j+1) n1 n2 f s1 s2 t in
            res

let write_merge_seq (f : 'a -> 'a -> int) (s1 : 'a AS.t) (s2 : 'a AS.t) (t : 'a AS.t) : 'a AS.t =
  let n1 = AS.length s1 in
  let n2 = AS.length s2 in
  let _ = write_merge_seq_loop 0 0 0 n1 n2 f s1 s2 t in
  t

let rec write_merge pool (f : 'a -> 'a -> int) (s1 : 'a AS.t) (s2 : 'a AS.t) (t : 'a AS.t) : 'a AS.t =
  if AS.length t < goto_seqmerge
  then write_merge_seq f s1 s2 t
  else
    let n1 = AS.length s1 in
    let n2 = AS.length s2 in
    if n1 == 0
    then write_loop pool 0 0 n2 s2 t
    else let mid1 = n1 / 2 in
         let pivot = AS.get s1 mid1 in
         let mid2 = binary_search f s2 pivot in
         let l1 = AS.sub s1 0 mid1 in
         let r1 = AS.sub s1 (mid1+1) (n1 - (mid1+1)) in
         let l2 = AS.sub s2 0 mid2 in
         let r2 = AS.sub s2 mid2 (n2-mid2) in
         let _ = AS.set t (mid1+mid2) pivot in
         let len_t = AS.length t in
         let tl = AS.sub t 0 (mid1+mid2) in
         let tr = AS.sub t (mid1+mid2+1) (len_t - (mid1+mid2+1)) in
         let tl1_f = T.async pool (fun _ -> write_merge pool f l1 l2 tl) in
         let tr1 = write_merge pool f r1 r2 tr in
         let tl1 = T.await pool tl1_f in
         t

let rec write_sort1 pool (f : 'a -> 'a -> int) (s : 'a AS.t) (t : 'a AS.t) : 'a AS.t =
  let len = AS.length s in
  if len < goto_quicksort
  then (Qsort.sortInPlace f s;
        s)
  else
    let half = len / 2 in
    let (sl, sr) = (AS.sub s 0 half, AS.sub s half (len-half)) in
    let (tl, tr) = (AS.sub t 0 half, AS.sub t half (len-half)) in
    let tl1_f = T.async pool (fun _ -> write_sort2 pool f sl tl) in
    let tr1 = write_sort2 pool f sr tr in
    let tl1 = T.await pool tl1_f in
    let res = write_merge pool f tl1 tr1 s in
    (* let res = write_merge_seq f tl1 tr1 s in *)
    res

and write_sort1_seq (f : 'a -> 'a -> int) (s : 'a AS.t) (t : 'a AS.t) : 'a AS.t =
  let len = AS.length s in
  if len < goto_quicksort
  then (Qsort.sortInPlace f s;
        s)
  else
    let half = len / 2 in
    let (sl, sr) = (AS.sub s 0 half, AS.sub s half (len-half)) in
    let (tl, tr) = (AS.sub t 0 half, AS.sub t half (len-half)) in
    let tl1 = write_sort2_seq f sl tl in
    let tr1 = write_sort2_seq f sr tr in
    let res = write_merge_seq f tl1 tr1 s in
    res

and write_sort2 pool (f : 'a -> 'a -> int) (s : 'a AS.t) (t : 'a AS.t) : 'a AS.t =
  let len = AS.length s in
  if len < goto_quicksort
  then
    let t1 = write_loop pool 0 0 len s t in
    Qsort.sortInPlace f t1;
    t1
  else
    let half = len / 2 in
    let (sl, sr) = (AS.sub s 0 half, AS.sub s half (len-half)) in
    let (tl, tr) = (AS.sub t 0 half, AS.sub t half (len-half)) in
    let sl1_f = T.async pool (fun _ -> write_sort1 pool f sl tl) in
    let sr1 = write_sort1 pool f sr tr in
    let sl1 = T.await pool sl1_f in
    let res = write_merge pool f sl1 sr1 t in
    (* let res = write_merge_seq f sl1 sr1 t in *)
    res

and write_sort2_seq (f : 'a -> 'a -> int) (s : 'a AS.t) (t : 'a AS.t) : 'a AS.t =
  let len = AS.length s in
  if len < goto_quicksort
  then
    let t1 = write_loop_seq 0 0 len s t in
    (Qsort.sortInPlace f t1;
     t1)
  else
    let half = len / 2 in
    let (sl, sr) = (AS.sub s 0 half, AS.sub s half (len-half)) in
    let (tl, tr) = (AS.sub t 0 half, AS.sub t half (len-half)) in
    let sl1 = write_sort1_seq f sl tl in
    let sr1 = write_sort1_seq f sr tr in
    let res = write_merge_seq f sl1 sr1 t in
    res

let mergesort pool (f : 'a -> 'a -> int) (vec : 'a array) : 'a array =
  let vec2 = A.copy vec in
  let s = AS.full vec2 in
  let t = AS.full (A.make (A.length vec2) (A.get vec2 0)) in
  let s1 = write_sort1 pool f s t in
  AS.underlying s1

let mergesort_seq (f : 'a -> 'a -> int) (vec : 'a array) : 'a array =
  let vec2 = A.copy vec in
  let s = AS.full vec2 in
  let t = AS.full (A.make (A.length vec2) (A.get vec2 0)) in
  (* Qsort.sortInPlace f s;
   * AS.underlying s *)
  let s1 = write_sort1_seq f s t in
  AS.underlying s1