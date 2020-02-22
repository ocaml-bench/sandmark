let size = try int_of_string Sys.argv.(1) with _ -> 1024

let matrix_multiply z x y =
  let lx = Array.length x in
  let ly = Array.length y in
  for i = 0 to lx - 1 do
    for j = 0 to ly - 1 do
      for k = 0 to ly - 1 do
        z.(i).(j) <- z.(i).(j) + x.(i).(k) * y.(k).(j)
      done
    done
  done

let () =
  let m1 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
  let m2 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
  let res = Array.make_matrix size size 0 in
  matrix_multiply res m1 m2;
  for i = 0 to size - 1 do
    for j = 0 to size - 1 do
      print_int res.(i).(j); print_string "  "
    done;
    print_newline()
  done
