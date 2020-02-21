let n = try int_of_string Sys.argv.(1) with _ -> 4

(* let edges = Array.make_matrix n n ~-1 *)


type e =
      | None
      | Some of int

let edges = Array.make_matrix n n None      

let edges = [|
    [| Some 0; Some 8;None; Some 1 |];
    [| None; Some 0; Some 1; None|];
    [| Some 4;None;Some 0;None |];
    [| None; Some 2; Some 9;Some 0 |];
  |] 

let sum x y =
  match x , y with 
  | Some x ,Some y -> Some (x+y)
  | _ , _-> None

let my_print x =
  match x with
  | Some x -> print_int x
  | None -> print_string "inf"  

let f_w () =
  (* let z = Array.make_matrix x0 x1 0 in *)
  for k = 0 to n-1 do
    for i = 0 to n-1 do
      if edges.(i).(k) <> None then
        for j = 0 to n-1 do
          if edges.(k).(j) <> None && (edges.(i).(j) = None || ( sum  edges.(i).(k)   edges.(k).(j) ) <  edges.(i).(j) ) then
            edges.(i).(j) <- (sum edges.(i).(k)  edges.(k).(j))
        done
    done
  done

let print_mat m =
(*   let x = Array.length m
  and y = Array.length m.(0) in *)
  for i = 0 to n-1 do
    for j = 0 to n-1 do
      my_print  m.(i).(j); print_string "  "
    done;
    print_newline()
  done


let ()=
  f_w(edges);
  print_mat (edges )
  (* let edges = [|
    [| 0; inf; 3; inf; 0; 0; 0; 0; 0; 0; |];
    [| 2; 0; inf; inf; 0; 0; 0; 0; 0; 0; |];
    [| inf; 7; 0; 1; 0; 0; 0; 0; 0; 0; |];
    [| 6; inf; inf; 0; 0; 0; 0; 0; 0; 0; |];
    [| 0; 0; 0; 1; 1; 1; 1; 0; 0; 0; |];
    [| 0; 0; 0; 1; 1; 1; 0; 0; 0; 0; |];
    [| 0; 0; 0; 0; 0; 0; 0; 1; 1; 0; |];
    [| 0; 0; 0; 1; 1; 0; 0; 0; 1; 0; |];
    [| 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; |];
    [| 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; |];
  |] in *) 


(* let _ =
  for i = 0 to n-1 do
    edges.(i).(i) <- 0
  done;

  for _ = 1 to e do
    let [n1; n2; w] = read_line() |> String.(split (regexp " ")) |> List.map int_of_string in
    edges.(n1-1).(n2-1) <- w
  done;

  for k = 0 to n-1 do
    for i = 0 to n-1 do
      if edges.(i).(k) <> ~-1 then
        for j = 0 to n-1 do
          if edges.(k).(j) <> ~-1 && (edges.(i).(j) = ~-1 || edges.(i).(k) + edges.(k).(j) < edges.(i).(j)) then
            edges.(i).(j) <- edges.(i).(k) + edges.(k).(j)
        done
    done
  done;

  let tests = read_line() |> int_of_string in

  for _ = 1 to tests do
    let [nt1; nt2] = read_line() |> String.(split (regexp " ")) |> List.map int_of_string in
    edges.(nt1-1).(nt2-1) |> print_int;
    print_newline()
  done *)