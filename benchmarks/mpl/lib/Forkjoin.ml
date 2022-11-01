module T = Domainslib.Task

type grain = int

let num_domains = Cla.parse_int "procs" 1
let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) ()
let _ = at_exit (fun () -> T.teardown_pool pool)

let run f =
  T.run pool f

let par f g =
  let ga = T.async pool g in
  let fr = f () in
  let gr = T.await pool ga in
  (fr, gr)

let par3 f1 f2 f3 =
  let a3 = T.async pool f3 in
  let a2 = T.async pool f2 in
  let r1 = f1 () in
  (r1, T.await pool a2, T.await pool a3)

let par4 f1 f2 f3 f4 =
  let a4 = T.async pool f4 in
  let a3 = T.async pool f3 in
  let a2 = T.async pool f2 in
  let r1 = f1 () in
  (r1, T.await pool a2, T.await pool a3, T.await pool a4)

let parfor grain (i, j) f =
  if i >= j then () else
  T.parallel_for pool
    ~chunk_size:grain
    ~start:i
    ~finish:(j-1)
    ~body:f
