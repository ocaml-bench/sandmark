module C = Domainslib.Chan

open Format

type message = Do of (unit -> unit) | Quit

type chan = {req: message C.t; resp: unit C.t}

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1

let mat_size = try int_of_string Sys.argv.(2) with _ -> 1200

let channels = 
Array.init (num_domains -1) (fun _ -> {req= C.make 1; resp= C.make 0})

module Array = struct
  include Array

  let init_matrix m n f = init m (fun i -> init n (f i))

  (** [swap x i j] swaps [x.(i)] and [x.(j)]. *)
  let swap x i j =
    let tmp = x.(i) in
    x.(i) <- x.(j);
    x.(j) <- tmp
end

let distribution = 
  let rec loop n d acc = 
    if d = 1 then n::acc
    else 
      let w = n / d in
      loop (n - w) (d - 1) (w::acc)
  in
  Array.of_list (loop mat_size num_domains [])

let run_iter job = 
  let sum = ref 0 in
  Array.iteri (fun i c ->
    let begin_ = !sum in
    sum := !sum + distribution.(i);
    let end_ = !sum in
    C.send c.req (Do (job begin_ end_))) channels;
  job !sum (!sum + distribution.(num_domains - 1)) ();
  Array.iter (fun c -> C.recv c.resp) channels


let aux a k size s e =
  for row = s to (pred e) do
      match row >= k + 1  with
      | true -> 
        let factor = (a.(row).(k)) /. (a.(k).(k)) in
        for col = k + 1 to size-1 do
            Domain.Sync.poll();
            a.(row).(col) <- a.(row).(col) -. factor *. a.(k).(col)
        done;
        a.(row).(k) <- factor
      | false -> ()  
  done 

let lup a0 =
let a = Array.copy a0 in
  for k = 0 to (mat_size - 2) do
    run_iter (fun s e () -> aux a k mat_size s e)
  done ;
  a 




let print_mat label x =
  printf "%s =@\n" label;
  Array.iter (fun xi ->
      Array.iter (printf "  %10g") xi;
      print_newline ()) x


let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      () 


let () =
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
 (*  let a = 
  [|
    [| 1.; -2.; -2.; -3.|];
    [|3.; -9.; 0.; -9.|];
    [| -1.; 2.;4.; 7.|];
    [| -3.; -6.; 26.; 2.|];
    
  |]  in *)
  let a = Array.init mat_size 
  (fun _ -> Array.init mat_size (fun _ -> (Random.float 100.0)+.1.0)) in
  (* print_mat "matrix A" a ; *)
  let lu = lup a in (* in
  let l = Array.init_matrix mat_size mat_size
      (fun i j -> if i > j then lu.(i).(j) else if i = j then 1.0 else 0.0) in
  let u = Array.init_matrix mat_size mat_size
      (fun i j -> if i <= j then lu.(i).(j) else 0.0) in *)
  (* print_mat "matrix L" l;
  print_mat "matrix U" u; *)
  ignore lu ;
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains 