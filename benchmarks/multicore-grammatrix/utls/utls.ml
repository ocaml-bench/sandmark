(* Copyright (C) 2020, Francois Berenger

   Yamanishi laboratory,
   Department of Bioscience and Bioinformatics,
   Faculty of Computer Science and Systems Engineering,
   Kyushu Institute of Technology,
   680-4 Kawazu, Iizuka, Fukuoka, 820-8502, Japan. *)

module L = List

let with_in_file fn f =
  let input = open_in_bin fn in
  let res = f input in
  close_in input;
  res

let rev_lines_of_file fn =
  with_in_file fn (fun input ->
      let res = ref [] in
      try while true do
          res := (input_line input) :: !res
        done;
        assert(false)
      with End_of_file -> !res
    )

(* map f on lines of file *)
let map_on_lines_of_file fn f =
  L.rev_map f (rev_lines_of_file fn)

(* measure time spent in f (seconds) *)
let wall_clock_time f =
  let start = Unix.gettimeofday () in
  let res = f () in
  let stop = Unix.gettimeofday () in
  let delta_t = stop -. start in
  (delta_t, res)

(* abort if condition is not met *)
let enforce condition err_msg =
  if not condition then
    failwith err_msg

let range i j =
  let res = ref [] in
  for j' = j downto i do
    res := j' :: !res
  done;
  !res

let string_split_on_char sep str =
  let open String in
  if str = "" then [""]
  else
    (* str is non empty *)
    let rec loop acc ofs limit =
      if ofs < 0 then sub str 0 limit :: acc
      (* ofs >= 0 && ofs < length str *)
      else if unsafe_get str ofs <> sep then loop acc (ofs - 1) limit
      else loop (sub str (ofs + 1) (limit - ofs - 1) :: acc) (ofs - 1) ofs
    in
    let len = length str in loop [] (len - 1) len
