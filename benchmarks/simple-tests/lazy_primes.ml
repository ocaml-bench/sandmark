let nth = try int_of_string (Sys.argv.(1)) with _ -> 1

type 'a stream = Cons of 'a * 'a stream Lazy.t

let hd (Cons (x,_)) = x

let tl (Cons (_,l)) = Lazy.force l

let rec from (n : int) : int stream =
  Cons (n, lazy (from (n + 1)))

let rec take n s =
 if n = 0 then [] else (hd s)::(take (n-1) (tl s))

let rec drop n s =
 if n = 0 then s
 else drop (n-1) (tl s)

let rec zip f s1 s2 =
 Cons (f (hd s1) (hd s2), lazy (zip f (tl s1) (tl s2)))

let rec filter p s =
 if p (hd s) then filter p (tl s)
 else Cons (hd s, lazy (filter p (tl s)))

let primes_stream =
 let rec primes s =
   Cons (hd s, lazy (primes @@ filter (fun x -> x mod (hd s) = 0) (tl s)))
 in
 primes (from 2)

let _ =
  match take 1 (drop (nth - 1) primes_stream) with
  | [p] -> Printf.printf "%d\n" p
  | _ -> failwith "impossible"
