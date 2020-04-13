module T = Domainslib.Task

let num_domains = try Sys.argv.(2) |> int_of_string with _ -> 4
let size = try Sys.argv.(1) |> int_of_string with _ -> 1024
let ts=64
let domain_pool = T.setup_pool ~num_domains:num_domains
let chunks = Array.init (num_domains - 1) (fun x -> x)

let matrix_multiply z x y s e =
  (* let x0 = Array.length x in  *)
  let y0 = Array.length y in
  let y1 = if y0 = 0 then 0 else Array.length y.(0) in

  let bi= ref s in
  while !bi < e do
    let bj= ref 0 in
    while !bj < y1 do
      let bk= ref 0 in
      while !bk < y1 do
      for i= 0 to (pred ts) do
        for j= 0 to (pred ts) do
          for k=0 to (pred ts) do
            Domain.Sync.poll();
            z.(!bi+i).(!bj+j) <- z.(!bi+i).(!bj+j) + x.(!bi+i).(!bk+k) * y.(!bk+k).(!bj+j)
          done
        done
      done;
      bk:=!bk+ts
    done;
    bj:=!bj+ts
    done;
    bi:=!bi+ts
  done

let aux x y =
  let x0 = Array.length x
  and y0 = Array.length y in
  let y1 = if y0 = 0 then 0 else Array.length y.(0) in
  let z = Array.make_matrix x0 y1 0 in
  let temp = ((x0-1)+1)/num_domains in
  let job i () =
    matrix_multiply z x y (i * temp)  ((i + 1) * temp)
  in
  Array.map (fun i -> T.async domain_pool (job i)) chunks |> fun arr ->
  job (num_domains - 1) ();
  Array.iter (fun x -> T.await domain_pool x) arr;
  z

let () =
  let m1 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100))
  and m2 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
  (* let mat=aux [|[|1;2|];[|3;4|]|] [|[|-3;-8;3|];[|-2;1;4|]|] in *)
  let _mat = aux m1 m2 in
  (* let x = Array.length mat
  and y = Array.length mat.(0) in
  for i = 0 to x-1 do
    for j = 0 to y-1 do
      print_int mat.(i).(j); print_string "  "
    done;
    print_newline()
  done; *)
  T.teardown_pool domain_pool