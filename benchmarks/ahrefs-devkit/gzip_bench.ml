(** Gzip GC Benchmark Suite

    This suite stresses the OCaml garbage collector through intensive
    compression and decompression operations. The benchmarks test:
    - Buffer-based I/O with continuous allocations
    - Zlib compression/decompression creating temporary buffers
    - Streaming patterns with state management
    - CRC calculations and header processing
    - Variable-sized buffer operations *)

open Devkit
open ExtLib

(* Helper functions for string compression/decompression *)
let compress_string ?level str =
  let _ = level in
  let oc = Gzip_io.output (IO.output_string ()) in
  IO.nwrite_string oc str;
  IO.close_out oc

let uncompress_string str =
  let ic = Gzip_io.input (IO.input_string str) in
  let result = IO.read_all ic in
  IO.close_in ic;
  result

(* Helper function to generate test data *)
let generate_test_data size pattern =
  let data = Bytes.create size in
  for i = 0 to size - 1 do
    Bytes.set data i (char_of_int (i * pattern mod 256))
  done;
  Bytes.to_string data

(* Benchmark 1: Small Buffer Compression Storm *)
let bench_small_buffer_storm () =
  let compressed_data = ref [] in

  for i = 1 to 5000 do
    let size = 100 + (i mod 900) in
    let data = generate_test_data size (i mod 256) in

    let compressed = compress_string data in
    let decompressed = uncompress_string compressed in

    let compressed_fast = compress_string ~level:1 data in
    let compressed_best = compress_string ~level:9 data in

    if i mod 100 = 0 then
      compressed_data :=
        compressed :: compressed_fast :: compressed_best :: !compressed_data;

    let _ = String.length compressed in
    let _ = String.length decompressed in

    if List.length !compressed_data > 300 then
      compressed_data := ExtList.List.take 150 !compressed_data
  done

(* Benchmark 2: Large Block Compression *)
let bench_large_block_compression () =
  let retained_blocks = ref [] in

  for i = 1 to 100 do
    let size = 10000 * (1 + (i mod 10)) in
    let data = generate_test_data size i in

    let compressed_default = compress_string data in
    let compressed_filtered = compress_string ~level:5 data in

    let decompressed1 = uncompress_string compressed_default in
    let decompressed2 = uncompress_string compressed_filtered in

    assert (decompressed1 = data);
    assert (decompressed2 = data);

    let chunk_size = 1024 in
    let chunks = ref [] in
    let pos = ref 0 in
    while !pos < String.length data do
      let len = min chunk_size (String.length data - !pos) in
      let chunk = String.sub data !pos len in
      let compressed_chunk = compress_string chunk in
      chunks := compressed_chunk :: !chunks;
      pos := !pos + len
    done;

    if i mod 10 = 0 then
      retained_blocks :=
        compressed_default :: compressed_filtered :: !retained_blocks;

    if List.length !retained_blocks > 20 then
      retained_blocks := ExtList.List.take 10 !retained_blocks
  done

(* Benchmark 3: Streaming Compression/Decompression *)
let bench_streaming_operations () =
  let stream_buffers = ref [] in

  for i = 1 to 500 do
    let data_size = 5000 + (i * 100) in
    let source_data = generate_test_data data_size i in

    let out_channel = Gzip_io.output (IO.output_string ()) in

    let chunk_size = 256 in
    let pos = ref 0 in
    while !pos < String.length source_data do
      let len = min chunk_size (String.length source_data - !pos) in
      let chunk = String.sub source_data !pos len in
      IO.nwrite_string out_channel chunk;
      pos := !pos + len
    done;

    let compressed = IO.close_out out_channel in

    let in_channel = Gzip_io.input (IO.input_string compressed) in
    let decompressed_buf = Buffer.create data_size in

    let read_buf = Bytes.create 128 in
    let rec read_loop () =
      try
        let n = IO.input in_channel read_buf 0 128 in
        if n > 0 then (
          Buffer.add_subbytes decompressed_buf read_buf 0 n;
          read_loop ())
      with IO.No_more_input -> ()
    in
    read_loop ();
    IO.close_in in_channel;

    let decompressed = Buffer.contents decompressed_buf in

    assert (decompressed = source_data);

    if i mod 50 = 0 then
      stream_buffers := compressed :: decompressed :: !stream_buffers;

    if List.length !stream_buffers > 100 then
      stream_buffers := ExtList.List.take 50 !stream_buffers
  done

(* Benchmark 4: Mixed Size Compression Patterns *)
let bench_mixed_size_patterns () =
  let mixed_cache = Hashtbl.create 1000 in

  for i = 1 to 1000 do
    let sizes = [| 64; 128; 256; 512; 1024; 2048; 4096; 8192; 128; 64 |] in
    let size = sizes.(i mod Array.length sizes) in
    let data = generate_test_data size (i * 7) in

    let levels = [ 1; 3; 5; 7; 9 ] in
    let compressed_versions =
      List.map (fun level -> compress_string ~level data) levels
    in

    let decompressed_versions =
      List.map uncompress_string compressed_versions
    in

    List.iter (fun d -> assert (d = data)) decompressed_versions;

    let mixed = String.concat "" compressed_versions in
    let mixed_compressed = compress_string mixed in

    if i mod 13 = 0 || i mod 17 = 0 then
      Hashtbl.replace mixed_cache i mixed_compressed;

    let chain =
      List.fold_left
        (fun acc comp -> compress_string (acc ^ comp))
        ""
        (ExtList.List.take 3 compressed_versions)
    in

    if i mod 23 = 0 then Hashtbl.replace mixed_cache (i + 10000) chain;

    if i mod 100 = 0 then
      Hashtbl.iter
        (fun k _ -> if k < i - 200 then Hashtbl.remove mixed_cache k)
        mixed_cache
  done

(* Benchmark 5: Concurrent-style Compression *)
let bench_concurrent_style () =
  let active_streams = Array.init 10 (fun _ -> ref []) in
  let completed = ref [] in

  for i = 1 to 2000 do
    let stream_id = i mod Array.length active_streams in
    let stream = active_streams.(stream_id) in

    let data = generate_test_data (500 + (stream_id * 100)) i in

    let compressed = compress_string data in
    stream := compressed :: !stream;

    if i mod 50 = 0 then
      Array.iteri
        (fun _idx s ->
          if List.length !s > 5 then (
            let combined = String.concat "" (List.rev !s) in
            let recompressed = compress_string combined in

            let _ = uncompress_string recompressed in

            completed := recompressed :: !completed;
            s := []))
        active_streams;

    if List.length !completed > 100 then
      completed := ExtList.List.take 50 !completed
  done

(* Benchmark 6: Compression with Headers and Metadata *)
let bench_headers_metadata () =
  let metadata_cache = ref [] in

  for i = 1 to 2000 do
    let data =
      Printf.sprintf "File_%d_Content_%s" i
        (String.make (100 + (i mod 400)) (char_of_int (65 + (i mod 26))))
    in

    let compressed = compress_string data in

    let header_size = min 10 (String.length compressed) in
    let header = String.sub compressed 0 header_size in

    let checksum = ref 0 in
    String.iter
      (fun c -> checksum := ((!checksum * 31) + Char.code c) mod 65536)
      data;

    let metadata =
      (header, !checksum, String.length data, String.length compressed)
    in

    let decompressed = uncompress_string compressed in
    assert (decompressed = data);

    let recompressed = compress_string ~level:(1 + (i mod 9)) decompressed in

    let ratio =
      float_of_int (String.length compressed)
      /. float_of_int (String.length data)
    in

    if i mod 50 = 0 then
      metadata_cache := (metadata, ratio, recompressed) :: !metadata_cache;

    if List.length !metadata_cache > 100 then
      metadata_cache := ExtList.List.take 50 !metadata_cache
  done

(* Benchmark 7: Buffer Reuse and Recycling *)
let bench_buffer_recycling () =
  let buffer_pool = Array.init 20 (fun _ -> Buffer.create 1024) in
  let compressed_pool = ref [] in
  let generation_counter = ref 0 in

  for i = 1 to 1500 do
    let buffer_idx = i mod Array.length buffer_pool in
    let buffer = buffer_pool.(buffer_idx) in

    Buffer.clear buffer;

    for j = 1 to 100 + (i mod 200) do
      Buffer.add_string buffer (Printf.sprintf "Line_%d_%d " i j)
    done;

    let data = Buffer.contents buffer in

    let compressed = compress_string data in

    let decode_buffer =
      buffer_pool.((buffer_idx + 1) mod Array.length buffer_pool)
    in
    Buffer.clear decode_buffer;
    let decompressed = uncompress_string compressed in
    Buffer.add_string decode_buffer decompressed;

    incr generation_counter;

    if !generation_counter mod 30 = 0 then (
      compressed_pool := compressed :: !compressed_pool;

      if List.length !compressed_pool > 10 then
        let old_data = List.hd !compressed_pool in
        let mixed = old_data ^ compressed in
        let mixed_compressed = compress_string mixed in
        compressed_pool := mixed_compressed :: List.tl !compressed_pool);

    if !generation_counter mod 100 = 0 && List.length !compressed_pool > 50 then
      compressed_pool := ExtList.List.take 25 !compressed_pool
  done

(* Benchmark 8: Complex Compression Pipelines *)
let bench_compression_pipelines () =
  let pipeline_stages = Hashtbl.create 500 in
  let final_results = ref [] in

  for i = 1 to 1000 do
    let base_data = generate_test_data (1000 + (i * 10)) i in
    let stage1 = compress_string base_data in

    let decompressed = uncompress_string stage1 in
    let modified = decompressed ^ Printf.sprintf "_modified_%d" i in
    let stage2 = compress_string ~level:5 modified in

    let stage3 =
      match Hashtbl.find_opt pipeline_stages (i - 10) with
      | Some (prev1, prev2, _) ->
          let combined = stage1 ^ prev1 ^ stage2 ^ prev2 in
          compress_string ~level:3 combined
      | None -> compress_string (stage1 ^ stage2)
    in

    Hashtbl.replace pipeline_stages i (stage1, stage2, stage3);

    let multi_compressed =
      let temp1 = compress_string ~level:1 base_data in
      let temp2 = compress_string ~level:5 temp1 in
      compress_string ~level:9 temp2
    in

    let multi_decompressed =
      let temp1 = uncompress_string multi_compressed in
      let temp2 = uncompress_string temp1 in
      uncompress_string temp2
    in

    assert (multi_decompressed = base_data);

    if i mod 50 = 0 then
      final_results := (stage3, multi_compressed) :: !final_results;

    if i mod 100 = 0 then (
      Hashtbl.iter
        (fun k _ -> if k < i - 50 then Hashtbl.remove pipeline_stages k)
        pipeline_stages;
      if List.length !final_results > 40 then
        final_results := ExtList.List.take 20 !final_results)
  done

(* Main benchmark suite runner *)
let () =
  bench_small_buffer_storm ();
  bench_large_block_compression ();
  bench_streaming_operations ();
  bench_mixed_size_patterns ();
  bench_concurrent_style ();
  bench_headers_metadata ();
  bench_buffer_recycling ();
  bench_compression_pipelines ()
