let test_bytes = "In Department condita sicut Laboratory Mathematica in manu Lenard, John Jones May XIV MCMXXXVII, quamquam is did non adepto recte statutum usque post Belli Orbis Terrarum II. Laboratorium Septentrionalis Nova erat proque domo longis Wing est pristini Advertising School, in Novum Site. In die qua fundata est, cum in animo sit computing ministerium providere ad communem usum, et quod a centro est, in development of Universitatis elit computational. Et Diplomatis Cambridge in Computer Science est mundi primum doceri utique postgraduate in computing, incipiens in MCMLIII."

let bytes_get iterations =
    let length = Bytes.length test_bytes in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Bytes.get test_bytes (i mod length)))
    done

let bytes_set iterations =
    let copy = Bytes.copy test_bytes in
    let copy_length = Bytes.length copy in
    for i = 1 to iterations do
        Sys.opaque_identity(Bytes.set copy (i mod copy_length) ' ')
    done

let bytes_cat iterations =
    let s = Bytes.to_string "I AM A FISH" in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Bytes.cat s test_bytes))
    done

let bytes_sub iterations =
    let length = Bytes.length test_bytes in
    for i = 1 to iterations do
        let i_start = (i mod (length-2)) in
            ignore(Sys.opaque_identity(Bytes.sub test_bytes i_start 2))
    done

let bytes_blit iterations =
    let length = Bytes.length test_bytes in
    for i = 1 to iterations do
        let dst = Bytes.make 32 ' ' in
            Bytes.blit test_bytes (i mod (length-32)) dst 0 32
    done

let bytes_concat iterations =
    for i = 1 to iterations do
        let fish = ["I"; "AM"; "A"; "FISH"] in
            ignore(Sys.opaque_identity(Bytes.concat " " fish))
    done

let bytes_iter iterations =
    for i = 1 to iterations do
        Bytes.iter (fun c -> ()) test_bytes
    done

let bytes_map iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Bytes.map (fun c -> '!') test_bytes))
    done

let bytes_trim iterations =
    let bytes_needing_trimming = "We need a trim\n\n\n\n\n" in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Bytes.trim bytes_needing_trimming))
    done

let bytes_index iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Bytes.index test_bytes 'r'))
    done

let bytes_contains iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Bytes.contains test_bytes 'r'))
    done

let bytes_uppercase_ascii iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(Bytes.uppercase_ascii test_bytes))
    done

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "bytes_get" ->
      bytes_get iterations
  | "bytes_sub" ->
      ignore (bytes_sub iterations)
  | "bytes_blit" ->
      ignore (bytes_blit iterations)
  | "bytes_concat" ->
      ignore (bytes_concat iterations)
  | "bytes_iter" ->
      ignore (bytes_iter iterations)
  | "bytes_map" ->
      ignore (bytes_map iterations)
  | "bytes_trim" ->
      ignore (bytes_trim iterations)
  | "bytes_index" ->
      ignore (bytes_index iterations)
  | "bytes_contains" ->
      ignore (bytes_contains iterations)
  | "bytes_uppercase_ascii" ->
      ignore (bytes_uppercase_ascii iterations)            
  | _ ->
      ()
