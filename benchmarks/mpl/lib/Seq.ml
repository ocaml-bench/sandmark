type 'a t =
  { data: 'a array
  ; lo: int
  ; hi: int
  }

type 'a seq = 'a t

let gran = 5000

let full (a: 'a array): 'a seq =
  { data = a; lo = 0; hi = Array.length a }

let base s =
  (s.data, s.lo, s.hi - s.lo)

let empty () =
  full [||]

let length s =
  s.hi - s.lo

let get s i =
  s.data.(s.lo + i)

let set s i x =
  s.data.(s.lo + i) <- x

let of_list xs =
  full (Array.of_list xs)

let fold_left f b s =
  let rec loop b i =
    if i >= s.hi then b else loop (f b (s.data.(i))) (i+1)
  in
  loop b s.lo

let fold_right f b s =
  let rec loop b i =
    if i <= s.lo then b else loop (f (s.data.(i-1)) b) (i-1)
  in
  loop b s.hi

let to_list xs =
  fold_right (fun x acc -> x :: acc) [] xs


let subseq s (i, len) =
  { data = s.data
  ; lo = s.lo + i
  ; hi = min (s.lo + i + len) s.hi
  }

let take s k =
  subseq s (0, k)

let drop s k =
  subseq s (k, length s - k)

let tabulate f n =
  full (Seqbasis.tabulate gran (0, n) f)

let map f s =
  full (Seqbasis.tabulate gran (0, length s) (fun i -> f (get s i)))

let rev s =
  let n = length s in
  full (Seqbasis.tabulate gran (0, n) (fun i -> get s (n-i-1)))

let append s1 s2 =
  let n1 = length s1 in
  let n2 = length s2 in
  let pull i = if i < n1 then get s1 i else get s2 (i-n1) in
  tabulate pull (n1 + n2)


let scan f b s =
  let n = length s in
  let p = full (Seqbasis.scan gran f b (0, n) (get s)) in
  (take p n, get p n)

let scan_incl f b s =
  let n = length s in
  let p = full (Seqbasis.scan gran f b (0, n) (get s)) in
  drop p 1

let reduce f b s =
  Seqbasis.reduce gran f b (0, length s) (get s)

let filter p s =
  full (Seqbasis.filter gran (0, length s) (get s) (fun i -> p (get s i)))

let filter_idx p s =
  full (Seqbasis.filter gran (0, length s) (get s) (fun i -> p i (get s i)))

let foreach s f =
  Forkjoin.parfor gran (0, length s) (fun i -> f i (get s i))

let flatten s =
  let offsets =
    full (Seqbasis.scan gran (+) 0 (0, length s) (fun i -> length (get s i)))
  in
  let total = get offsets (length s) in
  let dummy_elem = raise (Failure "ugh need to find dummy elem") in
  let output = Array.make total dummy_elem in
  Forkjoin.parfor 100 (0, length s) (fun i ->
    let t = get s i in
    let off = get offsets i in
    foreach t (fun j x -> output.(off + j) <- x)
  );
  full output
