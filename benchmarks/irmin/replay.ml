open Lwt.Syntax

let n_commits = try int_of_string Sys.argv.(1) with _ -> 42

module Maker = Irmin_pack_unix.Maker (Irmin_tezos.Conf)
(** For an in-memory irmin store, change to [Irmin_pack_mem] and add
   [irmin-pack.mem] in dune file. *)

module Store = struct
  include Maker.Make (Irmin_tezos.Schema)

  type store_config = unit

  let create_repo ~root () =
    let conf = Irmin_pack.config ~readonly:false ~fresh:true root in
    let* repo = Repo.v conf in
    let on_commit _ _ = Lwt.return_unit in
    let on_end () = Lwt.return_unit in
    Lwt.return (repo, on_commit, on_end)
end

module Replay = Irmin_traces.Trace_replay.Make (Store)

let main () =
  let conf =
    Irmin_traces.Trace_replay.
      {
        number_of_commits_to_replay = n_commits;
        path_conversion = `None;
        inode_config = (32, 256);
        store_type = `Pack;
        replay_trace_path = "/tmp/irmin-data/data4_100066commits.repr";
        artefacts_path = "/tmp/irmin_trace_replay_artefacts";
        keep_store = false;
        keep_stat_trace = false;
        empty_blobs = false;
        return_type = Unit;
      }
  in
  Replay.run () conf

let () = Lwt_main.run (main ())
