val create_process_env_paused :
     string
  -> string array
  -> string array
  -> Unix.file_descr
  -> Unix.file_descr
  -> Unix.file_descr
  -> int * Unix.file_descr

val start_profiling : int -> Unix.file_descr -> Common.aggregate_result

val write_profiling_result : string -> Common.aggregate_result -> unit
