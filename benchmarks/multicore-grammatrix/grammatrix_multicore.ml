(* Copyright (C) 2020, Francois Berenger

   Yamanishi laboratory,
   Department of Bioscience and Bioinformatics,
   Faculty of Computer Science and Systems Engineering,
   Kyushu Institute of Technology,
   680-4 Kawazu, Iizuka, Fukuoka, 820-8502, Japan. *)

module A = Array
module L = List
module T = Domainslib.Task

let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
let input_fn = try Sys.argv.(3) with _ ->  "data/tox21_nrar_ligands_std_rand_01.csv"
let chunk_size = try int_of_string Sys.argv.(2) with _ -> 0

let dot_product xs ys =
  let n = A.length xs in
  assert(n = A.length ys);
  let res = ref 0.0 in
  for i = 0 to n - 1 do
    res := !res +. ((A.unsafe_get xs i) *. (A.unsafe_get ys i))
  done;
  !res

let compute_gram_matrix samples pool =
  let n = A.length samples in
  assert(n > 0);
  let res = A.init n (fun _ -> A.create_float n) in
  T.parallel_for ~start:0 ~finish:(n - 1) ~body:(fun i ->
    for j = i to n - 1 do
      let x = dot_product samples.(i) samples.(j) in
      res.(i).(j) <- x;
      res.(j).(i) <- x (* symmetric matrix *)
    done) pool;
  res

let parse_line line =
  let int_strings = Utls.string_split_on_char ' ' line in
  let nb_features = L.length int_strings in
  let res = A.create_float nb_features in
  L.iteri (fun i int_str ->
      A.unsafe_set res i (float_of_string int_str)
    ) int_strings;
  res

let _ =
  let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) in
  let samples = A.of_list (Utls.map_on_lines_of_file input_fn parse_line) in
  Printf.printf "samples: %d features: %d\n"
      (A.length samples) (A.length samples.(0));
  let r = compute_gram_matrix samples pool in
  Utls.print_matrix r
