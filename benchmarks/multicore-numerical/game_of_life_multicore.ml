module C = Domainslib.Chan

type message = Do of (unit -> unit) | Quit

type chan = {req: message C.t; resp: unit C.t}

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n_times = try int_of_string Sys.argv.(2) with _ -> 2

let channels =
  Array.init (num_domains - 1) (fun _ -> {req= C.make 1; resp= C.make 0})


let get g x y =
  try g.(x).(y)
  with _ -> 0

let neighbourhood g x y =
  (get g (x-1) (y-1)) +
  (get g (x-1) (y  )) +
  (get g (x-1) (y+1)) +
  (get g (x  ) (y-1)) +
  (get g (x  ) (y+1)) +
  (get g (x+1) (y-1)) +
  (get g (x+1) (y  )) +
  (get g (x+1) (y+1))

let next_cell g x y =
  let n = neighbourhood g x y in
  match g.(x).(y), n with
  | 1, 0 | 1, 1                      -> 0  (* lonely *)
  | 1, 4 | 1, 5 | 1, 6 | 1, 7 | 1, 8 -> 0  (* overcrowded *)
  | 1, 2 | 1, 3                      -> 1  (* lives *)
  | 0, 3                             -> 1  (* get birth *)
  | _ (* 0, (0|1|2|4|5|6|7|8) *)     -> 0  (* barren *)

let copy g = Array.map Array.copy g

let evaluate g new_g s e =
  let height = Array.length g.(0) in
  for x = s to e do
    for y = 0 to pred height do
      Domain.Sync.poll();
      new_g.(x).(y) <- (next_cell g x y)
    done
  done

let next g =
  let width = Array.length g
  (* and height = Array.length g.(0)  *)
  and new_g = copy g in
  let job i () =
    evaluate g new_g (i * (pred width) / num_domains)  (((i + 1) * (pred width)/num_domains))
  in
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  job (num_domains - 1) ();
  Array.iter (fun c -> C.recv c.resp) channels;
  new_g


let print g =
  let width = Array.length g
  and height = Array.length g.(0) in
  for x = 0 to pred width do
    for y = 0 to pred height do
      if g.(x).(y) = 0
      then print_char '.'
      else print_char 'o'
    done;
    print_newline()
  done

let rec myfun g n =
  match n with
  | 0-> g
  | _-> myfun (next g) (n-1)

let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()


let ()=
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  (* let g = [|
    [| 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; |];
    [| 0; 1; 0; 1; 0; 0; 0; 0; 0; 0; |];
    [| 0; 0; 0; 1; 0; 0; 0; 0; 0; 0; |];
    [| 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; |];
    [| 0; 0; 0; 1; 1; 1; 1; 0; 0; 0; |];
    [| 0; 0; 0; 1; 1; 1; 0; 0; 0; 0; |];
    [| 0; 0; 0; 0; 0; 0; 0; 1; 1; 0; |];
    [| 0; 0; 0; 1; 1; 0; 0; 0; 1; 0; |];
    [| 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; |];
    [| 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; |];
  |] in *)
  let g = Array.init 1024 (fun _ -> Array.init 1024 (fun _ -> Random.int 2)) in
  print g;
  print_string " Resultant state";print_newline();
  print (myfun g n_times);
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains
