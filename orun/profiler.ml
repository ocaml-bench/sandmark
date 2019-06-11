type mmap_entry = {
    filename: string;
    addr: int;
    length: int;
}

type profiling_result = {
  ips: int array;
  mmap_entries: mmap_entry array;
}

external unpause_and_start_profiling : int -> profiling_result = "ml_unpause_and_start_profiling"

let int_of_fd (x: Unix.file_descr) : int = Obj.magic x

let rec file_descr_not_standard (fd : Unix.file_descr) =
  if int_of_fd(fd) >= 3 then fd else file_descr_not_standard (Unix.dup fd)

let safe_close fd =
  try Unix.close fd with Unix.Unix_error(_,_,_) -> ()

let perform_redirections new_stdin new_stdout new_stderr =
  let new_stdin = file_descr_not_standard new_stdin in
  let new_stdout = file_descr_not_standard new_stdout in
  let new_stderr = file_descr_not_standard new_stderr in
  (*  The three dup2 close the original stdin, stdout, stderr,
      which are the descriptors possibly left open
      by file_descr_not_standard *)
  Unix.dup2 ~cloexec:false new_stdin Unix.stdin;
  Unix.dup2 ~cloexec:false new_stdout Unix.stdout;
  Unix.dup2 ~cloexec:false new_stderr Unix.stderr;
  safe_close new_stdin;
  safe_close new_stdout;
safe_close new_stderr

let create_process_env_paused cmd args env new_stdin new_stdout new_stderr =
  match Unix.fork() with
    0 ->
      begin try
        perform_redirections new_stdin new_stdout new_stderr;
        Sys.set_signal Sys.sigusr1 (Sys.Signal_handle (fun _ -> ()));
        Unix.pause();
        Unix.execvpe cmd args env
      with _ ->
        exit 127
      end
| id -> id

let unpause_and_profile pid =
    ()