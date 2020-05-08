(* Copyright (C) 2020, Francois Berenger

   Yamanishi laboratory,
   Department of Bioscience and Bioinformatics,
   Faculty of Computer Science and Systems Engineering,
   Kyushu Institute of Technology,
   680-4 Kawazu, Iizuka, Fukuoka, 820-8502, Japan. *)

module A = Array
module L = List
module C = Domainslib.Chan

let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
let input_fn = "data/tox21_nrar_ligands_std_rand_01.csv"
let chunk_size = try int_of_string Sys.argv.(2) with _ -> 16

let dot_product xs ys =
  let n = A.length xs in
  assert(n = A.length ys);
  let res = ref 0.0 in
  for i = 0 to n - 1 do
    res := !res +. ((A.unsafe_get xs i) *. (A.unsafe_get ys i))
  done;
  !res

let compute_gram_matrix samples res s e =
  let n = A.length samples in
  assert(n > 0);
  for i = s to e do
    for j = i to n - 1 do
      let x = dot_product samples.(i) samples.(j) in
      res.(i).(j) <- x;
      res.(j).(i) <- x (* symmetric matrix *)
    done
  done

let parse_line line =
  let int_strings = Utls.string_split_on_char ' ' line in
  let nb_features = L.length int_strings in
  let res = A.create_float nb_features in
  L.iteri (fun i int_str ->
      A.unsafe_set res i (float_of_string int_str)
    ) int_strings;
  res

type message =
    Work of int * int
  | Quit

let rec create_work c start left =
  if left < chunk_size then begin
(*     Printf.printf "%d %d\n" start (start + left - 1); *)
    C.send c (Work (start, start + left - 1));
    for _i = 1 to num_domains do
(*       print_endline "Quit"; *)
      C.send c Quit
    done
  end else begin
(*     Printf.printf "%d %d\n" start (start + chunk_size - 1); *)
    C.send c (Work (start, start + chunk_size - 1));
    create_work c (start + chunk_size) (left - chunk_size)
  end

let rec worker samples res c =
  match C.recv c with
  | Work (s,e) ->
(*       Printf.printf "work: %d %d\n" s e; *)
      compute_gram_matrix samples res s e;
      worker samples res c
  | Quit -> ()

let _ =
  let samples = A.of_list (Utls.map_on_lines_of_file input_fn parse_line) in
  let n = A.length samples in
  let c = C.make_bounded (n / chunk_size +
                  1 (* remaining work *) +
                  num_domains (* quit messages *))
  in
  create_work c 0 n;
  let res = A.init n (fun _ -> A.create_float n) in
  Printf.printf "samples: %d features: %d\n"
      (A.length samples) (A.length samples.(0));
  let domains =
    Array.init (num_domains - 1) (fun _ ->
      Domain.spawn (fun _ -> worker samples res c))
  in
  worker samples res c;
  Array.iter Domain.join domains;
  Utls.print_matrix res
