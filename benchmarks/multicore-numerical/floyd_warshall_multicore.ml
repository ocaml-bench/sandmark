let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ -> 4
(* n is size of matrix  *)

let sum x y =
  match x , y with
  | Some x ,Some y -> Some (x+y)
  | _ , _-> None

let print_inf x =
  match  x with
  | Some x -> print_int x
  | None -> print_string "∞"

let print_mat adjacency =
print_endline " ";
let rows = Array.length adjacency in
let columns = Array.length adjacency.(0) in
   for i = 0 to (rows - 1) do
       for j = 0 to (columns - 1) do
           print_inf adjacency.(i).(j); print_string " "
       done;
       print_endline " "
   done

module C = Domainslib.Chan
type message = Do of (unit -> unit) | Quit
type chan = {req: message C.t; resp: unit C.t}
let channels =
  Array.init (num_domains -1) (fun _ -> {req= C.make_bounded 1; resp= C.make_bounded 1})

let my_formula () =
  let r = Random.int 100 in
  let r1 = Random.int 2 in
  match r1 with
  |0 ->None
  |_-> Some r

let adj = Array.init n (fun _ -> Array.init n (fun _ -> my_formula ()))

let edit_diagonal mat =
  Array.iteri (fun i _ -> mat.(i).(i) <- Some 0) mat

(* let adj = [|
    [| Some 0; Some 8;None; Some 1 |];
    [| None; Some 0; Some 1; None|];
    [| Some 4;None;Some 0;None |];
    [| None; Some 2; Some 9;Some 0 |];
  |] *)

let distribution =
  let rec loop n d acc =
    if d = 1 then n::acc
    else
      let w = n / d in
      loop (n - w) (d - 1) (w::acc)
  in
  Array.of_list (loop n num_domains [])

let run_iter job =
  let sum = ref 0 in
  Array.iteri (fun i c ->
    let begin_ = !sum in
    sum := !sum + distribution.(i);
    let end_ = !sum in
    C.send c.req (Do (job begin_ end_))) channels;
  job !sum (!sum + distribution.(num_domains - 1)) ();
  Array.iter (fun c -> C.recv c.resp) channels

let f_w s e k =
    for i = s to (pred e) do
      if adj.(i).(k) <> None then
        for j = 0 to n-1 do
          Domain.Sync.poll();
          if adj.(k).(j) <> None && (adj.(i).(j) = None || ( sum  adj.(i).(k)   adj.(k).(j) ) <  adj.(i).(j) ) then
            adj.(i).(j) <- (sum adj.(i).(k)  adj.(k).(j))
        done
    done;
    ()

let aux () =
  for k = 0 to (pred n) do
    run_iter (fun s e () -> f_w s e k )
  done

let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()

let ()=
  edit_diagonal adj;
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  aux() ;
(*  print_mat adj ;*)
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains
