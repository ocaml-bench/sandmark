let n = try int_of_string @@ Sys.argv.(1) with _ -> 1024

let bubble_sort_threshold = 32

let _ = Random.init 42
let a = Array.init n (fun _ -> Random.int n)

let bubble_sort (a : int array) start limit =
  for i = start to limit - 2 do
    for j = i + 1 to limit - 1 do
      if a.(j) < a.(i) then
        let t = a.(i) in
        a.(i) <- a.(j);
        a.(j) <- t;
    done
  done

let merge (src : int array) dst start split limit =
  let rec loop dst_pos i j =
    if i = split then
      Array.blit src j dst dst_pos (limit - j)
    else if j = limit then
      Array.blit src i dst dst_pos (split - i)
    else if src.(i) <= src.(j) then begin
      dst.(dst_pos) <- src.(i);
      loop (dst_pos + 1) (i + 1) j;
    end else begin
      dst.(dst_pos) <- src.(j);
      loop (dst_pos + 1) i (j + 1);
    end in
  loop start start split

let rec merge_sort move a b start limit =
  if move || limit - start > bubble_sort_threshold then
    let split = (start + limit) / 2 in
    let () = merge_sort (not move) a b start split in
    let () = merge_sort (not move) a b split limit in
    if move then 
        merge a b start split limit 
    else 
        merge b a start split limit
  else bubble_sort a start limit

let sort a =
  let b = Array.copy a in
   merge_sort false a b 0 (Array.length a)

let () = 
    let c = Array.copy a in 
    let () =  
        (sort a) in 
    let () = 
        (Array.sort (fun x y -> x - y) c) in 
    print_endline ((c = a) |>  Bool.to_string);
    print_endline (string_of_int n);



(*let () =
  let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) () in
  sort pool a;
  T.teardown_pool pool *)
