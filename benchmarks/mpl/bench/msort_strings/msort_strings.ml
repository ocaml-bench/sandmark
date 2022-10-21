(* let n = Cla.parse_int "N" (100 * 1000 * 1000) *)
let serial_grain = Cla.parse_int "serial" 1024

(* let rec sort cmp s =
  let n = Seq.length s in
  if n <= serial_grain then begin
    let t = Array.init n (Seq.get s) in
    Array.fast_sort cmp t;
    Seq.full t
  end else
  let l = Seq.take s (n/2) in
  let r = Seq.drop s (n/2) in
  let l', r' = Forkjoin.par (fun _ -> sort cmp l) (fun _ -> sort cmp r) in
  Merge.merge cmp l' r' *)

let rec write_sort cmp s t =
  let n = Seq.length s in
  if n <= serial_grain then begin
    for i = 0 to n-1 do
      Seq.set t i (Seq.get s i)
    done;
    Quicksort.sortInPlace cmp t
  end else
  let half = n/2 in
  let sl, sr = Seq.take s half, Seq.drop s half in
  let tl, tr = Seq.take t half, Seq.drop t half in
  let _ = Forkjoin.par
    (fun _ -> write_sort_in_place cmp sl tl)
    (fun _ -> write_sort_in_place cmp sr tr)
  in
  Merge.write_merge cmp sl sr t

and write_sort_in_place cmp s t =
  let n = Seq.length s in
  if n <= serial_grain then
    Quicksort.sortInPlace cmp s
  else
  let half = n/2 in
  let sl, sr = Seq.take s half, Seq.drop s half in
  let tl, tr = Seq.take t half, Seq.drop t half in
  let _ = Forkjoin.par
    (fun _ -> write_sort cmp sl tl)
    (fun _ -> write_sort cmp sr tr)
  in
  Merge.write_merge cmp tl tr s


let sort_in_place cmp s =
  if Seq.length s <= 1 then () else
  let (t, tm) = Benchmark.getTime (fun _ -> Seq.full (Array.make (Seq.length s) (Seq.get s 0))) in
  Printf.printf "array alloc: %f\n" tm;
  write_sort_in_place cmp s t


let sort cmp s =
  if Seq.length s <= 1 then s else
  let (result, tm) = Benchmark.getTime (fun _ -> Seq.map (fun x -> x) s) in
  Printf.printf "array copy: %f\n" tm;
  sort_in_place cmp result;
  result

let usage () =
  Printf.printf "usage: msort_strings -f FILE\n";
  exit 1

let filename = Cla.parse_string "f" ""
let makeLong = Cla.parse_flag "long"
let _ = if filename = "" then usage ()

let (contents, tm) = Benchmark.getTime (fun _ -> Readfile.contents filename)
let _ = Printf.printf "read file in %.03fs\n" tm

let is_whitespace c =
  c = ' ' || c = '\n' || c = '\r' || c = '\t' || c = '\x0C'

let tokens = Forkjoin.run (fun _ -> Tokenize.tokens is_whitespace contents)

let prefix = String.make 32 'a'
let input =
  if not makeLong then tokens
  else Forkjoin.run (fun _ -> Seq.map (fun str -> prefix ^ str) tokens)

let bench () = Forkjoin.run (fun _ -> sort compare input)

let result = Benchmark.run "msort" bench
let _ =
  for i = 0 to min (Seq.length result - 1) 10 do
    Printf.printf "%s " (Seq.get result i)
  done;
  Printf.printf "...\n";
