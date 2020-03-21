(* Copyright (C) 2020, Francois Berenger

   Yamanishi laboratory,
   Department of Bioscience and Bioinformatics,
   Faculty of Computer Science and Systems Engineering,
   Kyushu Institute of Technology,
   680-4 Kawazu, Iizuka, Fukuoka, 820-8502, Japan. *)

module A = Array
module L = List
module C = Domainslib.Chan

(* type message = Do of (unit -> unit) | Quit
type chan = {req: message C.t; resp: unit C.t}
let channels = Array.init (ncores -1) (fun _ -> {req= C.make 1; resp= C.make 1}) *)

let dot_product xs ys =
  let n = A.length xs in
  assert(n = A.length ys);
  let res = ref 0.0 in
  for i = 0 to n - 1 do
    res := !res +. ((A.unsafe_get xs i) *. (A.unsafe_get ys i))
  done;
  !res

let compute_gram_mat samples res s e =
  let n = A.length samples in
  assert(n > 0);
  (* let res = A.init n (fun _ -> A.create_float n) in *)
  Printf.printf "r: %d\t c: %d" (Array.length res) (Array.length res.(0));
  for i = s to (pred e) do
    for j = i to n - 1 do
      (* Printf.printf "n: %d i: %d j: %d\n" n i j; *)
      Domain.Sync.poll();
      let x = dot_product samples.(i) samples.(j) in
      res.(i).(j) <- x;
      res.(j).(i) <- x; (* symmetric matrix *)
      (* Printf.printf "back\n" *)
    done
  done

let num_domains = try int_of_string Sys.argv.(1) with _ -> 4
type message = Do of (unit -> unit) | Quit
type chan = {req: message C.t; resp: unit C.t}
let channels = Array.init (num_domains -1) (fun _ -> {req= C.make 1; resp= C.make 1})
let input_fn = try Sys.argv.(2) with _ ->  "data/tox21_nrar_ligands_std_rand_01.csv"


let compute_gram_matrix samples num_domains =
  let n = A.length samples in
  assert(n > 0);
  let res = A.init n (fun _ -> A.create_float n) in
  let temp = n / num_domains in
  let job i () =
    compute_gram_mat samples res (i * temp)  ((i + 1) * temp)
  in
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  job (num_domains - 1) ();
  Array.iter (fun c -> C.recv c.resp) channels;
  res
  (* for i = 0 to n - 1 do
    for j = i to n - 1 do
      let x = dot_product samples.(i) samples.(j) in
      res.(i).(j) <- x;
      res.(j).(i) <- x (* symmetric matrix *)
    done
  done; *)
  (* let r = compute_gram_mat samples res 1 n in
  r *)

let parse_line line =
  let int_strings = Utls.string_split_on_char ' ' line in
  let nb_features = L.length int_strings in
  let res = A.create_float nb_features in
  L.iteri (fun i int_str ->
      A.unsafe_set res i (float_of_string int_str)
    ) int_strings;
  res



let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()

let _ =

  let samples = A.of_list (Utls.map_on_lines_of_file input_fn parse_line) in
  Printf.printf "samples: %d features: %d"
      (A.length samples) (A.length samples.(0));
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in

  let r = compute_gram_matrix samples num_domains in
  Utls.print_matrix r;
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains
