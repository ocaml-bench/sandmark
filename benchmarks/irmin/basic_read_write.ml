module KV = Irmin_mem.KV (Irmin.Contents.String)

let _ =
  let _c = Irmin_mem.config () in
  let _r = KV.Repo.v _c in
  let _p1 = Lwt.bind _r (fun x -> KV.master x) in
  let _p2 = Lwt.bind _p1 (fun x -> KV.set x ["test"] ~info:(Irmin.Info.none) "test1") in
  let _p3 = Lwt.bind _p1 (fun x -> KV.get x ["test"]) in
  print_endline (Lwt_main.run _p3)
