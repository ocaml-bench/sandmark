(* compile with:
  ocamlfind opt -package unix,domainslib -linkpkg sorttest.ml
*)
module Timings = struct

  type t = {
    cpu_time : float;
    wall_time : float
  };;

let time_computation (f : unit -> 'a) : t * 'a =
  let times_start = Sys.time ()
  and wall_start = Unix.gettimeofday () in
  let ret = f () in
  let times_end = Sys.time ()
  and wall_end = Unix.gettimeofday () in
  { cpu_time = times_end -. times_start ;
    wall_time = wall_end -. wall_start
  },
  ret
end
module Quicksort = struct
  let pivot (cmp : 'a -> 'a -> int) (a : 'a array) (left : int) (right : int) =
    assert(0 <= left);
    assert(left <= right);
    assert(right <= Array.length a);
    let mid_start = ref left
    and mid_end = ref (left + 1)
    and current_pos = ref (right - 1)
    and pivot = a.(left) in
    while !mid_end <= !current_pos do
      assert (left <= !mid_start);
      assert (!mid_start < !mid_end);
      assert (!current_pos < right);
      let current = a.(!current_pos) in
      match cmp current pivot with
      | 0 ->
        a.(!current_pos) <- a.(!mid_end);
        mid_end := !mid_end + 1
      | n when n < 0 ->
        a.(!mid_start) <- current;
        a.(!current_pos) <- a.(!mid_end);
        mid_start := !mid_start+1;
        mid_end := !mid_end+1
      | _ ->
        current_pos :=  !current_pos - 1
    done;
    for i= !mid_start to !mid_end-1 do
      a.(i) <- pivot
    done;
    (!mid_start, !mid_end);;

  let rec quicksort (cmp : 'a -> 'a -> int) (a : 'a array) (left : int) (right : int) =
    assert(0 <= left);
    assert(left <= right);
    assert(right <= Array.length a);
    if right - left > 1
    then
      let (mid_start, mid_end) = pivot cmp a left right in
      let len_left = mid_start - left
      and len_right = right - mid_end in
      if len_left < len_right then
        (quicksort cmp a left mid_start;
         quicksort cmp a mid_end right)
      else
        (quicksort cmp a mid_end right;
         quicksort cmp a left mid_start);;
end


[@@@warning "-unused-value-declaration"]


let assert_sorted cmp a left right =
  for i=left to right-2 do
    assert (cmp a.(i) a.(i+1) <= 0)
  done

let checksum a left right =
  let sum = ref 0 in
  for i=left to right-1 do
    sum := !sum lxor a.(i)
  done;
  !sum

let random_array seed max n =
  let prng = Random.State.make seed in
  Array.init n (fun _ -> Random.State.int prng max)

let print_array oc prt a left right =
  for i=left to right-1 do
    Printf.fprintf oc "[%d] = %a\n" i prt a.(i)
  done

let output_int oc n =
  output_string oc (string_of_int n);;

let pp_size ppf x =
  let x = x *. 8. in
  let rec human s suffixes x =
    match x<1024., suffixes with
    | true, _ | false, [] ->
      Printf.fprintf ppf "%.2f%sB" x s
    | false, s :: suffixes ->
      human s suffixes (x/.1024.)
  in
  human "" ["k";"M";"G";"T"] x
module Tsk = Domainslib.Task
(*  ;;
let cores = 4 in
let pool = Tsk.setup_pool ~num_additional_domains:(cores-1) () in
let run f = Tsk.run pool f in
*)
;;

type mode = Spawn_domains of int | Explicit_gc | Implicit_gc
let mode = ref Implicit_gc
let stride = ref 1000
let steps = ref 500
let args = [
    "-spawn", Arg.Int (fun x -> mode := Spawn_domains x), "<n> spawn <n> idle domains (default 0)";
    "-gc", Arg.Unit (fun () -> mode := Explicit_gc ), " add explicit call to the GC";
    "-default", Arg.Unit (fun () -> mode := Implicit_gc ), " no explicit call to the GC, single domain";
    "-stride", Arg.Set_int stride, "<n> size increase at each step (default=1000)";
    "-steps", Arg.Set_int steps, "<n> run <n> steps (default=500)";
  ]

let () = Arg.parse args ignore ""
let mode = !mode
let stride = !stride
;;
let run f = f () in
let rec loop () =
  Unix.sleepf 100.0;
  loop ()
in
begin match mode with
| Spawn_domains n ->
  for _i = 1 to n do
    let _d = Domain.spawn loop in
    Printf.eprintf "loop domain = %d\n%!" (Obj.magic (Domain.get_id _d))
  done
| _ -> ()
end;
let n1 = ref 1 in
while !n1 <= !steps * 1000 + 1 do
  let n = !n1 in
  n1 := n + stride;

  let max = 10000
  and seed = [|n; 2; 3|] in
  let a = random_array seed max n in
  let sum = checksum a 0 n in
  let times,() = Timings.time_computation (fun () ->
                     run
                     (fun () -> Quicksort.quicksort ( - ) a 0 n)) in
  assert_sorted ( - ) a 0 n ;
  let stat = Gc.quick_stat () in
  let sum2 = checksum a 0 n in
  let () = match mode with
    | Explicit_gc -> Gc.full_major ()
    | _ -> ()
  in
  assert (sum = sum2);
  Printf.printf "%d\t%f\t%f" n times.cpu_time times.wall_time;
  Printf.printf "\tmax=%a\theap=%a\tmajor allocated=%a minor=%d major=%d"
    pp_size (float stat.top_heap_words)
    pp_size (float stat.heap_words)
    pp_size stat.major_words
    stat.minor_collections
    stat.major_collections
  ;
  Printf.printf "\n";
  flush stdout
done;;
