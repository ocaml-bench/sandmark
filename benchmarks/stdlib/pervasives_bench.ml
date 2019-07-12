let list_a = [1; 2; 3;]
let list_b = [3; 1; 2;]

let pervasives_compare_lists iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(compare list_a list_b))
    done

let pervasives_compare_ints iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(compare i 42))
    done

let pervasives_compare_floats iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(compare (float_of_int i) 5.))
    done

let pervasives_compare_strings iterations =
    let test_string = "I am a fish." in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(compare (string_of_int i) test_string))
    done

let pervasives_equal_lists iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(list_a == list_b))
    done

let pervasives_equal_ints iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity(i == 42))
    done

let pervasives_equal_floats iterations =
    for i = 1 to iterations do
        ignore(Sys.opaque_identity((float_of_int i) == 5.))
    done

let pervasives_equal_strings iterations =
    let test_string = "I am a fish." in
    for i = 1 to iterations do
        ignore(Sys.opaque_identity((string_of_int i) == test_string))
    done

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "pervasives_compare_lists" ->
      pervasives_compare_lists iterations
  | "pervasives_compare_ints" ->
      pervasives_compare_ints iterations
  | "pervasives_compare_floats" ->
      pervasives_compare_floats iterations
  | "pervasives_compare_strings" ->
      pervasives_compare_strings iterations
  | "pervasives_equal_lists" ->
      pervasives_equal_lists iterations
  | "pervasives_equal_ints" ->
      pervasives_equal_ints iterations
  | "pervasives_equal_floats" ->
      pervasives_equal_floats iterations
  | "pervasives_equal_strings" ->
      pervasives_equal_strings iterations     
  | _ ->
      ()