module T = Domainslib.Task

let num_domains = try int_of_string Sys.argv.(1) with _ -> 1
let n = try int_of_string Sys.argv.(2) with _ -> 2000

let swap arr i j =
  let temp = arr.(i) in
  arr.(i) <- arr.(j);
  arr.(j) <- temp

let partition arr low high =
  let x = arr.(high) and  i = ref (low-1) in
  if (high-low > 0) then
    begin
      for j= low to high - 1 do
        if arr.(j) <= x then
          begin
            i := !i+1;
            swap arr !i j
          end
      done
    end;
    swap arr (!i+1) high;
    !i+1

let rec quicksort arr low high d pool =
  if (high - low) <= 0 then ()
  else begin
    if d > 1 then begin
      let q = partition arr low high in
      let c = T.async pool (fun () -> quicksort arr low (q-1) (d/2) pool) in
      quicksort arr (q+1) high (d/2 + (d mod 2)) pool;
      T.await pool c
    end else begin
      let q = partition arr low high in
      quicksort arr low (q-1) d pool;
      quicksort arr (q+1) high d pool;
    end
  end

let () =
  let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) in
  let arr = Array.init n (fun _ -> Random.int n) in
  quicksort arr 0 (Array.length arr - 1) num_domains pool;
  (* for i = 0 to  Array.length arr - 1 do
    print_int arr.(i);
    print_string "  "
      done *)
  T.teardown_pool pool
