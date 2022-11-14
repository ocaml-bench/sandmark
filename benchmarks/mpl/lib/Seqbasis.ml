type grain = int

(* maybe do ref-loop instead? *)
let rec foldl f b (i, j) g =
  if i >= j then b
  else foldl f (f b (g i)) (i+1, j) g

(* let foldl f b (i, j) g =
  if i >= j then b else
  let r = ref b in
  for k = i to j-1 do
    r := f (!r) (g k)
  done;
  !r *)

let tabulate grain (i, j) f =
  if i >= j then [||] else
  (* make an array and initialize with the first element *)
  let a, tm = Benchmark.getTime (fun _ -> Array.make (j-i) (f i)) in
  if (j-i > 100000) then Printf.printf "tabulate: array make %.03f\n" tm;
  (* in parallel, set all the other indices *)
  Forkjoin.parfor grain (1, j-i) (fun k ->
    Array.set a k (f (i+k))
  );
  a

(*
let reduce grain g b (lo, hi) f =
  let n = hi-lo in
  let m = 1 + (n-1) / grain in (* number of blocks *)
  let block_sum block_idx =
    let block_lo = lo + block_idx * grain in
    let block_hi = min (block_lo + grain) hi in
    let rec loop b i =
      if i >= block_hi then b else loop (g b (f i)) (i+1)
    in
    loop b block_lo
  in
  let rec red i j =
    match j-i with
    | 0 -> b
    | 1 -> block_sum i
    | _ ->
      let mid = i + (j-i) / 2 in
      let l, r = Forkjoin.par (fun _ -> red i mid) (fun _ -> red mid j) in
      g l r
  in
  red 0 m
*)



let rec reduce grain g b (lo, hi) f =
  let n = hi - lo in
  if n <= grain then
    let rec loop b i =
      if i >= hi then b else loop (g b (f i)) (i+1)
    in
    loop b lo
  else
  let mid = lo + n / 2 in
  let l, r = Forkjoin.par
    (fun _ -> reduce grain g b (lo, mid) f)
    (fun _ -> reduce grain g b (mid, hi) f)
  in
  g l r


(*
let rec reduce grain g b (lo, hi) f =
  let n = hi - lo in
  let m = 1 + (n-1) / grain in
  let sums = Array.make m b in
  Forkjoin.parfor 1 (0, m) (fun block_idx ->
    let block_lo = lo + block_idx * grain in
    let block_hi = min (block_lo + grain) hi in
    let rec loop b i =
      if i >= block_hi then b else loop (g b (f i)) (i+1)
    in
    sums.(block_idx) <- loop b block_lo
  );
  if m = 1 then sums.(0) else
  reduce grain g b (0, m) (Array.get sums)
*)

let prim_reduce grain f b (i, j) g =
  Domainslib.Task.parallel_for_reduce
    ~chunk_size:grain
    ~start:i
    ~finish:(j-1)
    ~body:g
    Forkjoin.pool
    f
    b

let rec scan grain (g: 'a -> 'a -> 'a) (b: 'a) (lo, hi) (f: int -> 'a) =
  let n = hi - lo in
  if hi - lo <= grain then
    let (result: 'a array) = Array.make (n+1) b in
    let rec loop b i =
      if i >= hi then b else begin
        result.(i) <- b;
        loop (g b (f i)) (i+1)
      end
    in
    result.(n) <- loop b lo;
    result
  else
    let k = grain in
    let m = 1 + (n-1) / k in (* number of blocks *)
    let sums = Array.make m b in
    Forkjoin.parfor 1 (0, m) (fun i ->
      let block_lo = lo + i*grain in
      let block_hi = min (block_lo + grain) hi in
      let rec loop b j =
        if j >= block_hi then b else loop (g b (f j)) (j+1)
      in
      sums.(i) <- loop b block_lo
    );
    let partials = scan grain g b (0, m) (Array.get sums) in
    let (result: 'a array) = Array.make (n+1) b in
    Forkjoin.parfor 1 (0, m) (fun i ->
      let block_lo = lo + i*grain in
      let block_hi = min (block_lo + grain) hi in
      let rec loop b j =
        if j >= block_hi then b else begin
          result.(j) <- b;
          loop (g b (f j)) (j+1)
        end
      in
      result.(n) <- loop partials.(i) block_lo
    );
    Array.set result n (Array.get partials m);
    result


let prim_scan grain g b (lo, hi) f =
  let n = hi-lo in
  if n <= 0 then [||] else
  let a = Array.make (n+1) b in
  Forkjoin.parfor grain (0, n) (fun k ->
    Array.set a (k+1) (f (lo+k))
  );
  Domainslib.Task.parallel_scan Forkjoin.pool g a


let filter grain (lo, hi) f g =
  if hi-lo <= 0 then [||] else
  let n = hi - lo in
  let k = grain in
  let m = 1 + (n-1) / k in (* number of blocks *)
  let counts = tabulate 1 (0, m) (fun i ->
    let start = lo + i*k in
    let endd = min (start+k) hi in
    let rec loop j c =
      if j >= endd then c
      else if g j then loop (j+1) (c+1)
      else loop (j+1) c
    in
    loop start 0)
  in
  let offsets = scan grain (+) 0 (0, m) (Array.get counts) in
  let result, tm = Benchmark.getTime (fun _ -> Array.make offsets.(m) (f lo)) in
  if (offsets.(m) > 100000) then Printf.printf "filter array make %.03f\n" tm;
  Forkjoin.parfor 1 (0, m) (fun i ->
    let start = lo + i*k in
    let endd = min (start+k) hi in
    let rec loop j c =
      if j >= endd then ()
      else if g j then (result.(c) <- f j; loop (j+1) (c+1))
      else loop (j+1) c
    in
    loop start offsets.(i)
  );
  result
