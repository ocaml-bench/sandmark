let test_string =
  "In Department condita sicut Laboratory Mathematica in manu Lenard, John \
   Jones May XIV MCMXXXVII, quamquam is did non adepto recte statutum usque \
   post Belli Orbis Terrarum II. Laboratorium Septentrionalis Nova erat \
   proque domo longis Wing est pristini Advertising School, in Novum Site. In \
   die qua fundata est, cum in animo sit computing ministerium providere ad \
   communem usum, et quod a centro est, in development of Universitatis elit \
   computational. Et Diplomatis Cambridge in Computer Science est mundi \
   primum doceri utique postgraduate in computing, incipiens in MCMLIII."

let string_get iterations =
  let length = String.length test_string in
  for i = 1 to iterations do
    ignore (Sys.opaque_identity test_string.[i mod length])
  done

let string_sub iterations =
  let length = String.length test_string in
  for i = 1 to iterations do
    let i_start = i mod (length - 2) in
    ignore (Sys.opaque_identity (String.sub test_string i_start 2))
  done

let string_blit iterations =
  let length = String.length test_string in
  for i = 1 to iterations do
    let dst = Bytes.make 32 ' ' in
    String.blit test_string (i mod (length - 32)) dst 0 32
  done

let string_concat iterations =
  for i = 1 to iterations do
    let fish = ["I"; "AM"; "A"; "FISH"] in
    ignore (Sys.opaque_identity (String.concat " " fish))
  done

let string_iter iterations =
  for i = 1 to iterations do
    String.iter (fun c -> ()) test_string
  done

let string_map iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (String.map (fun c -> '!') test_string))
  done

let string_trim iterations =
  let string_needing_trimming = "We need a trim\n\n\n\n\n" in
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (String.trim string_needing_trimming))
  done

let string_index iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (String.index test_string 'r'))
  done

let string_contains iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (String.contains test_string 'r'))
  done

let string_uppercase_ascii iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (String.uppercase_ascii test_string))
  done

let string_split_on_char iterations =
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (String.split_on_char ' ' test_string))
  done

let string_compare iterations =
  let all_words = String.split_on_char ' ' test_string in
  let sum_all_compare x = List.fold_left (fun acc y -> acc + String.compare x y) 0 all_words in
  let accum_fn acc x = acc + sum_all_compare x in
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (List.fold_left accum_fn 0 all_words))
  done

let string_equal iterations =
  let all_words = String.split_on_char ' ' test_string in
  let sum_all_equal x = List.fold_left (fun acc y -> if String.equal x y then acc+1 else acc) 0 all_words in
  let accum_fn acc x = acc + sum_all_equal x in
  for i = 1 to iterations do
    ignore (Sys.opaque_identity (List.fold_left accum_fn 0 all_words))
  done

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "string_get" ->
      string_get iterations
  | "string_sub" ->
      ignore (string_sub iterations)
  | "string_blit" ->
      ignore (string_blit iterations)
  | "string_concat" ->
      ignore (string_concat iterations)
  | "string_iter" ->
      ignore (string_iter iterations)
  | "string_map" ->
      ignore (string_map iterations)
  | "string_trim" ->
      ignore (string_trim iterations)
  | "string_index" ->
      ignore (string_index iterations)
  | "string_contains" ->
      ignore (string_contains iterations)
  | "string_uppercase_ascii" ->
      ignore (string_uppercase_ascii iterations)
  | "string_split_on_char" ->
      ignore (string_split_on_char iterations)
  | "string_compare" ->
      ignore (string_compare iterations)
  | "string_equal" ->
      ignore (string_equal iterations)
  | _ ->
      ()
