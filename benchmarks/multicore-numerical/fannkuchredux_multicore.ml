(*
 * The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * Contributed by Paolo Ribeca, August 2011
 *
 * (Based on the Java version by Oleg Mazurov)
 *)
module T = Domainslib.Task

let workers = try int_of_string @@ Sys.argv.(1) with _ -> 10
let n = try int_of_string Sys.argv.(2) with _ -> 7
let num_domains = workers
let workers = 10

module Perm =
  struct
    type t = { p: int array;
               pp: int array;
               c: int array }
  let facts =
    let n = 20 in
    let res = Array.make (n + 1) 1 in
    for i = 1 to n do
      res.(i) <- i * res.(i - 1)
    done;
    res
  (* Setting up the permutation based on the given index *)
  let setup n idx =
    let res = { p = Array.init n (fun i -> i);
                pp = Array.make n 1;
                c = Array.make n 1 }
    and idx = ref idx in
    for i = n - 1 downto 0 do
      let d = !idx / facts.(i) in
      res.c.(i) <- d;
      idx := !idx mod facts.(i);
      Array.blit res.p 0 res.pp 0 (i + 1);
      for j = 0 to i do
        res.p.(j) <- if j + d <= i then res.pp.(j + d) else res.pp.(j + d - i - 1)
      done
    done;
    res
  (* Getting the next permutation *)
  let next { p = p; c = c; _ } =
    let plen = Array.length p in
    let f = ref p.(1) in
    p.(1) <- p.(0);
    p.(0) <- !f;
    let i = ref 1 in
    let aug_c = ref (c.(!i) + 1) in 
    c.(!i) <- !aug_c;
    while !aug_c > !i do
      c.(!i) <- 0;
      incr i;
      let n = p.(1) in
      p.(0) <- n;
      let red_i = !i - 1 in
      for j = 1 to red_i do
        if plen > j+1 then begin p.(j) <- p.(j + 1); end else ()
      done;
      if plen > !i then begin 
        p.(!i) <- !f; 
        f := n; 
      end else ();
      aug_c := c.(!i) + 1;
      c.(!i) <- !aug_c
    done
  (* Counting the number of flips *)
  let count { p = p ; pp = pp; _ } =
    let f = ref p.(0) and res = ref 1 in
    if p.(!f) <> 0 then begin
      let len = Array.length p in
      let red_len = len - 1 in
      for i = 0 to red_len do pp.(i) <- p.(i) done;
      while pp.(!f) <> 0 do
        incr res;
        let lo = ref 1 and hi = ref (!f - 1) in
        while !lo < !hi do
          let t = pp.(!lo) in
          pp.(!lo) <- pp.(!hi);
          pp.(!hi) <- t;
          incr lo;
          decr hi
        done;
        let ff = !f in
        let t = pp.(ff) in
        pp.(ff) <- ff;
        f := t
      done
    end;
    !res
  end

let fr n lo hi = 
    let p = Perm.setup n lo
    and c = ref 0 and m = ref 0
    and red_hi = hi - 1 in
    for i = lo to red_hi do let r = Perm.count p in
      c := !c + r * (1 - (i land 1) lsl 1);
      if r > !m then
      m := r;
      Perm.next p
    done;
    (!c, !m)

let main pool s_n =
    let n = s_n in
    let chunk_size = Perm.facts.(n) / workers
    and rem = Perm.facts.(n) mod workers in
    let w = ref (Array.init workers (fun _ -> (0, 0))) in
   T.run pool (fun () -> T.parallel_for pool ~start:0 ~finish:(workers-1) ~body:(fun i ->
      Printf.printf "par_iter: %d\n" i;
      let lo = i * chunk_size + min i rem in
      let hi = lo + chunk_size + if i < rem then 1 else 0 in
      !w.(i) <- fr s_n lo hi
    ) );
    let c = ref 0 and m = ref 0 in
    Array.iter
      (fun (nc, nm) ->
        c := !c + nc;
        m := max !m nm)
      !w;
    Printf.printf "%d\nPfannkuchen(%d) = %d\n" !c n !m

let _ =
  let pool = T.setup_pool ~num_domains:(num_domains - 1) () in
  main pool n;
  T.teardown_pool pool
