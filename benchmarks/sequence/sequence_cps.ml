type ('s,'a) unfolder =
  {unfold :
     'r.
        's
     -> on_done:'r
     -> on_skip:('s -> 'r)
     -> on_yield:('s -> 'a -> 'r)
     -> 'r}

type _ t =
  | Sequence : ('s * ('s,'a) unfolder) -> 'a t

let map (Sequence(s,{unfold})) ~f =
  Sequence(s, {unfold =
                 fun s ~on_done ~on_skip ~on_yield ->
                   let on_yield s a = on_yield s (f a) in
                   unfold s ~on_done ~on_skip ~on_yield})

let filter (Sequence(s,{unfold})) ~f =
  Sequence(s, {unfold =
                 fun s ~on_done ~on_skip ~on_yield ->
                   let on_yield s a =
                     if f a
                     then on_yield s a
                     else on_skip s in
                   unfold s ~on_done ~on_skip ~on_yield})

let fold_1 (Sequence(s,{unfold})) ~init ~f =
  let rec loop s v =
    unfold s ~on_done:v ~on_skip:(fun s -> loop s v)
      ~on_yield:(fun s a -> loop s (f v a))
  in
  loop s init

let fold_2 (Sequence(s,{unfold})) ~init ~f =
  let s_ref = ref s in
  let v_ref = ref init in
  while begin
    unfold
      !s_ref
      ~on_done:false
      ~on_skip:(fun s -> s_ref:=s; true)
      ~on_yield:
        (fun s a ->
          s_ref := s;
          v_ref := f !v_ref a;
          true)
  end do () done;
  !v_ref


let fold = fold_2

let (|>) x f = f x


let test n =
  let s = Sequence(0,
                   {unfold =
                      fun i ~on_done ~on_skip ~on_yield ->
                        if i >= n then on_done else
                          on_yield (i+1) i})
  in
  s
  |> map ~f:(fun x -> x + 3)
  |> filter ~f:(fun i -> i land 1 = 0)
  |> map ~f:(fun x -> x * x)
  |> fold ~init:0 ~f:(+)

let () =
  let n = int_of_string Sys.argv.(1) in
  let r = ref 0 in
  for i = 0 to n do
    r := !r + test i;
  done;
  print_int !r;
  print_newline ()

let () =
  try
    let fn = Sys.getenv "OCAML_GC_STATS" in
    let oc = open_out fn in
    Gc.print_stat oc
  with _ -> ()
