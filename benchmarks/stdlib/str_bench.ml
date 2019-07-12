let test_regex = {regex|Novum Site|regex}

let test_string = "In Department condita sicut Laboratory Mathematica in manu Lenard, John Jones May XIV MCMXXXVII, quamquam is did non adepto recte statutum usque post Belli Orbis Terrarum II. Laboratorium Septentrionalis Nova erat proque domo longis Wing est pristini Advertising School, in Novum Site. In die qua fundata est, cum in animo sit computing ministerium providere ad communem usum, et quod a centro est, in development of Universitatis elit computational. Et Diplomatis Cambridge in Computer Science est mundi primum doceri utique postgraduate in computing, incipiens in MCMLIII."

let str_regexp iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Str.regexp test_regex))
    done

let str_string_match iterations =
    let regex = Str.regexp test_regex in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Str.string_match regex test_string 0))
    done

let str_search_forward iterations =
    let regex = Str.regexp test_regex in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Str.search_forward regex test_string 0))
    done

let str_string_partial_match iterations =
    let regex = Str.regexp test_regex in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Str.string_partial_match regex test_string 0))
    done

let str_global_replace iterations =
    let regex = Str.regexp test_regex in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Str.global_replace regex "." test_string))
    done

let str_split iterations =
    let regex = Str.regexp "@" in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Str.split regex test_string))
    done

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "str_regexp" ->
      str_regexp iterations
  | "str_string_match" ->
      ignore (str_string_match iterations)
  | "str_search_forward" ->
      ignore (str_search_forward iterations)
  | "str_string_partial_match" ->
      ignore (str_string_partial_match iterations)
  | "str_global_replace" ->
      ignore (str_global_replace iterations)
  | "str_split" ->
      ignore (str_split iterations)           
  | _ ->
      ()