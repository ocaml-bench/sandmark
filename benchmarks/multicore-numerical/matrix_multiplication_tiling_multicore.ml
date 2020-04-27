module C = Domainslib.Chan

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let size = try int_of_string Sys.argv.(2) with _ -> 1024

type message = Do of (unit -> unit) | Quit
type chan = {req: message C.t; resp: unit C.t}
let channels =
  Array.init (num_domains - 1) (fun _ -> {req= C.make_bounded 1; resp= C.make_bounded 1})

let ts=64

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
  Array.iteri (fun i c -> C.send c.req (Do (job i))) channels ;
  job (num_domains - 1) ();
  Array.iter (fun c -> C.recv c.resp) channels;
  z


let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()

let () =
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  let m1 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100))
  and m2 = Array.init size (fun _ -> Array.init size (fun _ -> Random.int 100)) in
  (* let mat=aux [|[|1;2|];[|3;4|]|] [|[|-3;-8;3|];[|-2;1;4|]|] in *)
  let mat=aux m1 m2 in
  let _x = Array.length mat
  and _y = Array.length mat.(0) in
  (*for i = 0 to x-1 do
    for j = 0 to y-1 do
      print_int mat.(i).(j); print_string "  "
    done;
    print_newline()
  done;*)
  Array.iter (fun c -> C.send c.req Quit) channels ;
  Array.iter Domain.join domains
