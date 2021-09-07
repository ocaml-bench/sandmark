let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
let n = try int_of_string Sys.argv.(2) with _ -> 1000
module C = Domainslib.Chan

open Globroots

module TestClassic = Test(Classic) ()
module TestGenerational = Test(Generational) ()

let c = C.make_bounded 0

let wait () =
  C.recv c |> ignore

let _ =
  let domains = Array.init (num_domains - 1) (fun _ -> Domain.spawn(wait)) in
  young2old (); Gc.full_major ();
  assert (static2young (1, 1) Gc.full_major == 0x42);
  print_string "Non-generational API\n";
  TestClassic.test n;
  print_newline();
  print_string "Generational API\n";
  TestGenerational.test n;
  print_newline();
  for i = 1 to (num_domains - 1) do
    C.send c i
  done;
  Array.iter Domain.join domains
