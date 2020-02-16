module C = Domainslib.Chan

type message = Do of (unit -> unit) | Quit

type chan = {req: message C.t; resp: unit C.t}

let n = try int_of_string Sys.argv.(1) with _ -> 4

let num_domains = try int_of_string Sys.argv.(2) with _ -> 1

let channels =
  Array.init num_domains (fun _ -> {req= C.make 1; resp= C.make 0})

type e = 
      | None
      | Some of int

(* let edges = Array.make_matrix n n None       *)

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

let f_w s e =
  for k = s to (pred e) do
    for i = 0 to n-1 do
      if edges.(i).(k) <> None then
        for j = 0 to n-1 do
          if edges.(k).(j) <> None && (edges.(i).(j) = None || ( sum  edges.(i).(k)   edges.(k).(j) ) <  edges.(i).(j) ) then
            edges.(i).(j) <- (sum edges.(i).(k)  edges.(k).(j))
        done
    done
  done

let aux () =
  let temp = ((n-1)+1)/num_domains in
  let job i () =
    f_w  (i * temp)  ((i + 1) * temp)
  in
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  Array.iter (fun c -> C.recv c.resp) channels

let print_mat m =
  for i = 0 to n-1 do
    for j = 0 to n-1 do
      my_print  m.(i).(j); print_string "  "
    done;
    print_newline()
  done

let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      () 


let ()=  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  aux() ;
  print_mat (edges );
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains 