(* Copyright (C) 2020, Francois Berenger

   Yamanishi laboratory,
   Department of Bioscience and Bioinformatics,
   Faculty of Computer Science and Systems Engineering,
   Kyushu Institute of Technology,
   680-4 Kawazu, Iizuka, Fukuoka, 820-8502, Japan. *)

open Printf

module A = Array
module L = List

let dot_product xs ys =
  let n = A.length xs in
  assert(n = A.length ys);
  let res = ref 0.0 in
  for i = 0 to n - 1 do
    res := !res +. ((A.unsafe_get xs i) *. (A.unsafe_get ys i))
  done;
  !res

let compute_gram_matrix samples =
  let n = A.length samples in
  assert(n > 0);
  let res = A.init n (fun _ -> A.create_float n) in
  for i = 0 to n - 1 do
    for j = i to n - 1 do
      let x = dot_product samples.(i) samples.(j) in
      res.(i).(j) <- x;
      res.(j).(i) <- x (* symmetric matrix *)
    done
  done;
  res

let parse_line line =
  let int_strings = Utls.string_split_on_char ' ' line in
  let nb_features = L.length int_strings in
  let res = A.create_float nb_features in
  L.iteri (fun i int_str ->
      A.unsafe_set res i (float_of_string int_str)
    ) int_strings;
  res

let input_fn = try Sys.argv.(2) with _ ->  "benchmarks/multicore-grammatrix/data/tox21_nrar_ligands_std_rand_01.csv"
let ncores = try int_of_string Sys.argv.(1) with _ -> 4


let _ =
  let samples = A.of_list (Utls.map_on_lines_of_file input_fn parse_line) in
  Printf.printf "samples: %d features: %d"
      (A.length samples) (A.length samples.(0));
  let r = compute_gram_matrix samples in
  Utls.print_matrix r
