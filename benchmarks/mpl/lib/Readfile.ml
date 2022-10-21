
let contents filename =
  let file = Unix.openfile filename [Unix.O_RDONLY] 0o640 in
  let n = (Unix.fstat file).st_size in
  let buf = Bytes.create n in
  let k = 10000 in
  let m = 1 + (n-1) / k in
  for i = 0 to m-1 do
    let lo = i*k in
    let hi = Int.min ((i+1)*k) n in
    let p = ref lo in
    while !p < hi do
      let count = Unix.read file buf (!p) (hi - !p) in
      p := !p + count
    done
  done;
  Unix.close file;
  buf
