let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
let n = (try int_of_string Sys.argv.(2) with _ -> 1000) / num_domains

open Globroots

let work () =
  let module TestClassic = Test(Classic) () in
  let module TestGenerational = Test(Generational) () in
  young2old (); Gc.full_major ();
  print_string "Non-generational API\n";
  TestClassic.test n;
  print_newline();
  print_string "Generational API\n";
  TestGenerational.test n;
  print_newline()

let _ =
  let domains = Array.init (num_domains - 1) (fun _ -> Domain.spawn(work)) in
  work ();
  Array.iter Domain.join domains
