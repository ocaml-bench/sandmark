let to_file ~filename (data : 'a ) =
  let out = open_out filename in
  Marshal.to_channel out data [];
  close_out out

let from_file filename =
  let in_ = open_in filename in
  let res : 'a = Marshal.from_channel in_ in
  close_in in_;
  res
