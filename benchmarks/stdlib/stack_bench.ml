let create_stack size =
  let s = Stack.create () in
  for i = 1 to size do
    Stack.push i s
  done ;
  s

let stack_fold iterations =
  let s = create_stack 100 in
  for _ = 1 to iterations do
    ignore (Sys.opaque_identity (Stack.fold ( + ) 0 s))
  done

let stack_push_pop iterations =
  let s = Stack.create () in
  Stack.push () s ;
  for _ = 1 to iterations do
    Stack.push () s ; Stack.pop s
  done

let () =
  let iterations = int_of_string Sys.argv.(2) in
  match Sys.argv.(1) with
  | "stack_fold" ->
      stack_fold iterations
  | "stack_push_pop" ->
      stack_push_pop iterations
  | _ ->
      ()
