let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let mat_size = try int_of_string Sys.argv.(2) with _ -> 1200

module T = Domainslib.Task

module SquareMatrix = struct
  let create f : float array =
    let fa = Array.create_float (mat_size * mat_size) in
    for i = 0 to mat_size * mat_size - 1 do
      fa.(i) <- f (i / mat_size) (i mod mat_size)
    done;
    fa

  let get (m : float array) r c = m.(r * mat_size + c)
  let set (m : float array) r c v = m.(r * mat_size + c) <- v
  let copy = Array.copy
end

open SquareMatrix

let chunk_size = 32
let pool = T.setup_pool ~num_domains:(num_domains - 1)

let lup a0 =
  let a = copy a0 in
  for k = 0 to (mat_size - 2) do
    T.parallel_for pool 
    ~chunk_size:chunk_size 
    ~start:(k + 1) 
    ~finish:(mat_size  -1)
    ~body:(fun row ->
      let factor = get a row k /. get a k k in
      for col = k + 1 to mat_size-1 do
        set a row col (get a row col -. factor *. (get a k col))
        done;
      set a row k factor )
  done;
  a
let () =
  let a = create (fun _ _ -> (Random.float 100.0)+.1.0) in
  let lu = lup a in
  let _l = create (fun i j -> if i > j then get lu i j else if i = j then 1.0 else 0.0) in
  let _u = create (fun i j -> if i <= j then get lu i j else 0.0) in
  T.teardown_pool pool
