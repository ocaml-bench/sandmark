(** Stre GC Benchmark Suite

    This suite stresses the OCaml garbage collector through intensive string
    manipulation operations using the Stre module. Each benchmark targets
    different GC behaviors through string allocation patterns:
    - Substring allocation pressure
    - String splitting and concatenation
    - Pattern-based operations with regular expressions
    - Temporary string creation and disposal *)

open Devkit

(* Benchmark 1: String Split Storm (Minor GC stress) *)
let bench_split_storm () =
  let retained = ref [] in

  let base_string =
    String.concat ","
      (List.init 1000 (fun i -> Printf.sprintf "item_%d_value_%d" i (i * 7)))
  in

  for i = 1 to 1000 do
    let parts1 = Stre.nsplitc base_string ',' in
    let _parts2 = Stre.nsplitc_rev base_string ',' in

    let nested = String.concat "|" parts1 in
    let parts3 = Stre.nsplitc nested '|' in

    if i mod 50 = 0 then retained := parts3 @ !retained;

    let count = ref 0 in
    let _ =
      Stre.nsplitc_fold base_string ','
        (fun acc s ->
          incr count;
          if !count mod 10 = 0 then retained := s :: !retained;
          acc)
        ()
    in
    ();

    if List.length !retained > 1000 then
      retained := ExtList.List.take 500 !retained
  done

(* Benchmark 2: Substring Slicing Pressure *)
let bench_substring_slicing () =
  let retained_slices = ref [] in

  let source = String.init 100000 (fun i -> char_of_int (65 + (i mod 26))) in

  for i = 1 to 500 do
    let slice_size = 10 + (i mod 1000) in
    let offset = i mod (String.length source - slice_size) in

    let slice1 = Stre.from_to source offset (offset + slice_size) in
    let slice2 = Stre.unsafe_from_to source offset (offset + slice_size) in
    let slice3 = Stre.slice ~first:offset ~last:(offset + slice_size) source in

    for j = 0 to 9 do
      let overlap_start = offset + (j * (slice_size / 10)) in
      if overlap_start + slice_size < String.length source then
        let overlap =
          Stre.slice ~first:overlap_start
            ~last:(overlap_start + slice_size)
            source
        in
        if j mod 3 = 0 then retained_slices := overlap :: !retained_slices
    done;

    if i mod 20 = 0 then
      retained_slices := slice1 :: slice2 :: slice3 :: !retained_slices;

    if List.length !retained_slices > 500 then
      retained_slices := ExtList.List.take 250 !retained_slices
  done

(* Benchmark 3: Pattern-based String Operations *)
let bench_pattern_operations () =
  let retained_matches = ref [] in

  let text =
    String.concat "\n"
      (List.init 500 (fun i ->
           Printf.sprintf
             "Line %d: email_%d@example.com, phone: 555-%04d, code: ABC%03d" i i
             (i * 13 mod 9999)
             (i mod 1000)))
  in

  for i = 1 to 100 do
    let lines = Stre.nsplitc text '\n' in

    let processed =
      List.map
        (fun line ->
          let parts1 = Stre.nsplitc line ':' in
          let parts2 = List.concat_map (fun p -> Stre.nsplitc p ',') parts1 in

          let extracted =
            List.filter_map
              (fun p ->
                if String.length p > 5 then Some (Stre.slice ~first:0 ~last:5 p)
                else None)
              parts2
          in

          String.concat "|" extracted)
        lines
    in

    if i mod 10 = 0 then retained_matches := processed @ !retained_matches;

    let _ =
      List.map
        (fun s ->
          let upper = String.uppercase_ascii s in
          let lower = String.lowercase_ascii s in
          let reversed =
            String.init (String.length s) (fun j ->
                String.get s (String.length s - 1 - j))
          in
          if i mod 20 = 0 then
            retained_matches := upper :: lower :: reversed :: !retained_matches)
        (ExtList.List.take 10 processed)
    in

    if List.length !retained_matches > 1000 then
      retained_matches := ExtList.List.take 500 !retained_matches
  done

(* Benchmark 4: String Concatenation Chains *)
let bench_concatenation_chains () =
  let retained_chains = ref [] in

  for i = 1 to 200 do
    let chain1 = ref "" in
    let chain2 = ref "" in

    for j = 1 to 100 do
      chain1 := !chain1 ^ string_of_int j ^ ",";
      if j mod 10 = 0 then chain2 := !chain2 ^ !chain1
    done;

    let parts = Stre.nsplitc !chain1 ',' in
    let rejoined1 = String.concat "|" parts in
    let rejoined2 = String.concat ";" parts in
    let rejoined3 = String.concat "::" parts in

    let nested =
      List.fold_left
        (fun acc p -> acc ^ "[" ^ p ^ "]")
        ""
        (ExtList.List.take 50 parts)
    in

    if i mod 10 = 0 then
      retained_chains :=
        !chain1 :: !chain2 :: rejoined1 :: rejoined2 :: rejoined3 :: nested
        :: !retained_chains;

    if List.length !retained_chains > 200 then
      retained_chains := ExtList.List.take 100 !retained_chains
  done

(* Benchmark 5: Enumeration-based String Processing *)
let bench_enum_string_ops () =
  let retained_enums = ref [] in

  for i = 1 to 300 do
    let text =
      String.init 10000 (fun j ->
          if j mod 100 = 0 then '\n' else char_of_int (65 + ((i + j) mod 26)))
    in

    let enum1 = Stre.nsplitc_enum text '\n' in

    let processed =
      Enum.map
        (fun line ->
          let words = Stre.nsplitc line ' ' in
          String.concat "_" (List.map String.uppercase_ascii words))
        enum1
    in

    let partial = Enum.take 50 processed |> ExtList.List.of_enum in

    let enum2 = Stre.nsplitc_enum text '\n' in
    let filtered = Enum.filter (fun s -> String.length s > 50) enum2 in
    let filtered_list = Enum.take 20 filtered |> ExtList.List.of_enum in

    if i mod 15 = 0 then
      retained_enums := partial @ filtered_list @ !retained_enums;

    let enum3 = Stre.nsplitc_enum text '\n' in
    let chain =
      Enum.map
        (fun s -> Stre.slice ~first:0 ~last:(min 10 (String.length s)) s)
        enum3
    in
    let chain_list = Enum.take 30 chain |> ExtList.List.of_enum in

    if i mod 20 = 0 then retained_enums := chain_list @ !retained_enums;

    if List.length !retained_enums > 500 then
      retained_enums := ExtList.List.take 250 !retained_enums
  done

(* Benchmark 6: Mixed-size String Allocations *)
let bench_mixed_size_allocations () =
  let retained_mixed = Hashtbl.create 1000 in
  let counter = ref 0 in

  for i = 1 to 500 do
    let sizes = [| 10; 100; 1000; 50; 500; 5000; 20; 200; 2000 |] in

    Array.iter
      (fun size ->
        incr counter;

        let s = String.init size (fun j -> char_of_int (65 + (i * j mod 26))) in

        let chunk_size = max 1 (size / (10 + (i mod 10))) in
        let chunks = ref [] in
        let pos = ref 0 in
        while !pos < String.length s do
          let len = min chunk_size (String.length s - !pos) in
          chunks := Stre.slice ~first:!pos ~last:(!pos + len) s :: !chunks;
          pos := !pos + len
        done;

        let processed =
          List.map
            (fun chunk ->
              let upper = String.uppercase_ascii chunk in
              let doubled = chunk ^ chunk in
              if !counter mod 7 = 0 then doubled else upper)
            !chunks
        in

        if !counter mod 13 = 0 || !counter mod 17 = 0 then
          Hashtbl.replace retained_mixed !counter processed;

        if !counter mod 100 = 0 then
          Hashtbl.iter
            (fun k _ ->
              if k < !counter - 500 then Hashtbl.remove retained_mixed k)
            retained_mixed)
      sizes
  done

(* Benchmark 7: String Building with Buffers *)
let bench_string_building () =
  let retained_built = ref [] in

  for i = 1 to 200 do
    let direct = ref "" in
    for j = 1 to 100 do
      direct := !direct ^ Printf.sprintf "item_%d_%d " i j
    done;

    let parts = List.init 100 (fun j -> Printf.sprintf "item_%d_%d" i j) in
    let from_list = String.concat " " parts in

    let base = String.init 5000 (fun _ -> 'x') in
    let substrings =
      List.init 50 (fun j ->
          let start = j * 100 in
          let len = 50 + (j mod 50) in
          Stre.slice ~first:start ~last:(start + len) base)
    in
    let from_subs = String.concat "-" substrings in

    let split1 = Stre.nsplitc from_list ' ' in
    let rebuilt1 = String.concat "," split1 in

    let split2 = Stre.nsplitc from_subs '-' in
    let rebuilt2 = String.concat ";" split2 in

    if i mod 10 = 0 then
      retained_built :=
        !direct :: from_list :: from_subs :: rebuilt1 :: rebuilt2
        :: !retained_built;

    if List.length !retained_built > 300 then
      retained_built := ExtList.List.take 150 !retained_built
  done

(* Benchmark 8: Deep String Transformation Chains *)
let bench_transformation_chains () =
  let transformation_cache = Hashtbl.create 500 in
  let stage_results = ref [] in

  for i = 1 to 150 do
    let base =
      String.concat ","
        (List.init 200 (fun j -> Printf.sprintf "data_%d_%d" i j))
    in

    let stage1 = Stre.nsplitc base ',' in
    let stage1_transformed =
      List.map
        (fun s ->
          let len = String.length s in
          if len > 5 then Stre.slice ~first:2 ~last:(len - 1) s else s ^ s)
        stage1
    in

    let stage2 = String.concat "|" stage1_transformed in
    let stage2_split = Stre.nsplitc stage2 '|' in

    let stage3 =
      List.filter_map
        (fun s ->
          if String.length s mod 2 = 0 then Some (String.uppercase_ascii s)
          else if String.length s > 3 then
            Some (Stre.slice ~first:1 ~last:(String.length s - 1) s)
          else None)
        stage2_split
    in

    let stage4 =
      if List.length stage3 < 100 then
        List.concat_map
          (fun s1 ->
            List.map
              (fun s2 ->
                if String.length s1 + String.length s2 < 50 then s1 ^ "_" ^ s2
                else
                  Stre.slice ~first:0 ~last:10 s1
                  ^ "_"
                  ^ Stre.slice ~first:0 ~last:10 s2)
              (ExtList.List.take 5 stage3))
          (ExtList.List.take 10 stage3)
      else stage3
    in

    Hashtbl.replace transformation_cache i stage4;

    (if i > 10 then
       match Hashtbl.find_opt transformation_cache (i - 5) with
       | Some old_stage ->
           let combined =
             ExtList.List.take 10 stage4 @ ExtList.List.take 10 old_stage
           in
           stage_results := combined :: !stage_results
       | None -> ());

    if i mod 50 = 0 then
      Hashtbl.iter
        (fun k _ -> if k < i - 20 then Hashtbl.remove transformation_cache k)
        transformation_cache;

    if List.length !stage_results > 50 then
      stage_results := ExtList.List.take 25 !stage_results
  done

(* Main benchmark suite runner *)
let () =
  bench_split_storm ();
  bench_substring_slicing ();
  bench_pattern_operations ();
  bench_concatenation_chains ();
  bench_enum_string_ops ();
  bench_mixed_size_allocations ();
  bench_string_building ();
  bench_transformation_chains ()
