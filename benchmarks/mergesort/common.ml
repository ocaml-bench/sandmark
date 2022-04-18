module T = Domainslib.Task
module A = Array
module AS = CCArray_slice

type point3d = float * float * float

let print_point3d (x,y,z) =
  print_string ("(" ^ Float.to_string x ^ ", " ^ Float.to_string y ^ ", " ^ Float.to_string z ^ ")")

let compare_point3d (axis : int) ((x1,y1,z1) : point3d) ((x2,y2,z2) : point3d) : int =
  if axis == 0
  then Float.compare x1 x2
  else if axis == 1
  then Float.compare y1 y2
  else Float.compare z1 z2

let dist_point3d ((x1,y1,z1) : point3d) ((x2,y2,z2) : point3d) : float =
  let (d1, d2, d3) = (x1 -. x2, y1 -. y2, z1 -. z2) in
  (d1 *. d1) +. (d2 *. d2) +. (d3 *. d3)

let min_point3d ((x1,y1,z1) : point3d) ((x2,y2,z2) : point3d) : point3d =
  ((Float.min x1 x2),  (Float.min y1 y2), (Float.min z1 z2))

let max_point3d ((x1,y1,z1) : point3d) ((x2,y2,z2) : point3d) : point3d =
  ((Float.max x1 x2),  (Float.max y1 y2), (Float.max z1 z2))

let coord (i : int) ((x,y,z) : point3d) =
  match i with
    0 -> x
  | 1 -> y
  | 2 -> z
  | _ -> z

type point2d = float * float

let compare_point2d (axis : int) ((x1,y1) : point2d) ((x2,y2) : point2d) : int =
  if axis == 0
  then Float.compare x1 x2
  else Float.compare y2 y2

let dist_point2d ((x1,y1) : point2d) ((x2,y2) : point2d) : float =
  let (d1, d2) = (x1 -. x2, y1 -. y2) in
  (d1 *. d1) +. (d2 *. d2)

let min_point2d ((x1,y1) : point2d) ((x2,y2) : point2d) : point2d =
  ((Float.min x1 x2),  (Float.min y1 y2))

let max_point2d ((x1,y1) : point2d) ((x2,y2) : point2d) : point2d =
  ((Float.max x1 x2),  (Float.max y1 y2))


(* https://stackoverflow.com/questions/5774934 *)
let read_file (filename : string) : string list =
  let lines = ref [] in
  let chan = open_in filename in
  try
    while true; do
      lines := input_line chan :: !lines
    done; !lines
  with End_of_file ->
    close_in chan;
    List.rev !lines ;;

(* A.init n (fun i -> let line = List.nth lines i in
 *                    if (String.length line) == 0
 *                    then (0.01, 0.01, 0.01)
 *                    else
 *                      let words = String.split_on_char ' ' line in
 *                      let a = Float.of_string (List.nth words 0) in
 *                      let b = Float.of_string (List.nth words 1) in
 *                      let c = Float.of_string (List.nth words 2) in
 *                      (a, b, c))
 *)

let read3DArrayFile (fp : string) : point3d array =
  let lines = read_file fp in
  let n = List.length lines in
  let _ = print_endline ("length: " ^ string_of_int n ^ "\n") in
  let pool = T.setup_pool ~num_domains:48 in
  let result = A.make n (0.01, 0.01, 0.01) in
  let _ = T.parallel_for ~start:0 ~finish:(n-1)
            ~body:(fun i -> let line = List.nth lines i in
                            if (String.length line) == 0
                            then ()
                            else
                              let words = String.split_on_char ' ' line in
                              let a = Float.of_string (List.nth words 0) in
                              let b = Float.of_string (List.nth words 1) in
                              let c = Float.of_string (List.nth words 2) in
                              A.set result i (a, b, c);
                              ())
            pool in
  let _ = T.teardown_pool pool in
  result


let read2DArrayFile (fp : string) : point2d array =
  let lines = read_file fp in
  let n = List.length lines in
  let pool = T.setup_pool ~num_domains:48 in
  let result = A.make n (0.01, 0.01) in
  let _ = T.parallel_for ~start:0 ~finish:(n-1)
            ~body:(fun i -> let line = List.nth lines i in
                            if (String.length line) == 0
                            then ()
                            else
                              let words = String.split_on_char ' ' line in
                              let a = Float.of_string (List.nth words 0) in
                              let b = Float.of_string (List.nth words 1) in
                              A.set result i (a, b);
                              ())
            pool in
  let _ = T.teardown_pool pool in
  result

let get_rand (n : int) : int =
  let t = Unix.gettimeofday () in
  let i = Float.round t in
  (Float.hash i) mod n

let filter_array (f : ('a -> bool)) (arr : 'a array) : 'a array =
  let module A = Array in
  A.of_list (List.filter f (A.to_list arr))

let print_array f arr =
  let _ = A.iter (fun x -> print_string (f x ^ " ")) arr in
  print_endline "\n"

let print_slice f arr =
  let _ = AS.iter (fun x -> print_string (f x ^ " ")) arr in
  print_endline "\n"
