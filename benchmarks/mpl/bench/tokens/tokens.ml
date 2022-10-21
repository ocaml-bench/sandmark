let usage () =
  Printf.printf "usage: tokens [--no-output] -f FILE\n";
  exit 1

let filename = Cla.parse_string "f" ""
let noOutput = Cla.parse_flag "no-output"

let _ = if filename = "" then usage ()

let (contents, tm) = Benchmark.getTime (fun _ -> Readfile.contents filename)
let _ = Printf.printf "read file in %.03fs\n" tm

let is_whitespace c =
  c = ' ' || c = '\n' || c = '\r' || c = '\t' || c = '\x0C'

let bench () = Forkjoin.run (fun _ -> Tokenize.tokens is_whitespace contents)
let result = Benchmark.run "tokens" bench
let _ = Printf.printf "tokens %d\n" (Seq.length result)

let _ =
  if noOutput then () else
  for i = 0 to Seq.length result - 1 do
    print_string (Seq.get result i ^ "\n")
  done
