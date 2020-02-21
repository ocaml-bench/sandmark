
(* let ts = 64 *)

let matrix_size = try int_of_string Sys.argv.(1) with _ -> 1024

let ts = try int_of_string Sys.argv.(2) with _ -> 64

let matrix_multiply x y =
  let x0 = Array.length x
  and y0 = Array.length y in
  let y1 = if y0 = 0 then 0 else Array.length y.(0) in
  let z = Array.make_matrix x0 y1 0 in

  let bi= ref 0 in
  while  (!bi < x0) do

    let bj= ref 0 in
    while  (!bj < y1) do

      let bk= ref 0 in
      while  (!bk < y1) do

      for i= 0 to (pred ts) do
        for j= 0 to (pred ts) do  
          for k=0 to (pred ts) do
            z.(!bi+i).(!bj+j) <- z.(!bi+i).(!bj+j) + x.(!bi+i).(!bk+k) * y.(!bk+k).(!bj+j)
          done 
        done
      done;
      bk:=!bk+ts  
    done;
    bj:=!bj+ts 
    done;
    bi:=!bi+ts  
  done;
  z



let () =
  (* let n = int_of_string(Sys.argv.(1)) and *)
  (* let mat=matrix_multiply [|[|1;2|];[|3;4|]|] [|[|-3;-8;3|];[|-2;1;4|]|] in *)
  let m1 = Array.init matrix_size (fun _ -> Array.init matrix_size (fun _ -> Random.int 100))
  and m2 = Array.init matrix_size (fun _ -> Array.init matrix_size (fun _ -> Random.int 100)) in
  let mat=matrix_multiply m1 m2 in
  let x = Array.length mat
  and y = Array.length mat.(0) in
  for i = 0 to x-1 do
    for j = 0 to y-1 do
      print_int mat.(i).(j); print_string "  "
    done;
    print_newline()
  done
