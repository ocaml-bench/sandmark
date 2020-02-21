let matrix_multiply x y =
  let x0 = Array.length x
  and y0 = Array.length y in
  let y1 = if y0 = 0 then 0 else Array.length y.(0) in
  let z = Array.make_matrix x0 y1 0 in
  for i = 0 to x0-1 do
    for j = 0 to y1-1 do
      for k = 0 to y0-1 do
        z.(i).(j) <- z.(i).(j) + x.(i).(k) * y.(k).(j)
      done
    done
  done;
  z

let () =
  (* let n = int_of_string(Sys.argv.(1)) and *)
  (* let mat=matrix_multiply [|[|1;2|];[|3;4|]|] [|[|-3;-8;3|];[|-2;1;4|]|] in *)
  let m1 = Array.init 1024 (fun _ -> Array.init 1024 (fun _ -> Random.int 100))
  and m2 = Array.init 1024 (fun _ -> Array.init 1024 (fun _ -> Random.int 100)) in
  let mat=matrix_multiply m1 m2 in
  let x = Array.length mat
  and y = Array.length mat.(0) in
  for i = 0 to x-1 do
    for j = 0 to y-1 do
      print_int mat.(i).(j); print_string "  "
    done;
    print_newline()
  done
