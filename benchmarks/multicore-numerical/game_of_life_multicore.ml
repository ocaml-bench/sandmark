module C = Domainslib.Chan

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n_times = try int_of_string Sys.argv.(2) with _ -> 2
let board_size = 1024

let rg = 
  ref (Array.init board_size (fun _ -> Array.init board_size (fun _ -> Random.int 2)))
let rg' = 
  ref (Array.init board_size (fun _ -> Array.init board_size (fun _ -> Random.int 2)))
let buf = Bytes.create board_size

type message = Do of (unit -> unit) | Quit
type chan = {req: message C.t; resp: unit C.t}
let channels = Array.init (num_domains - 1) (fun _ -> {req= C.make 1; resp= C.make 0})

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

let evaluate g new_g s e =
  for x = s to e do
    for y = 0 to board_size - 1 do
      Domain.Sync.poll ();
      new_g.(x).(y) <- next_cell g x y
    done
  done

let next () =
  let g = !rg in
  let new_g = !rg' in
  let job i () =
    evaluate g new_g 
      (i * (board_size - 1) / num_domains) 
      ((i + 1) * (board_size - 1) / num_domains)
  in
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  job (num_domains - 1) ();
  Array.iter (fun c -> C.recv c.resp) channels;
  rg := new_g;
  rg' := g

let print g =
  for x = 0 to board_size - 1 do
    for y = 0 to board_size - 1 do
      if g.(x).(y) = 0
      then Bytes.set buf y '.' 
      else Bytes.set buf y 'o'
    done;
    print_endline (Bytes.unsafe_to_string buf)
  done;
  print_endline ""

let rec repeat n =
  match n with
  | 0-> ()
  | _-> next (); repeat (n-1)

let rec worker c () =
  match C.recv c.req with
  | Do f -> f () ; C.send c.resp () ; worker c ()
  | Quit -> ()

let ()=
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  print !rg;
  repeat n_times;
  print !rg;
  Array.iter (fun c -> C.send c.req Quit) channels;
  Array.iter Domain.join domains
