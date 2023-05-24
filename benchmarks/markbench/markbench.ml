(* Micro benchmark by Stephen Dolan to monitor prefetching performance for
   regressions *)

type t = {
  mutable a : int option;
  mutable b : float;
  mutable c : float;
  mutable d : float;
  mutable e : float;
  mutable f : float;
}

let make_arr () =
  let nums = Array.init (1 lsl 20) (fun i -> Some i) in
  let a = Array.init 1_024 (fun _ -> []) in
  for i = 1 to 10_000_000 do
    let n = ((i * 34872841) lsr 13) land 0x3ff in
    a.(n) <- { a = nums.(i land 0xfffff); b = 0.; c = 0.; d = 0.; e = 0.; f = 42. } :: a.(n);
  done;
  a

let arr = make_arr ()
let () = Printf.eprintf "Setup done\n%!"

let bench n =
  Printf.eprintf "Performing %n GC full major\n%!" n;
  let tstart = Unix.gettimeofday () in
  for _ = 1 to n do
    Gc.full_major ()
  done;
  let tend = Unix.gettimeofday () in
  Printf.printf "%.3f s/gc\n" ((tend -. tstart) /. float_of_int n)

let () =
  match Sys.argv with
  | [| _; "noop" |] -> ()
  | [| _ |] -> bench 10
  | [| _; n |] -> bench (int_of_string n)
  | _ -> exit 1
