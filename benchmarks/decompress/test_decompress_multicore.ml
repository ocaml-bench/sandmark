open Zl

let num_domains = try int_of_string(Sys.argv.(1)) with _ -> 1
let iterations = try int_of_string(Sys.argv.(2)) with _ -> 64
let data_size = try int_of_string(Sys.argv.(3)) with _ -> 32 * 1024

let blit_to_buffer t b v len =
  let rec go off len =
    if len > 0
    then
      ( let len' = (min : int -> int -> int) len (Bytes.length t) in
        Bigstringaf.blit_to_bytes v ~src_off:off t ~dst_off:0 ~len:len' ;
        Buffer.add_subbytes b t 0 len' ;
        go (off + len') (len - len') ) in
  go 0 len

let compress data =
  (* pre-allocation of values. *)
  let w = De.make_window ~bits:15 in
  let q = De.Queue.create 0x1000 in
  let i = De.bigstring_create De.io_buffer_size in
  let o = De.bigstring_create De.io_buffer_size in
  let p = ref 0 in
  let t = Bytes.create De.io_buffer_size in
  let b = Buffer.create 0x1000 in

  (* NOTE: [q] can be the bottleneck about compression where [q] is
   * the shared-queue between Lz77 algorithm and encoder. Smaller is it,
   * the more encoder will flush!
   *
   * [t] degrades performances to pass from a [De.bigstring] to a [Buffer.t] *)

  let refill v =
    let len =
      (min : int -> int -> int) (Bigstringaf.length v) (String.length data - !p) in
    Bigstringaf.blit_from_string
      data ~src_off:!p
      v ~dst_off:0 ~len ; p := !p + len ; len in
  let flush v len = blit_to_buffer t b v len in

  Higher.compress
    ~level:3 ~w ~q ~i ~o ~refill ~flush ;
  Buffer.contents b

let uncompress data =
  (* pre-allocation of values. *)
  let w = De.make_window ~bits:15 in
  let allocate _ = w in
  let i = De.bigstring_create De.io_buffer_size in
  let o = De.bigstring_create De.io_buffer_size in
  let p = ref 0 in
  let t = Bytes.create 0x1000 in
  let b = Buffer.create 0x1000 in

  let refill v =
    let len =
      (min : int -> int -> int) (Bigstringaf.length v) (String.length data - !p) in
    Bigstringaf.blit_from_string
      data ~src_off:!p
      v ~dst_off:0 ~len ; p := !p + len ; len in
  let flush v len = blit_to_buffer t b v len in

  (* NOTE: about multicore, Lz77 compression can exist into one domain where
   * encoder can exists to another domain. Both use the shared-queue [q] and
   * only it must be protected about data-race. *)

  Higher.uncompress ~allocate ~i ~o ~refill ~flush

let rng_state_key : Random.State.t Domain.DLS.key = Domain.DLS.new_key ()

let get_rng_state () = try Option.get @@ Domain.DLS.get rng_state_key
  with _ -> begin
    Domain.DLS.set rng_state_key (Random.State.make_self_init ());
    Option.get @@ Domain.DLS.get rng_state_key
  end

let data_to_compress =
  let buf = Bytes.create data_size in
  let rng_state = get_rng_state () in
  for i = 0 to data_size - 1 do
    Bytes.set buf i (Char.chr (97 + Random.State.int rng_state 26))
  done ;
  Bytes.to_string buf

let work i () =
  for _run = 0 to i do
    let result = compress data_to_compress in
    let original = uncompress result in
    ignore original
  done

let rec distribute iters num_doms doms =
  if num_doms = 1 then
    begin
      work iters ();
      List.map Domain.join doms
    end
  else
    let w = iters / num_doms in
    distribute (iters - w) (num_doms - 1)
      ((Domain.spawn (work w))::doms)

let _ = distribute iterations num_domains []
