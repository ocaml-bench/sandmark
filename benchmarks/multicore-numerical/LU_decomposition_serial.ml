open Format

module Array = struct
  include Array

  let init_matrix m n f = init m (fun i -> init n (f i))

  (** [swap x i j] swaps [x.(i)] and [x.(j)]. *)
  let swap x i j =
    let tmp = x.(i) in
    x.(i) <- x.(j);
    x.(j) <- tmp
end

let mat_size = try int_of_string Sys.argv.(1) with _ -> 1200

let lup a0 =
  let a = Array.copy a0 in
  for k = 0 to (mat_size - 2) do 
    for row = k + 1 to (mat_size - 1) do
        let factor = (a.(row).(k)) /. (a.(k).(k)) in
        for col = k + 1 to mat_size-1 do
            a.(row).(col) <- a.(row).(col) -. factor *. a.(k).(col)
        done;
        a.(row).(k) <- factor
    done
  done ;
  a 


let print_mat label x =
  printf "%s =@\n" label;
  Array.iter (fun xi ->
      Array.iter (printf "  %10g") xi;
      print_newline ()) x

let () =
  (* let a = 
  [|
    [| 1.; -2.; -2.; -3.|];
    [|3.; -9.; 0.; -9.|];
    [| -1.; 2.;4.; 7.|];
    [| -3.; -6.; 26.; 2.|];
    
  |]  in *)
  let a = Array.init mat_size 
  (fun _ -> Array.init mat_size (fun _ -> (Random.float 100.0)+.1.0)) in
  print_mat "matrix A" a ;
  let lu = lup a in
  let l = Array.init_matrix mat_size mat_size
      (fun i j -> if i > j then lu.(i).(j) else if i = j then 1.0 else 0.0) in
  let u = Array.init_matrix mat_size mat_size
      (fun i j -> if i <= j then lu.(i).(j) else 0.0) in
  print_mat "matrix L" l;
  print_mat "matrix U" u 