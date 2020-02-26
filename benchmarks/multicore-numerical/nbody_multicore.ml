(* The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * Contributed by Troestler Christophe
 *)

module C = Domainslib.Chan

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ -> 500
let num_bodies = try int_of_string Sys.argv.(3) with _ -> 1024

let pi = 3.141592653589793
let solar_mass = 4. *. pi *. pi
let days_per_year = 365.24

type message = Do of (unit -> unit) | Quit
type chan = {req: message C.t; resp: unit C.t}
let channels =
  Array.init (num_domains - 1) (fun _ -> {req= C.make 1; resp= C.make 0})

type planet = { mutable x : float;  mutable y : float;  mutable z : float;
                mutable vx: float;  mutable vy: float;  mutable vz: float;
                mass : float }

let advance bodies dt s e =
  (* let n = Array.length bodies - 1 in *)
  for i = s to (pred e) do
    let b = bodies.(i) in
    for j = 0 to Array.length bodies - 1 do
      let b' = bodies.(j) in
      if (i!=j) then
      begin
        let dx = b.x -. b'.x  and dy = b.y -. b'.y  and dz = b.z -. b'.z in
        let dist2 = dx *. dx +. dy *. dy +. dz *. dz in
        let mag = dt /. (dist2 *. sqrt(dist2)) in
        b.vx <- b.vx -. dx *. b'.mass *. mag;
        b.vy <- b.vy -. dy *. b'.mass *. mag;
        b.vz <- b.vz -. dz *. b'.mass *. mag;
      end


      (* b'.vx <- b'.vx +. dx *. b.mass *. mag;
      b'.vy <- b'.vy +. dy *. b.mass *. mag;
      b'.vz <- b'.vz +. dz *. b.mass *. mag; *)
    done
  done

let second_loop bodies dt s e =
  for i = s to (pred e) do
    let b = bodies.(i) in
    b.x <- b.x +. dt *. b.vx;
    b.y <- b.y +. dt *. b.vy;
    b.z <- b.z +. dt *. b.vz;
  done

let distribution = 
  let rec loop n d acc = 
    if d = 1 then n::acc
    else 
      let w = n / d in
      loop (n - w) (d - 1) (w::acc)
  in
  Array.of_list (loop num_bodies num_domains [])

let run_iter job = 
  let sum = ref 0 in
  Array.iteri (fun i c ->
    let begin_ = !sum in
    sum := !sum + distribution.(i);
    let end_ = !sum in
    C.send c.req (Do (job begin_ end_))) channels;
  job !sum (!sum + distribution.(num_domains - 1)) ();
  Array.iter (fun c -> C.recv c.resp) channels

let aux_1 bodies dt =
  run_iter (fun s e () -> advance bodies dt s e);
  run_iter (fun s e () -> second_loop bodies dt s e)

let energy bodies =
  let e = ref 0. in
  for i = 0 to Array.length bodies - 1 do
    let b = bodies.(i) in
    e := !e +. 0.5 *. b.mass *. (b.vx *. b.vx +. b.vy *. b.vy +. b.vz *. b.vz);
    for j = i+1 to Array.length bodies - 1 do
      let b' = bodies.(j) in
      let dx = b.x -. b'.x  and dy = b.y -. b'.y  and dz = b.z -. b'.z in
      let distance = sqrt(dx *. dx +. dy *. dy +. dz *. dz) in
      e := !e -. (b.mass *. b'.mass) /. distance
    done
  done;
  !e

let offset_momentum bodies =
  let px = ref 0. and py = ref 0. and pz = ref 0. in
  for i = 0 to Array.length bodies - 1 do
    px := !px +. bodies.(i).vx *. bodies.(i).mass;
    py := !py +. bodies.(i).vy *. bodies.(i).mass;
    pz := !pz +. bodies.(i).vz *. bodies.(i).mass;
  done;
  bodies.(0).vx <- -. !px /. solar_mass;
  bodies.(0).vy <- -. !py /. solar_mass;
  bodies.(0).vz <- -. !pz /. solar_mass

let rec worker c () =
  match C.recv c.req with
  | Do f ->
      f () ; C.send c.resp () ; worker c ()
  | Quit ->
      ()

let bodies =
  Array.init num_bodies (fun _ ->
    { x = (Random.float  10.);
      y = (Random.float 10.);
      z = (Random.float 10.);
      vx= (Random.float 5.) *. days_per_year;
      vy= (Random.float 4.) *. days_per_year;
      vz= (Random.float 5.) *. days_per_year;
      mass=(Random.float 10.) *. solar_mass; })

let () =
  let domains = Array.map (fun c -> Domain.spawn (worker c)) channels in
  offset_momentum bodies;
  Printf.printf "%.9f\n" (energy bodies);
  for _i = 1 to n do aux_1 bodies 0.01 done;
  Printf.printf "%.9f\n" (energy bodies);
  Array.iter (fun c -> C.send c.req Quit) channels;
  Array.iter Domain.join domains
