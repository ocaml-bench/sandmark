(*
 *  This test intends to measure the throughput of an effect handler
 *  block where perform is called but does not return to the continuation.
 *  It will include:
 *    - new stack creation for the function to be executed
 *    - switching stack to the new stack
 *    - doing the perform and switching stacks back to the old stack
 *    - any garbage collection of the continuation that is ignored
 *)

let n_iter = try int_of_string Sys.argv.(1) with _ -> 1_000_000

let now = Sys.time

effect E : int -> int

let g () = perform (E 1)

let h () =
    let t0 = now () in

    for _ = 1 to n_iter do
        ignore (Sys.opaque_identity(
            match g () with
            | effect (E x) _k -> x
            | x -> x
        ))
    done;

    let t = (now ()) -. t0 in
    Printf.printf "%i iterations took %f\n%!" n_iter t;
    Printf.printf "%.1fns per iteration\n%!" ((t*.1e9)/. (float_of_int n_iter))

let _ = h ()

