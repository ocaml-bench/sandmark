(* The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * Contributed by Troestler Christophe
 *)

module T = Domainslib.Task

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ -> 500
let num_bodies = try int_of_string Sys.argv.(3) with _ -> 1024

let pi = 3.141592653589793
let solar_mass = 4. *. pi *. pi
let days_per_year = 365.24

type planet = { mutable x : float;  mutable y : float;  mutable z : float;
                mutable vx: float;  mutable vy: float;  mutable vz: float;
                mass : float }

let aux_1 bodies dt pool =
  T.parallel_for pool
    ~chunk_size:(num_bodies/num_domains)
    ~start:0
    ~finish:(num_bodies - 1)
    ~body:(fun i ->
      let b = bodies.(i) in
      let vx, vy, vz = ref b.vx, ref b.vy, ref b.vz in
      for j = 0 to Array.length bodies - 1 do
        Domain.Sync.poll();
        let b' = bodies.(j) in
        if (i!=j) then begin
          let dx = b.x -. b'.x  and dy = b.y -. b'.y  and dz = b.z -. b'.z in
          let dist2 = dx *. dx +. dy *. dy +. dz *. dz in
          let mag = dt /. (dist2 *. sqrt(dist2)) in
          vx := !vx -. dx *. b'.mass *. mag;
          vy := !vy -. dy *. b'.mass *. mag;
          vz := !vz -. dz *. b'.mass *. mag;
        end
      done;
      b.vx <- !vx;
      b.vy <- !vy;
      b.vz <- !vz);
  for i = 0 to num_bodies - 1 do
    Domain.Sync.poll();
    let b = bodies.(i) in
    b.x <- b.x +. dt *. b.vx;
    b.y <- b.y +. dt *. b.vy;
    b.z <- b.z +. dt *. b.vz;
  done

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
  let pool = T.setup_pool ~num_domains:(num_domains - 1) in
  offset_momentum bodies;
  Printf.printf "%.9f\n" (energy bodies);
  for _i = 1 to n do aux_1 bodies 0.01 pool done;
  Printf.printf "%.9f\n" (energy bodies);
  T.teardown_pool pool