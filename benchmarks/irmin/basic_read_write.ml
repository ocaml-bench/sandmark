module KV = Irmin_mem.KV (Irmin.Contents.String)

let _ =
  let s = Sys.argv.(1) in
  let c = Irmin_mem.config () in
  let r = KV.Repo.v c in
  let p1 = Lwt.bind r (fun x -> KV.master x) in
  let _ = Lwt.bind p1 (fun x -> KV.set x ["test"] ~info:(Irmin.Info.none) s) in
  let p3 = Lwt.bind p1 (fun x -> KV.get x ["test"]) in
  assert (Lwt_main.run p3 = s)
