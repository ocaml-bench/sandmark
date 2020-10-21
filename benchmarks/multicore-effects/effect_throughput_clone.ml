(*
 *  This test intends to measure the throughput of continuation cloning.
 *  It will include:
 *    - cloning the continuation
 *    - switching stack to the new stack
 *    - returning from the new stack and freeing the stack
 *)

let n_iter = try int_of_string Sys.argv.(1) with _ -> 1_000_000

let now = Sys.time

effect E : int -> int

let g () = perform (E 1)

let h () =
    let t0 = now () in

    ignore (
        match g () with
        | effect (E x) k -> begin
            for _ = 1 to n_iter do
                ignore (Sys.opaque_identity(
                    continue (Obj.clone_continuation k) x
                ))
            done;
            continue k x
        end
        | x -> x
        );

    let t = (now ()) -. t0 in
    Printf.printf "%i iterations took %f\n%!" n_iter t;
    Printf.printf "%.1fns per iteration\n%!" ((t*.1e9)/. (float_of_int n_iter))

let _ = h ()

