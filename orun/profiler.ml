type sample = {
    comp_dir: string;
    filename: string;
    line: int;
}

type profiling_result = {
  samples: sample list
}

external unpause_and_start_profiling : int -> Unix.file_descr -> profiling_result = "ml_unpause_and_start_profiling"

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

let rec wait_for_parent parent_ready =
  let read_fds, _write_fds, _exception_fds = Unix.select [parent_ready] [] [] (-1.0) in
    if List.mem parent_ready read_fds then
      ()
    else
      wait_for_parent parent_ready 

let create_process_env_paused cmd args env new_stdin new_stdout new_stderr =
  let (parent_ready, parent_ready_write) = Unix.pipe () in
  match Unix.fork() with
    0 ->
      begin try
        perform_redirections new_stdin new_stdout new_stderr;
        wait_for_parent parent_ready;
        Unix.execvpe cmd args env
      with _ ->
        exit 127
      end
| id -> (id, parent_ready_write)