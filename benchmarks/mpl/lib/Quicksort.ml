

(* Author: The 210 Team
 * Adapted from SML by Sam Westrick
 *
 * Uses dual-pivot quicksort from:
 *
 * Dual-Pivot Quicksort Algorithm
 * Vladimir Yaroslavskiy
 * http://codeblab.com/wp-content/uploads/2009/09/DualPivotQuicksort.pdf
 * 2009
 *
 * Insertion sort is taken from the SML library ArraySort
 *)


let sortRange grainsize (array, start, n, compare) =
  let sub (a,i) = a.(i) in
  let update (a,i,x) = a.(i) <- x in

  let item i = sub(array,i) in
  let set (i,v) = update(array,i,v) in
  let cmp (i,j) = compare (item i) (item j) in

  let swap (i,j) =
    let tmp = item i in
    set(i, item j); set(j, tmp)
  in

  (* same as swap(j,k); swap(i,j) *)
  let rotate(i,j,k) =
    let tmp = item k in
    set(k, item j); set(j, item i); set(i, tmp)
  in

  let insertSort (start, n) =
    let limit = start+n in
    let rec outer i =
      if i >= limit then () else
      let rec inner j =
        if j = start then outer(i+1) else
        let j' = j - 1 in
        if cmp(j', j) > 0
        then (swap(j,j'); inner j')
        else outer(i+1)
      in
      inner i
    in
    outer (start+1)
  in

  (* puts lesser pivot at start and larger at end *)
  let twoPivots(a, n) =
    let sortToFront(size) =
      let m = n / (size + 1) in
      let rec toFront(i) =
        if (i < size) then (swap(a + i, a + m*(i+1)); toFront(i+1))
        else ()
      in
      (toFront(0); insertSort(a,size))
    in
    if (n < 80) then
      (if cmp(a, a+n-1) > 0 then swap(a,a+n-1) else ())
    else (sortToFront(5); swap(a+1,a); swap(a+3,a+n-1))
  in

  (* splits based on two pivots (p1 and p2) into 3 parts:
      less than p1, greater than p2, and the rest in the middle.
      The pivots themselves end up at the two ends.
      If the pivots are the same, returns a false flag to indicate middle
      need not be sorted. *)
  let split3 (a, n) =
    let (p1, p2) = (twoPivots(a,n); (a, a+n-1)) in
    let rec right(r) = if cmp(r, p2) > 0 then right(r-1) else r in
    let rec loop(l,m,r) =
      if (m > r) then
        (l,m)
      else if cmp(m, p1) < 0 then
        (swap(m,l); loop(l+1, m+1, r))
      else
      (if cmp(m, p2) > 0 then
      	(if cmp(r, p1) < 0
         then (rotate(l,m,r); loop(l+1, m+1, right(r-1)))
         else (swap(m,r); loop(l, m+1, right(r-1))))
      else
        loop(l, m+1, r))
    in
    let (l,m) = loop(a + 1, a + 1, right(a + n - 2)) in
    (l, m, cmp(p1, p2) < 0)
  in

  (* makes recursive calls in parallel if big enough *)
  let rec qsort (a, n) =
    if (n < 16) then insertSort(a, n) else
    let (l, m, doMid) = split3(a,n) in
    if (n <= grainsize) then
      (qsort (a, l-a);
       (if doMid then qsort(l, m-l) else ());
       qsort (m, a+n-m))
    else
    let left () = qsort (a, l-a) in
    let mid () = qsort (l, m-l) in
    let right () = qsort (m, a+n-m) in
    if doMid then
      let _ = Forkjoin.par3 left mid right in ()
    else
      let _ = Forkjoin.par left right in ()
  in
  qsort (start,n)

(* sorts an array slice in place *)
let sortInPlaceG grainsize compare (aslice: 'a Seq.t) =
  let (a, i, n) = Seq.base aslice in
  sortRange grainsize (a, i, n, compare)

let sortG grainsize compare (aslice: 'a Seq.t) =
  let result = Seq.map (fun x -> x) aslice in
  sortInPlaceG grainsize compare result;
  result

let grainsize = 8192

let sortInPlace c s = sortInPlaceG grainsize c s
let sort c s = sortG grainsize c s
