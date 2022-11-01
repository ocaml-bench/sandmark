
let rec primes n =
  if n < 2 then [||] else
  (* all primes up to sqrt(n) *)
  let sqrtPrimes =
    primes (int_of_float (Float.floor (Float.sqrt (float_of_int n))))
  in
  (* allocate array of flags to mark primes *)
  let flags = Bytes.create (n+1) in
  let mark i = Bytes.set flags i '1' in
  let unmark i = Bytes.set flags i '0' in
  let isMarked i = Bytes.get flags i = '1' in

  (* Printf.printf "primes(%d): initializing flags\n" n; *)

  (* initially, mark every number *)
  Forkjoin.parfor 5000 (0, n+1) mark;

  (* Printf.printf "primes(%d): unmarking multiples\n" n; *)

  (* unmark every multiple of every prime in sqrtPrimes *)
  Forkjoin.parfor 1 (0, Array.length sqrtPrimes) (fun i ->
    let p = sqrtPrimes.(i) in
    let numMultiples = n / p - 1 in
    Forkjoin.parfor 5000 (0, numMultiples) (fun j -> unmark ((j+2) * p))
  );

  (* Printf.printf "primes(%d): filtering\n" n; *)

  (* for every i in 2 <= i <= n, filter those that are still marked *)
  Seqbasis.filter 5000 (2, n+1) (fun i -> i) isMarked

let n = Cla.parse_int "N" (100 * 1000 * 1000)

let bench () = Forkjoin.run (fun _ -> primes n)

let result = Benchmark.run "primes" bench
let _ =
  Printf.printf "num-primes %d\n" (Array.length result);
  for i = 0 to min (n-1) 10 do
    Printf.printf "%d " result.(i)
  done;
  Printf.printf "...\n";
